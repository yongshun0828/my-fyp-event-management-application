import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String? selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Password Hashing Function
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hashed = sha256.convert(bytes);
    return hashed.toString();
  }

  void _register() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage("Please fill in all fields");
      return;
    }

    if (selectedGender == null) {
      _showMessage("Please select your gender");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Passwords do not match!");
      return;
    }

    if (password.length < 6) {
      _showMessage("Password must be at least 6 characters long");
      return;
    }

    try {
      // Register user with Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String hashedPassword = hashPassword(password);

      // Store user details in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'gender': selectedGender ?? "Not Specified",
        'password': hashedPassword,
        'uid': userCredential.user!.uid,
        'role': 'user',
        'createdAt': Timestamp.now(),
      });

      _showMessage("Registration Successful!", isSuccess: true);
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _showMessage("Registration Error: ${e.toString()}");
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade700,
              Colors.purple.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Back Button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  // Welcome Text
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please fill in the details to register',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Registration Form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          nameController,
                          'Full Name',
                          Icons.person_outline,
                          hint: 'Enter your full name',
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          emailController,
                          'Email Address',
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          hint: 'Enter your email address',
                        ),
                        const SizedBox(height: 20),
                        _buildGenderDropdown(),
                        const SizedBox(height: 20),
                        _buildTextField(
                          passwordController,
                          'Password',
                          Icons.lock_outline,
                          obscureText: _obscurePassword,
                          hint: 'Enter your password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          confirmPasswordController,
                          'Confirm Password',
                          Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          hint: 'Confirm your password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Login Link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text(
                              'Already have an account? Login',
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? hint,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.purple),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purple),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedGender,
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: const Icon(Icons.person_outline, color: Colors.purple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.purple, width: 2),
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
          DropdownMenuItem(
            value: 'Prefer Not Say',
            child: Text('Prefer Not Say'),
          ),
        ],
        onChanged: (value) => setState(() => selectedGender = value),
      ),
    );
  }
}
