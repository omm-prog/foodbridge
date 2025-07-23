import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<List<Map<String, dynamic>>> _fetchNGOProfiles() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('ngo_users').get();

    return querySnapshot.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NGO Profiles")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNGOProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No NGOs Found"));
          }

          List<Map<String, dynamic>> ngoList = snapshot.data!;

          return ListView.builder(
            itemCount: ngoList.length,
            itemBuilder: (context, index) {
              var ngo = ngoList[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.business,
                    size: 40,
                    color: Colors.blue,
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ngo['organisation'] ?? 'Unknown Organisation',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        "👤 ${ngo['name'] ?? 'No Name'}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📍 Address: ${ngo['address'] ?? 'Not Provided'}"),
                      Text("📞 Phone: ${ngo['phoneNumber'] ?? 'No Contact'}"),
                      Text("🌐 Website: ${ngo['website'] ?? 'No Website'}"),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
