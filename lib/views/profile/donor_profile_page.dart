import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_page.dart'; // Import the edit profile page

class DonorProfilePage extends StatelessWidget {
  const DonorProfilePage({super.key});

  /// Fetch the current donor's data from Firestore.
  Future<DocumentSnapshot> _fetchCurrentUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
    } else {
      throw Exception("No user is currently signed in.");
    }
  }

  /// Stream the current donor's food posts from Firestore.
  Stream<QuerySnapshot> _fetchUserPosts() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('food_posts')
        .where('donorId', isEqualTo: currentUser?.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile (Donor)")),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchCurrentUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found."));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? "No Name";
          String email = userData['email'] ?? "No Email";

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Name: $name",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("Email: $email", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    "My Food Posts",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _fetchUserPosts(),
                    builder: (context, postSnapshot) {
                      if (postSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
                        return const Text("You haven't posted any food donations yet.");
                      }

                      var posts = postSnapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          var post = posts[index];

                          bool hasLocation = post.data().toString().contains('latitude') &&
                              post.data().toString().contains('longitude');

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              title: Text(post['foodName']),
                              subtitle: Text(post['description']),
                              trailing: hasLocation
                                  ? Text("📍 ${post['latitude']}, ${post['longitude']}")
                                  : const Text("📍 No location"),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(role: "donor"),
                        ),
                      );
                    },
                    child: const Text("Edit Profile"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      // Navigate to login screen
                    },
                    child: const Text("Log Out"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
