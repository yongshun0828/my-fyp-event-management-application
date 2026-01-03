import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tarumt_event_app/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    QuerySnapshot usersSnapshot = await firestore.collection('users').get();

    for (var doc in usersSnapshot.docs) {
      String userId = doc.id;
      String plainPassword = doc['password']; // Existing unencrypted password

      // Check if the password is already hashed (to avoid double hashing)
      if (plainPassword.length != 64) {
        String hashedPassword = hashPassword(plainPassword);

        await firestore.collection('users').doc(userId).update({
          'password': hashedPassword,
        });

        print('Updated password for user: $userId');
      } else {
        print('Skipping user: $userId (already hashed)');
      }
    }

    print("All passwords updated successfully!");
  } catch (e) {
    print("Error updating passwords: $e");
  }
}

// Password Hashing Function
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final hashed = sha256.convert(bytes);
  return hashed.toString();
}
