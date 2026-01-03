import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class StaffProfilePage extends StatelessWidget {
  const StaffProfilePage({super.key});

  Future<DocumentSnapshot?> _getStaffData(String? email) async {
    if (email == null) return null;

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
    } catch (e) {
      print("Error fetching staff data: $e");
    }
    return null;
  }

  // ignore: unused_element
  void _navigateToCodePage(BuildContext context) {
    Navigator.pushNamed(context, '/code'); // Ensure this route is defined
  }

void _logout(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      print("🔍 User Email: ${user.email}");
      print("🔍 Auth Providers: ${user.providerData.map((p) => p.providerId).toList()}");

      for (var provider in user.providerData) {
        if (provider.providerId == 'google.com') {
          await GoogleSignIn().signOut();
          break;
        }
      }
    }

    await FirebaseAuth.instance.signOut();

    print("✅ User successfully logged out");

    // Wait for sign-out to complete and reload FirebaseAuth instance
    await Future.delayed(const Duration(milliseconds: 500));
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        print("🚀 Logout confirmed, navigating to login page");
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        print("⚠️ Logout failed, user still exists: ${user.email}");
      }
    });

  } catch (e) {
    print("❌ Logout Error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text(
          "Staff Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/staffprofile');
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Staff',
            ),
          ],
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: _getStaffData(user?.email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Loading profile...",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Staff data not found",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final staffData = snapshot.data!.data() as Map<String, dynamic>;
          final String name = staffData['name'] ?? "No Name";
          final String email = staffData['email'] ?? "No Email";
          final String profileImage = staffData['profileImage'] ?? "";

          return Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/userdetails');
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 46,
                              backgroundImage: profileImage.isNotEmpty
                                  ? NetworkImage(profileImage)
                                  : const AssetImage('assets/images/user.png')
                                      as ImageProvider,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _navigateToCodePage(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.code,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Code",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildMenuItem(
                      Icons.notifications,
                      "Announcement",
                      onTap: () {
                        Navigator.pushNamed(context, '/home');
                      },
                    ),
                    _buildMenuItem(
                      Icons.event,
                      "Enroll Event",
                      onTap: () {
                        Navigator.pushNamed(context, '/event');
                      },
                    ),
                    _buildMenuItem(
                      Icons.edit,
                      "Host Event",
                      onTap: () async {
                        final event = await _fetchEventDocument();
                        if (event != null) {
                          Navigator.pushNamed(
                            context,
                            '/eventdetails',
                            arguments: event,
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      Icons.video_call,
                      "Google Meet",
                      onTap: () {
                        Navigator.pushNamed(context, '/meeting');
                      },
                    ),
                    _buildMenuItem(
                      Icons.list,
                      "Student Name List",
                      onTap: () {
                        Navigator.pushNamed(context, '/studentlist');
                      },
                    ),
                    _buildMenuItem(
                      Icons.map,
                      "Map",
                      onTap: () {
                        Navigator.pushNamed(context, '/map');
                      },
                    ),
                    _buildMenuItem(
                      Icons.feedback,
                      "Feedback",
                      onTap: () {
                        Navigator.pushNamed(context, '/feedback');
                      },
                    ),
                    _buildMenuItem(
                      Icons.logout,
                      "Logout",
                      onTap: () {
                        _logout(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<DocumentSnapshot?> _fetchEventDocument() async {
    try {
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('events').limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
    } catch (e) {
      print("Error fetching event: $e");
    }
    return null;
  }
}
