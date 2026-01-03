import 'dart:convert';
import 'package:crypto/crypto.dart'; // For password hashing
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String gender = 'Male';
  String userId = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: user.email)
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
          setState(() {
            userId = querySnapshot.docs.first.id;
            _nameController.text = userData['name'] ?? '';
            _emailController.text = userData['email'] ?? '';
            gender = userData['gender'] ?? 'Male';
          });
        }
      } catch (e) {
        _showMessage("Error fetching user data: $e", isError: true);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateUserData() async {
    setState(() => _isLoading = true);
    final User? user = FirebaseAuth.instance.currentUser;

    if (userId.isNotEmpty && user != null) {
      try {
        String? hashedPassword;
        if (_passwordController.text.isNotEmpty) {
          hashedPassword = _hashPassword(_passwordController.text);
          await user.updatePassword(_passwordController.text);
        }

        if (_emailController.text != user.email) {
          await user.verifyBeforeUpdateEmail(_emailController.text);
        }

        await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'name': _nameController.text,
              'email': _emailController.text,
              'gender': gender,
              if (hashedPassword != null) 'password': hashedPassword,
            });

        _showMessage('Profile updated successfully!', isError: false);
      } catch (e) {
        _showMessage('Error updating profile: $e', isError: true);
      }
    }
    setState(() => _isLoading = false);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    const AssetImage('assets/images/user.png'),
                              ),
                            ),
                            Positioned(
                              bottom: 15,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
                        _buildTextField(
                          "Full Name",
                          _nameController,
                          Icons.person_outline,
                        ),
            _buildTextField(
                          "Email",
                          _emailController,
                          Icons.email_outlined,
                          enabled: true,
                        ),
                        _buildDropdownField("Gender", Icons.people_outline),
                        const SizedBox(height: 20),
                        const Text(
                          'Security',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
            ),
            const SizedBox(height: 20),
                        _buildTextField(
                          "New Password",
                          _passwordController,
                          Icons.lock_outline,
                          obscureText: true,
                          hintText: "Leave blank to keep current password",
                        ),
                        const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
                          height: 55,
              child: ElevatedButton(
                onPressed: _updateUserData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    bool obscureText = false,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.purple,
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: gender,
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
          DropdownMenuItem(value: 'Prefer Not Say', child: Text('Prefer Not Say')),
        ],
        onChanged: (value) {
          setState(() {
            gender = value!;
          });
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.purple,
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }
}
