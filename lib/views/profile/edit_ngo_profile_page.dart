import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditNGOProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditNGOProfilePage({super.key, this.userData});

  @override
  _EditNGOProfilePageState createState() => _EditNGOProfilePageState();
}

class _EditNGOProfilePageState extends State<EditNGOProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _organisationController;
  late TextEditingController _registrationController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.userData?['phoneNumber'] ?? '');
    _addressController = TextEditingController(text: widget.userData?['address'] ?? '');
    _organisationController = TextEditingController(text: widget.userData?['organisation'] ?? '');
    _registrationController = TextEditingController(text: widget.userData?['registrationNumber'] ?? '');
    _websiteController = TextEditingController(text: widget.userData?['website'] ?? '');
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not logged in.")));
      return;
    }

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('ngo_users').doc(currentUser.uid);

    // Ensure email, name, and role are stored in NGO profile (like donor_users)
    Map<String, dynamic> updatedData = {
      'uid': currentUser.uid,
      'email': widget.userData?['email'] ?? currentUser.email,
      'name': widget.userData?['name'] ?? '',
      'role': 'ngo', // Ensuring role is stored
      'phoneNumber': _phoneController.text,
      'address': _addressController.text,
      'organisation': _organisationController.text,
      'registrationNumber': _registrationController.text,
      'website': _websiteController.text,
      'updatedAt': FieldValue.serverTimestamp(),  // Always update timestamp
    };

    await userRef.set(updatedData, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully.")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit NGO Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: widget.userData?['name'],
                decoration: const InputDecoration(labelText: "Name"),
                readOnly: true,
              ),
              TextFormField(
                initialValue: widget.userData?['email'],
                decoration: const InputDecoration(labelText: "Email"),
                readOnly: true,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                validator: (value) => value!.isEmpty ? "Please enter phone number" : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (value) => value!.isEmpty ? "Please enter address" : null,
              ),
              TextFormField(
                controller: _organisationController,
                decoration: const InputDecoration(labelText: "Organisation"),
                validator: (value) => value!.isEmpty ? "Please enter organisation name" : null,
              ),
              TextFormField(
                controller: _registrationController,
                decoration: const InputDecoration(labelText: "Registration Number"),
                validator: (value) => value!.isEmpty ? "Please enter registration number" : null,
              ),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: "Website"),
                validator: (value) => value!.isEmpty ? "Please enter website" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text("Update Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
