import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerUser({
    required String name,
    required String email,
    required String gender,
    required String password,
    required String confirmPassword,
  }) async {
    if (name.isEmpty ||
        email.isEmpty ||
        gender.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      return "Please fill in all fields.";
    }

    if (password != confirmPassword) {
      return "Passwords do not match.";
    }

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'gender': gender,
        'role': 'user',
      });

      return null; // No error, success
    } on FirebaseAuthException catch (e) {
      return e.toString(); // Return error message
    }
  }
}
