import 'dart:io';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'donor_page.dart';
import 'package:flutter/foundation.dart'; // Import this

class PostFoodPage extends StatefulWidget {
  const PostFoodPage({super.key});

  @override
  _PostFoodPageState createState() => _PostFoodPageState();
}

class _PostFoodPageState extends State<PostFoodPage> {
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _foodDescriptionController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  bool _isLoading = false;
  Position? _currentPosition;
  String? _selectedCategory;
  Uint8List? _webImage;
  File? _mobileImage;

  final List<String> _categories = [
    "Cooked Food",
    "Fruits",
    "Vegetables",
    "Packaged Food",
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enable location services.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied permanently.")),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _expiryDateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final pickedFile = await ImagePickerWeb.getImageAsBytes();
      if (pickedFile != null) {
        setState(() {
          _webImage = pickedFile;
          _mobileImage = null;
        });
      }
    } else {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _mobileImage = File(pickedFile.path);
          _webImage = null;
        });
      }
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    const String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dv6d2ivhi/image/upload";
    const String uploadPreset = "ml_default";

    var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl));
    request.fields["upload_preset"] = uploadPreset;

    String uniqueFileName = "food_${DateTime.now().millisecondsSinceEpoch}.png"; // Unique filename

    if (_mobileImage != null) {
      request.files.add(await http.MultipartFile.fromPath("file", _mobileImage!.path, filename: uniqueFileName));
    } else if (_webImage != null) {
      request.files.add(http.MultipartFile.fromBytes("file", _webImage!, filename: uniqueFileName));
    } else {
      print("No image selected");
      return null;
    }

    print("Uploading image...");
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    print("Cloudinary Response: $responseData");

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(responseData);
      return jsonResponse["secure_url"];
    } else {
      print("Cloudinary upload failed: ${response.statusCode}");
      return null;
    }
  }
  Future<void> _postFood() async {
    if (_foodNameController.text.isEmpty ||
        _foodDescriptionController.text.isEmpty ||
        _expiryDateController.text.isEmpty ||
        _selectedCategory == null ||
        _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all details.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      DocumentSnapshot donorSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String donorName = donorSnapshot['name'];

      String? imageUrl;
      if (_mobileImage != null || _webImage != null) {
        imageUrl = await _uploadImageToCloudinary();
      }

      await FirebaseFirestore.instance.collection('food_posts').add({
        'foodName': _foodNameController.text,
        'description': _foodDescriptionController.text,
        'expiryDate': _expiryDateController.text,
        'category': _selectedCategory,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'donorId': user.uid,
        'imageUrl': imageUrl,
        'timestamp': Timestamp.now(),
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Food posted successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Future.delayed(Duration.zero, () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DonorPage(name: donorName)),
                  );
                });
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error posting food: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to post food. Try again.")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Food")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _foodNameController, decoration: const InputDecoration(labelText: "Food Name")),
            TextField(controller: _foodDescriptionController, decoration: const InputDecoration(labelText: "Food Description")),
            TextField(controller: _expiryDateController, readOnly: true, decoration: const InputDecoration(labelText: "Expiry Date"), onTap: () => _selectExpiryDate(context)),
            DropdownButtonFormField(value: _selectedCategory, hint: const Text("Select Food Category"), items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (value) => setState(() => _selectedCategory = value)),
            ElevatedButton(onPressed: _pickImage, child: const Text("Pick Image")),
            if (_mobileImage != null) Image.file(_mobileImage!, height: 100),
            if (_webImage != null) Image.memory(_webImage!, height: 100),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _postFood, child: const Text("Submit")),
          ],
        ),
      ),
    );
  }
}
