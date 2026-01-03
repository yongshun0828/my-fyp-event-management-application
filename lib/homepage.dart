import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Track selected tab
  late String currentDate;

  @override
void initState() {
  super.initState();
  _initializeNotifications(); // Initialize local notifications
  _updateDate();
}

  void _updateDate() {
    final now = DateTime.now();
    setState(() {
      currentDate = "${now.day} - ${now.month} ${_getWeekday(now.weekday)}";
    });
  }

  String _getWeekday(int weekday) {
    const weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    return weekdays[weekday - 1];
  }

  Future<FirebaseApp> _initializeFirebase() async {
    return await Firebase.initializeApp();
  }

  Future<void> _navigateToUserPage(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try{
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
        
        if (querySnapshot.docs.isNotEmpty){
          var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
          String userRole = userData['role'] ?? 'user';

          if (userRole == 'staff'){
            print("Staff user, navigating to Staff Page");
            Navigator.pushNamed(context, '/staff');
          }else{
            print("Regular user, navigating to User Page");
            Navigator.pushNamed(context, '/user');
          }
        }
      } catch (e) {
        print("Error fetching user data: $e");
        Navigator.pushNamed(context, '/user');
      }
    } else {
      print("User not logged in, redirecting to Login Page");
      Navigator.pushNamed(context, '/login');
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      _navigateToUserPage(context);
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Request permission (Android 13+)
  if (await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ==
      false) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}


Future<void> _showNotification(String eventName, String startDate) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'event_channel_id',
    'Event Notifications',
    channelDescription: 'Notifications for event participation',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Event Joined',
    'You have successfully joined $eventName. \nStart Date: $startDate',
    platformChannelSpecifics,
  );
}  

void _showEventDetails(BuildContext context, DocumentSnapshot event) {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Login Required',
            style: TextStyle(color: Colors.purple),
          ),
          content: const Text(
            'You need to be logged in to view event details. Would you like to login now?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamed(context, '/login'); // Navigate to login page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
    return;
  }

  final venue = event['venue'] ?? "Unknown Venue";
  final isOnlineEvent = venue == "Unknown Venue";
  final eventData = event.data() as Map<String, dynamic>? ?? {};
  final participaters = List<String>.from(eventData['participater'] ?? []);
  final hasJoined = participaters.contains(user.email);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: const Color.fromARGB(255, 143, 227, 186),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  eventData['eventName'] ?? 'Unnamed Event',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 10),
            if (eventData['backgroundImage'] != null)
              Image.network(
                eventData['backgroundImage'],
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 10),
            Text(
              "Date: ${eventData['startDate'] ?? 'No Date'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Details: ${eventData['description'] ?? 'No Description'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (!isOnlineEvent)
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: user.email)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData = snapshot.data!.docs.firstOrNull?.data() as Map<String, dynamic>?;
                  final isStaff = userData?['role'] == 'staff';

                  // Don't show anything for staff members
                  if (isStaff) {
                    return const SizedBox.shrink();
                  }

                  return Center(
                child: ElevatedButton(
                      onPressed: hasJoined ? null : () => _joinEvent(context, event),
                  style: ElevatedButton.styleFrom(
                        backgroundColor: hasJoined ? Colors.grey : Colors.blue,
                      ),
                      child: Text(
                        hasJoined ? "Already Joined" : "Join Event",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            if (isOnlineEvent && eventData['meetingLink'] != null)
              Center(
                child: ElevatedButton(
                  onPressed: () => _launchURL(eventData['meetingLink']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    "Join Meeting",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

  void _joinEvent(BuildContext context, DocumentSnapshot event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Show dialog instead of snackbar
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Login Required',
              style: TextStyle(color: Colors.purple),
            ),
            content: const Text(
              'You need to be logged in to join this event. Would you like to login now?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamed(context, '/login'); // Navigate to login page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login'),
              ),
            ],
          );
        },
      );
      return;
    }

    final venue = event['venue'] ?? "Unknown Venue";
    if (venue == "Unknown Venue") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This is an online event. Join from the Meeting Page."),
        ),
      );
      return;
    }

    // Check if user has already joined
    final eventData = event.data() as Map<String, dynamic>? ?? {};
    final participaters = List<String>.from(eventData['participater'] ?? []);
    if (participaters.contains(user.email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have already joined this event."),
        ),
      );
      return;
    }

    // Initialize participater array if it doesn't exist
    Map<String, dynamic> updateData = {
      'participater': FieldValue.arrayUnion([user.email]),
    };

    await FirebaseFirestore.instance.collection('events').doc(event.id).update(updateData);

    _showNotification(eventData['eventName'], eventData['startDate']); // Send notification

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Joined ${eventData['eventName']}")),
    );
  }


void _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Could not open link")));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  decoration: BoxDecoration(
                  color: Colors.purple,
                  ),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end, 
                        children: [
                          Image.asset('assets/images/logo1.png', height: 55),
                          const SizedBox(width: 15),
                          Text(
                            currentDate,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Tunku Abdul Rahman University Of Management And Technology",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Events List Section
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('events').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
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
                                'Loading events...',
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

                      var now = DateTime.now();
                      var events = snapshot.data!.docs.where((event) {
                        try {
                          String? dateString = event['startDate'];
                          if (dateString == null) return false;
                          DateTime eventDate = DateTime.parse(dateString);
                          return eventDate.isAfter(now) || eventDate.isAtSameMomentAs(now);
                        } catch (e) {
                          return false;
                        }
                      }).toList();

                      if (events.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.event_busy,
                                  size: 70,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "No upcoming events",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Check back later for new events",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          var event = events[index];
                          return GestureDetector(
                            onTap: () => _showEventDetails(context, event),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    // Event Image
                                    Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                image: event['backgroundImage'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(event['backgroundImage']),
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(
                                                  Colors.black.withOpacity(0.3),
                                          BlendMode.darken,
                                        ),
                                      )
                                    : null,
                                color: Colors.grey[200],
                              ),
                                      child: event['backgroundImage'] == null
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      size: 48,
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    "No Image Available",
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : null,
                                    ),
                                    // Event Details Overlay
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.9),
                                              Colors.black.withOpacity(0.7),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['eventName'] ?? 'Unnamed Event',
                                      style: const TextStyle(
                                                fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.calendar_today,
                                                    size: 16,
                                                    color: Colors.white.withOpacity(0.9),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                    Text(
                                      event['startDate'] ?? 'No Date',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Colors.white.withOpacity(0.9),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    event['venue'] ?? 'Unknown Venue',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white.withOpacity(0.9),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "User"),
        ],
        onTap: _onBottomNavTap,
      ),
    );
  }
}