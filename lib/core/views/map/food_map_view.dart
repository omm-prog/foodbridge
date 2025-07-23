import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodMapView extends StatefulWidget {
  final String? selectedFoodId;
  final bool showAllMarkers;

  const FoodMapView({
    Key? key,
    this.selectedFoodId,
    this.showAllMarkers = true,
  }) : super(key: key);

  @override
  State<FoodMapView> createState() => _FoodMapViewState();
}

class _FoodMapViewState extends State<FoodMapView> {
  final MapController _mapController = MapController(); // Initialize directly
  List<Marker> _markers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFoodMarkers();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodMarkers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      QuerySnapshot foodSnapshot;
      if (widget.selectedFoodId != null) {
        foodSnapshot = await FirebaseFirestore.instance
            .collection('food_posts')
            .where(FieldPath.documentId, isEqualTo: widget.selectedFoodId)
            .get();
      } else {
        foodSnapshot = await FirebaseFirestore.instance
            .collection('food_posts')
            .get();
      }

      List<Marker> newMarkers = [];

      for (var doc in foodSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['latitude'] != null && data['longitude'] != null) {
          newMarkers.add(
            Marker(
              point: LatLng(
                data['latitude'] as double,
                data['longitude'] as double,
              ),
              child: GestureDetector(
                onTap: () => _showFoodDetails(data),
                child: Column(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        data['foodName'] as String,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              width: 80.0,
              height: 80.0,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _isLoading = false;
        });

        // Only move the map if there are markers and the controller is ready
        if (_markers.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(_markers.first.point, 13.0);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading map data: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showFoodDetails(Map<String, dynamic> foodData) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              foodData['foodName'] as String,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Category: ${foodData['category']}'),
            Text('Description: ${foodData['description']}'),
            Text('Expires: ${foodData['expiryDate']}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_markers.isEmpty) {
      return const Center(child: Text('No locations available'));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _markers.isNotEmpty
            ? _markers.first.point
            : const LatLng(0, 0),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.foodbridge',
        ),
        MarkerLayer(markers: _markers),
      ],
    );
  }
}