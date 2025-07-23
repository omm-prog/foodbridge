import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  final String role;

  const EditProfilePage({super.key, required this.role});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _email = "";
  String _organization = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String collection = widget.role == "ngo" ? "ngo_users" : "donor_users";

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(user.uid)
        .get();

    if (doc.exists) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data != null) {
        _nameController.text = data['name'] ?? "";
        _phoneNumberController.text = data['phoneNumber'] ?? "";
        _addressController.text = data['address'] ?? "";
        _email = data['email'] ?? user.email!;
        _organization = data['organisation'] ?? "";
      }
    } else {
      _email = user.email!;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String collection = widget.role == "ngo" ? "ngo_users" : "donor_users";

    await FirebaseFirestore.instance.collection(collection).doc(user.uid).set({
      "name": _nameController.text,
      "organisation": _organization,
      "phoneNumber": _phoneNumberController.text,
      "address": _addressController.text,
      "email": _email,
      "role": widget.role,
      "uid": user.uid,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) =>
                          value!.isEmpty ? "Enter your name" : null,
                    ),
                    TextFormField(
                      initialValue: _organization,
                      decoration: const InputDecoration(labelText: "Organization"),
                      enabled: false, // Make organization unchangeable
                    ),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(labelText: "Phone Number"),
                      validator: (value) =>
                          value!.isEmpty ? "Enter phone number" : null,
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: "Address"),
                      validator: (value) =>
                          value!.isEmpty ? "Enter address" : null,
                    ),
                    TextFormField(
                      initialValue: _email,
                      decoration: const InputDecoration(labelText: "Email"),
                      enabled: false, // Make email unchangeable
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
