import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_ngo_profile_page.dart';
import '../../views/auth/login_page.dart'; // Make sure this is the correct path

class NGOProfilePage extends StatelessWidget {
  const NGOProfilePage({super.key});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    // Fetch from 'users' collection (Name & Email)
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

    // Fetch from 'ngo_users' collection (NGO details)
    DocumentSnapshot ngoDoc =
        await FirebaseFirestore.instance
            .collection('ngo_users')
            .doc(currentUser.uid)
            .get();

    if (!userDoc.exists) return null;

    Map<String, dynamic> userData = {
      'name': userDoc['name'],
      'email': userDoc['email'],
    };

    if (ngoDoc.exists) {
      userData.addAll(ngoDoc.data() as Map<String, dynamic>);
    }

    return userData;
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NGO Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("No profile found. Please update your profile."),
            );
          }

          var userData = snapshot.data!;
          String formattedDate =
              userData['updatedAt'] != null
                  ? (userData['updatedAt'] as Timestamp).toDate().toString()
                  : "Not Updated";

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Name: ${userData['name']}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Email: ${userData['email']}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Phone: ${userData['phoneNumber'] ?? 'No Phone'}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Address: ${userData['address'] ?? 'No Address'}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Organisation: ${userData['organisation'] ?? 'No Organisation'}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Registration No: ${userData['registrationNumber'] ?? 'No Registration'}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Website: ${userData['website'] ?? 'No Website'}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Last Updated: $formattedDate",
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EditNGOProfilePage(userData: userData),
                      ),
                    );
                  },
                  child: const Text("Edit Profile"),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
