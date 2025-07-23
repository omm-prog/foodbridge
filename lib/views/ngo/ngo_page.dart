import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../views/auth/login_page.dart';
import '../profile/ngo_profile_page.dart';
import 'dart:math';

class NGOPage extends StatefulWidget {
  final String name;

  const NGOPage({super.key, required this.name});

  @override
  _NGOPageState createState() => _NGOPageState();
}

class _NGOPageState extends State<NGOPage> {
  Position? _currentPosition;
  bool _isLoading = true;
  List<Map<String, dynamic>> foodPosts = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services.")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permissions are permanently denied."),
          ),
        );
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      _fetchFoodPosts();
    } catch (e) {
      print("❌ Error fetching location: $e");
    }
  }

  Future<void> _fetchFoodPosts() async {
    if (_currentPosition == null) {
      print("⚠️ Location not available yet!");
      return;
    }

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('food_posts').get();

      List<Map<String, dynamic>> posts = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data == null ||
            !data.containsKey('donorId') ||
            !data.containsKey('latitude') ||
            !data.containsKey('longitude') ||
            !data.containsKey('foodName') ||
            !data.containsKey('description')) {
          continue;
        }

        String donorId = data['donorId'];
        String expiryDate = data['expiryDate'] ?? "Unknown";
        String acceptedByNGO = data['acceptedByNGO'] ?? "Available";
        String imageUrl = data['imageUrl'] ?? ""; // Default empty string

        DocumentSnapshot donorSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(donorId)
                .get();

        String donorName =
            donorSnapshot.exists ? donorSnapshot['name'] : "Unknown Donor";

        double distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          data['latitude'],
          data['longitude'],
        );

        posts.add({
          'foodName': data['foodName'],
          'description': data['description'],
          'distance': distance,
          'donorName': donorName,
          'expiryDate': expiryDate,
          'acceptedByNGO':
              acceptedByNGO != "Available" ? "Accepted" : "Available",
          'docId': doc.id,
          'isAccepted': acceptedByNGO != "Available",
          'imageUrl': imageUrl, // Add imageUrl to the post data
        });
      }

      posts.sort((a, b) {
        if (a['isAccepted'] && !b['isAccepted']) {
          return 1;
        } else if (!a['isAccepted'] && b['isAccepted']) {
          return -1;
        }
        return a['distance'].compareTo(b['distance']);
      });

      setState(() {
        foodPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching posts: $e");
    }
  }

  Future<void> _acceptFoodPost(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('food_posts')
          .doc(docId)
          .update({'acceptedByNGO': widget.name});

      setState(() {
        foodPosts =
            foodPosts.map((post) {
              if (post['docId'] == docId) {
                post['acceptedByNGO'] = "Accepted";
                post['isAccepted'] = true;
              }
              return post;
            }).toList();
      });

      _fetchFoodPosts(); // Refresh list after accepting

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Food accepted successfully!")),
      );
    } catch (e) {
      print("❌ Error accepting food post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to accept food post.")),
      );
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  Widget _buildHomePage() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : foodPosts.isEmpty
            ? const Center(child: Text("No food available nearby."))
            : ListView.builder(
                itemCount: foodPosts.length,
                itemBuilder: (context, index) {
                  var post = foodPosts[index];
                  bool isAccepted = post['isAccepted'];

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10), // Add padding
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Section
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8), // Rounded corners
                            child: post['imageUrl'].isNotEmpty
                                ? Image.network(
                                    post['imageUrl'],
                                    width: 80, // Increased image size
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.fastfood, color: Colors.orange, size: 50);
                                    },
                                  )
                                : const Icon(Icons.fastfood, color: Colors.orange, size: 50),
                          ),
                          const SizedBox(width: 10), // Space between image and text
                          // Text Section
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post['foodName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text("Donor: ${post['donorName']}", style: const TextStyle(fontSize: 14)),
                                Text("Expiry: ${post['expiryDate']}", style: const TextStyle(fontSize: 14)),
                                Text("Distance: ${post['distance'].toStringAsFixed(2)} km", style: const TextStyle(fontSize: 14)),
                                Text("Status: ${post['acceptedByNGO']}", style: TextStyle(fontSize: 14, color: post['isAccepted'] ? Colors.green : Colors.red)),
                              ],
                            ),
                          ),
                          // Accept Button
                          if (!post['isAccepted']) 
                            ElevatedButton(
                              onPressed: () => _acceptFoodPost(post['docId']),
                              child: const Text("Accept"),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${widget.name} (NGO)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildHomePage() : const NGOProfilePage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
