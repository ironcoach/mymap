import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mymap/utils/extensions.dart';
import 'package:mymap/widgets/edit_box.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final usersCollection = FirebaseFirestore.instance.collection("users");

  Future<void> editField(String field) async {
    String newStr = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $field"),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {},
        ),
        actions: [
          TextButton(
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              "Save",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(newStr),
          ),
        ],
      ),
    );

    if (newStr.trim().isNotEmpty) {
      await usersCollection.doc(currentUser.email).update({field: newStr});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Profile Page"),
          backgroundColor: context.colorScheme.tertiaryContainer),
      body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(currentUser.email)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final userData = snapshot.data!.data() as Map<String, dynamic>;

              return ListView(
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.person,
                    size: 50,
                  ),
                  Text(
                    userData["firstname"],
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    currentUser.email!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  EditBox(
                    text: userData["firstname"],
                    sectionName: "First Name",
                    onPressed: () => editField('firstname'),
                  ),
                  EditBox(
                    text: userData["lastname"],
                    sectionName: "Last Name",
                    onPressed: () => editField('lastname'),
                  ),
                  EditBox(
                    text: userData["phone"],
                    sectionName: "Phone",
                    onPressed: () => editField('phone'),
                  ),
                  EditBox(
                    text: userData["email"],
                    sectionName: "email",
                    onPressed: () => editField('email'),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error.toString()}"),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }),
    );
  }
}
