import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  String inputCode = "";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onKeyTap(String value) async {
    _controller.forward().then((_) => _controller.reverse());
    
    setState(() {
      if (value == "X") {
        inputCode = inputCode.isNotEmpty ? inputCode.substring(0, inputCode.length - 1) : "";
      } else if (value == "✔" && inputCode.length == 6) {
        _submitAttendance();
      } else if (inputCode.length < 6) {
        inputCode += value;
      }
    });
  }

  Future<void> _submitAttendance() async {
    String userEmail = _auth.currentUser?.email ?? "";

    if (userEmail.isEmpty) {
      _showMessage("User not logged in.", isError: true);
      return;
    }

    try {
      QuerySnapshot eventSnapshot = await _firestore
          .collection("events")
          .where("code", isEqualTo: inputCode)
          .limit(1)
          .get();

      if (eventSnapshot.docs.isEmpty) {
        _showMessage("Invalid attendance code.", isError: true);
        return;
      }

      var eventDoc = eventSnapshot.docs.first;
      String eventName = eventDoc["eventName"];
      List<dynamic> participants = eventDoc["participater"] ?? [];

      if (!participants.contains(userEmail)) {
        _showMessage("You have not joined this event.", isError: true);
        return;
      }

      // Check if user has already registered attendance
      var attendanceDoc = await _firestore
          .collection("events")
          .doc(eventDoc.id)
          .collection("attend")
          .doc(userEmail)
          .get();

      if (attendanceDoc.exists) {
        Timestamp lastAttendance = attendanceDoc["timestamp"];
        DateTime lastAttendanceTime = lastAttendance.toDate();
        DateTime now = DateTime.now();
        
        // Check if the last attendance was on the same day
        if (lastAttendanceTime.year == now.year &&
            lastAttendanceTime.month == now.month &&
            lastAttendanceTime.day == now.day) {
          _showAttendanceDialog(
            "Already Registered",
            "You have already registered your attendance for $eventName today.",
            Icons.info_outline,
            Colors.orange,
          );
          setState(() => inputCode = "");
          return;
        }
      }

      await _firestore
          .collection("events")
          .doc(eventDoc.id)
          .collection("attend")
          .doc(userEmail)
          .set({"email": userEmail, "timestamp": FieldValue.serverTimestamp()});

      _showMessage("Attendance registered for $eventName!", isError: false);
      setState(() => inputCode = "");
    } catch (e) {
      _showMessage("Error: ${e.toString()}", isError: true);
    }
  }

  void _showAttendanceDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Last registered: ${DateFormat('HH:mm:ss').format(DateTime.now())}",
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => inputCode = "");
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (isError) {
      _showAttendanceDialog(
        "Error",
        message,
        Icons.error_outline,
        Colors.red,
      );
    } else {
      _showAttendanceDialog(
        "Success",
        message,
        Icons.check_circle_outline,
        Colors.green,
      );
    }
  }

  Future<void> _showAttendanceHistory() async {
    String userEmail = _auth.currentUser?.email ?? "";
    if (userEmail.isEmpty) return;

    QuerySnapshot eventsSnapshot = await _firestore.collection("events").get();
    DateTime now = DateTime.now();

    List<Map<String, String>> todayAttendedEvents = [];
    for (var event in eventsSnapshot.docs) {
      var attendSnapshot = await event.reference.collection("attend").doc(userEmail).get();
      if (attendSnapshot.exists) {
        Timestamp timestamp = attendSnapshot["timestamp"];
        DateTime attendTime = timestamp.toDate();
        
        // Only add events attended today
        if (attendTime.year == now.year &&
            attendTime.month == now.month &&
            attendTime.day == now.day) {
          String attendTimeStr = DateFormat('HH:mm:ss').format(attendTime);
          todayAttendedEvents.add({
            "eventName": event["eventName"],
            "attendTime": attendTimeStr,
          });
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.event_available, color: Colors.purple),
            const SizedBox(width: 8),
            const Text("Today's Attendance"),
          ],
        ),
        content: todayAttendedEvents.isEmpty
            ? const Center(
                child: Text("No attendance records for today."),
              )
            : SizedBox(
                height: 300,
                width: 300,
                child: ListView.builder(
                  itemCount: todayAttendedEvents.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          todayAttendedEvents[index]["eventName"] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Attended at: ${todayAttendedEvents[index]["attendTime"]}",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event_available, color: Colors.green),
                        ),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        title: const Text("Attendance", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _showAttendanceHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    "Enter Attendance Code",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please enter the 6-digit code to register your attendance",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 45,
                  height: 45,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: index < inputCode.length ? Colors.purple : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    index < inputCode.length ? inputCode[index] : "",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: _buildKeypad(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    List<String> keys = [
      "1", "2", "3",
      "4", "5", "6",
      "7", "8", "9",
      "X", "0", "✔"
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          return ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: () => _onKeyTap(keys[index]),
              child: Container(
                decoration: BoxDecoration(
                  color: keys[index] == "X" 
                      ? Colors.red[50]
                      : keys[index] == "✔"
                          ? Colors.green[50]
                          : Colors.purple[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: keys[index] == "X"
                        ? Colors.red[300]!
                        : keys[index] == "✔"
                            ? Colors.green[300]!
                            : Colors.purple[300]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    keys[index],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: keys[index] == "X"
                          ? Colors.red[700]
                          : keys[index] == "✔"
                              ? Colors.green[700]
                              : Colors.purple[700],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
