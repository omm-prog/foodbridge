import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import '../../views/auth/login_page.dart';
import '../../views/ngo/ngo_page.dart';
import '../../views/donor/donor_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // Using default Flutter font by not specifying a fontFamily here
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(), // Automatically decides where to go
    );
  }
}

// AuthWrapper checks if user is logged in and redirects based on role
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the user is logged in, determine the role from Firestore
        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection("users")
                    .doc(snapshot.data!.uid)
                    .get(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                Map<String, dynamic>? userData =
                    roleSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null && userData.containsKey('role')) {
                  String role = userData['role'];
                  String name = userData['name'] ?? "User"; // Default name

                  if (role == "ngo") {
                    return NGOPage(name: name); // Redirect to NGOPage
                  } else if (role == "donor") {
                    return DonorPage(name: name); // Redirect to DonorPage
                  }
                }
              }
              // If no valid role or user data is found, send to LoginPage
              return const LoginPage();
            },
          );
        }
        // If no user is logged in, show LoginPage
        return const LoginPage();
      },
    );
  }
}
