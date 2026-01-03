import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tarumt_event_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'loginpage.dart';
import 'registrationpage.dart';
import 'homepage.dart';
import 'user_profile_page.dart';
import 'eventregister.dart';
import 'attendance.dart';
import 'staffpage.dart';
import 'userdetailspage.dart';
import 'eventpayment.dart';
import 'eventdetailspage.dart';
import 'update_event_page.dart';
import 'meeting.dart';
import 'studentlist.dart';
import 'map.dart';
import 'code.dart';
import 'feedback.dart';
import 'announcement.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  

  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text("Error initializing Firebase")),
            ),
          );
        }
        return MaterialApp(
          title: 'TARUMT Event Management Application',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const HomePage(),
          debugShowCheckedModeBanner: false,
          onGenerateRoute: (settings) {
            if (settings.name == '/eventpayment') {
              final args = settings.arguments as Map<String, dynamic>? ?? {};

              int calculateTotalCost(String startDate, String endDate) {
                try {
                  DateTime start = DateTime.parse(startDate);
                  DateTime end = DateTime.parse(endDate);
                  int days = end.difference(start).inDays + 1;
                  return days * 50;
                } catch (e) {
                  return 0; // Handle invalid date format
                }
              }

              int totalCost = calculateTotalCost(
                args['startDate'] ?? '',
                args['endDate'] ?? '',
              );

              return MaterialPageRoute(
                builder: (context) => PaymentPage(
                  eventName: args['eventName'] ?? "Unknown Event",
                  startDate: args['startDate'] ?? "N/A",
                  endDate: args['endDate'] ?? "N/A",
                  description: args['description'] ?? "No description available",
                  venue: args['venue'] ?? "Unknown Venue",
                  meetingLink: args['meetingLink'] ?? "No Link",
                  isPhysical: args['isPhysical'] ?? false,
                  backgroundImage: args['backgroundImage'] ?? "",
                  totalCost: totalCost, createdBy: '',
                ),
              );
            }

            if (settings.name == '/eventdetails') {
              final event = settings.arguments as DocumentSnapshot?;
              if (event == null) {
                return MaterialPageRoute(
                  builder: (context) => const HomePage(),
                );
              }
              return MaterialPageRoute(
                builder: (context) => EventDetailsPage(event: event),
              );
            }

            if (settings.name == '/updateevent') {
              final event = settings.arguments as DocumentSnapshot?;
              if (event == null) {
                return MaterialPageRoute(
                  builder: (context) => const HomePage(),
                );
              }
              return MaterialPageRoute(
                builder: (context) => UpdateEventPage(event: event),
              );
            }

            // Handle unknown routes
            return MaterialPageRoute(
              builder: (context) => const HomePage(),
            );
          },
          routes: {
            '/login': (context) => LoginPage(),
            '/registration': (context) => const RegistrationPage(),
            '/home': (context) => const HomePage(),
            '/user': (context) => UserProfilePage(),
            '/event': (context) => EventRegisterPage(),
            '/attendance': (context) => AttendancePage(),
            '/staff': (context) => StaffProfilePage(),
            '/userdetails': (context) => UserDetailsPage(),
            '/meeting': (context) => MeetingPage(),
            '/code': (context) => CodePage(),
            '/map': (context) => MapPage(),
            '/studentlist': (context) => StudentListPage(),
            '/feedback' : (context) => FeedbackPage(),
            '/announcement' : (context) => AnnouncementPage(),
          },
        );
      },
    );
  }
}
