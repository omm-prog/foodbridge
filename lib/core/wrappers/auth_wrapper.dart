import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../views/auth/login_page.dart';
import '../../views/ngo/ngo_page.dart';
import '../../views/donor/donor_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // If user is not logged in, show LoginPage
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // User is logged in, fetch their role from Firestore
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection("users")
                  .doc(snapshot.data!.uid)
                  .get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
              Map<String, dynamic>? userData =
                  roleSnapshot.data!.data() as Map<String, dynamic>?;

              if (userData != null && userData.containsKey('role')) {
                String role = userData['role'];
                String name = userData['name'] ?? 'User';

                if (role == "ngo") {
                  return NGOPage(name: name);
                } else if (role == "donor") {
                  return DonorPage(name: name);
                }
              }
            }

            // If role is missing, logout and show login page
            FirebaseAuth.instance.signOut();
            return const LoginPage();
          },
        );
      },
    );
  }
}
