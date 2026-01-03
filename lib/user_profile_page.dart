import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  Future<DocumentSnapshot?> _getUserData(String? email) async {
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
      print("Error fetching user data: $e");
    }
    return null;
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

    // Navigate to login page and clear navigation stack
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  } catch (e) {
    print("❌ Logout Error: $e");
  }
}



  @override
Widget build(BuildContext context) {
  final User? user = FirebaseAuth.instance.currentUser;

  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      backgroundColor: Colors.purple,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context, '/home');
        },
      ),
      title: const Text(
        "User Profile",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
    ),
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            Navigator.pushReplacementNamed(context, '/user');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
        ],
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    body: FutureBuilder<DocumentSnapshot?>(
      future: _getUserData(user?.email),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading profile...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  "Error: ${snapshot.error}",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
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
                Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "User data not found",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String name = userData['name'] ?? "No Name";
        final String email = userData['email'] ?? "No Email";
        final String profileImage = userData['profileImage'] ?? "";

        return Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.purple,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/userdetails');
                    },
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundImage: profileImage.isNotEmpty
                                ? NetworkImage(profileImage)
                                : const AssetImage('assets/images/user.png') as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
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
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Attendance Card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/attendance');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mail,
                            color: Colors.purple,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Attendance",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
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
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMenuItem(
                    Icons.notifications,
                    "Announcement",
                    onTap: () {
                      Navigator.pushNamed(context, '/announcement');
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
                    "Event Meeting",
                    onTap: () {
                      Navigator.pushNamed(context, '/meeting');
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
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
