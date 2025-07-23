import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_selection_page.dart'; // Redirecting to Role Selection Page
import '../../views/ngo/ngo_page.dart';
import '../../views/donor/donor_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  void _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user != null) {
        // Fetch user details from Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          String role = userDoc["role"] ?? "";
          String name = userDoc["name"] ?? "User";

          if (role == "ngo") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => NGOPage(name: name)),
            );
          } else if (role == "donor") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DonorPage(name: name),
              ), // ✅ FIXED: DonorPage now accepts 'name'
            );
          }
        } else {
          setState(() {
            errorMessage = "User data not found.";
          });
        }
      } else {
        setState(() {
          errorMessage = "Invalid email or password.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Login failed.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _login, child: const Text("Login")),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoleSelectionPage(),
                  ),
                );
              },
              child: const Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}
