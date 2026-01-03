import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _feedbackController = TextEditingController();
  double _rating = 3.0;
  String? _selectedEvent;
  bool _isStaff = false;
  // ignore: unused_field
  DateTime? _eventEndDate;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
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
    _feedbackController.dispose();
    super.dispose();
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
      ),
    );
  }

  Future<void> _checkUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          setState(() {
            _isStaff = userData['role'] == 'staff';
          });
        }
      } catch (e) {
        print("Error checking user role: $e");
      }
    }
  }

  // Check if user has joined the event
  Future<bool> _hasUserJoinedEvent(String eventName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final querySnapshot = await _firestore
          .collection('events')
          .where('eventName', isEqualTo: eventName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final eventData = querySnapshot.docs.first.data();
        final participaters = List<String>.from(eventData['participater'] ?? []);
        return participaters.contains(user.email);
      }
      return false;
    } catch (e) {
      print("Error checking if user joined event: $e");
      return false;
    }
  }

  // Fetch all event names from Firestore
  Future<List<String>> _fetchEventNames() async {
    try {
    final querySnapshot = await _firestore.collection('events').get();
      final now = DateTime.now();
      
      List<String> completedEvents = [];
      
      for (var doc in querySnapshot.docs) {
        final eventData = doc.data();
        
        if (!eventData.containsKey('endDate')) {
          continue;
        }
        
        try {
          final endDateStr = eventData['endDate'] as String;
          final endDate = DateTime.parse(endDateStr);
          
          // Include all ended events for viewing feedback
          if (now.isAfter(endDate)) {
            completedEvents.add(eventData['eventName'].toString());
          }
        } catch (e) {
          print("Error processing event ${eventData['eventName']}: $e");
        }
      }
      
      return completedEvents;
    } catch (e) {
      print("Error fetching event names: $e");
      return [];
    }
  }

  // Check if event has ended
  Future<bool> _hasEventEnded(String eventName) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('eventName', isEqualTo: eventName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final eventData = querySnapshot.docs.first.data();
        final endDateStr = eventData['endDate'] as String;
        
        // Parse the string date
        final endDate = DateTime.parse(endDateStr);
        setState(() {
          _eventEndDate = endDate;
        });
        
        return DateTime.now().isAfter(endDate);
      }
      return false;
    } catch (e) {
      print("Error checking event end date: $e");
      return false;
    }
  }

  // Submit feedback
  Future<void> _submitFeedback() async {
    if (_selectedEvent == null || _feedbackController.text.isEmpty) {
      _showMessage("Please select an event and write feedback!");
      return;
    }

    // Check if user has joined the event
    bool hasJoined = await _hasUserJoinedEvent(_selectedEvent!);
    if (!hasJoined) {
      _showMessage("You can only submit feedback for events you have joined.", isError: true);
      return;
    }

    // Check if event has ended
    bool hasEnded = await _hasEventEnded(_selectedEvent!);
    if (!hasEnded) {
      _showMessage("You can only submit feedback after the event has ended.", isError: true);
      return;
    }

    final eventQuery = await _firestore.collection('events')
      .where('eventName', isEqualTo: _selectedEvent)
      .get();

    if (eventQuery.docs.isNotEmpty) {
      final eventDoc = eventQuery.docs.first.reference;

      // Check if user has already submitted feedback
      final existingFeedback = await eventDoc.collection('feedback')
          .where('userEmail', isEqualTo: _auth.currentUser?.email)
          .get();

      if (existingFeedback.docs.isNotEmpty) {
        _showMessage("You have already submitted feedback for this event.", isError: true);
        return;
      }

      await eventDoc.collection('feedback').add({
        'rating': _rating,
        'comment': _feedbackController.text,
        'timestamp': Timestamp.now(),
        'userEmail': _auth.currentUser?.email,
      });

      _feedbackController.clear();
      _showMessage('Feedback submitted successfully!');
      setState(() {});
    } else {
      _showMessage('Event not found!', isError: true);
    }
  }

  // Fetch feedback for the selected event
  Stream<QuerySnapshot> _getFeedbackStream() {
    if (_selectedEvent == null) return const Stream.empty();

    return _firestore.collection('events')
      .where('eventName', isEqualTo: _selectedEvent)
      .get().asStream().asyncExpand((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.first.reference.collection('feedback')
            .orderBy('timestamp', descending: true)
            .snapshots();
        }
        return const Stream.empty();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: Row(
          children: [
            const Icon(Icons.feedback, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Event Feedback', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Selection Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: FutureBuilder<List<String>>(
              future: _fetchEventNames(),
              builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    );
                  }
                return DropdownButton<String>(
                  hint: const Text("Select an Event"),
                  value: _selectedEvent,
                  isExpanded: true,
                    underline: const SizedBox(),
                  items: snapshot.data!.map((eventName) {
                    return DropdownMenuItem(
                      value: eventName,
                      child: Text(eventName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedEvent = value);
                  },
                );
              },
            ),
            ),
            const SizedBox(height: 24),

            // Feedback Submission Section
            if (!_isStaff && _selectedEvent != null) ...[
              FutureBuilder<bool>(
                future: _hasUserJoinedEvent(_selectedEvent!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final hasJoined = snapshot.data!;
                  if (!hasJoined) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "You need to join this event to submit feedback.",
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Rate this event",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                _controller.forward().then((_) => _controller.reverse());
                                setState(() => _rating = index + 1.0);
                              },
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Icon(
                                  index < _rating ? Icons.star : Icons.star_border,
                                  color: Colors.orange,
                                  size: 32,
                                ),
                              ),
                );
              }),
            ),
                        const SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
                          decoration: InputDecoration(
                            labelText: 'Write your feedback',
                            hintText: 'Share your experience...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                            onPressed: () {
                              _controller.forward().then((_) => _controller.reverse());
                              _submitFeedback();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Submit Feedback",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Feedback List Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFeedbackStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.feedback_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No feedback available yet",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final feedback = doc.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${feedback['rating'].toInt()}',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: List.generate(5, (index) {
                                            return Icon(
                                              index < (feedback['rating'] as num)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.orange,
                                              size: 16,
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy • hh:mm a').format(
                                            (feedback['timestamp'] as Timestamp).toDate(),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                feedback['comment'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
