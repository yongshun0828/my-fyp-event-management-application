import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  // ignore: unused_field
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open meeting link")),
        );
      }
    }
  }

  Stream<List<DocumentSnapshot>> _getJoinedEvents() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('events')
        .where('participater', arrayContains: user.email)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Widget _buildEventCard(Map<String, dynamic> event, bool isNewEvent) {
    final startDate = DateTime.parse(event['startDate'] as String);
    final endDate = DateTime.parse(event['endDate'] as String);
    final isOnlineEvent = (event['venue'] ?? "Unknown Venue") == "Unknown Venue";
    final now = DateTime.now();
    final isEventActive = now.isAfter(startDate) && now.isBefore(endDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: isNewEvent 
          ? LinearGradient(
              colors: [Colors.purple.shade100, Colors.purple.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isNewEvent ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isNewEvent ? Colors.purple : Colors.grey.shade300,
            width: isNewEvent ? 2 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  event['eventName'] ?? 'Unnamed Event',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isNewEvent ? Colors.purple.shade700 : Colors.black,
                  ),
                ),
              ),
              if (isEventActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (isNewEvent)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: isNewEvent ? Colors.purple : Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Start: ${DateFormat('yyyy-MM-dd HH:mm').format(startDate)}',
                    style: TextStyle(
                      color: isNewEvent ? Colors.purple.shade700 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: isNewEvent ? Colors.purple : Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'End: ${DateFormat('yyyy-MM-dd HH:mm').format(endDate)}',
                    style: TextStyle(
                      color: isNewEvent ? Colors.purple.shade700 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isOnlineEvent ? Icons.video_call : Icons.location_on,
                    size: 16,
                    color: isNewEvent ? Colors.purple : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnlineEvent ? 'Online Event' : event['venue'] ?? 'No venue specified',
                    style: TextStyle(
                      color: isNewEvent ? Colors.purple.shade700 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              if (isOnlineEvent && event['meetingLink'] != null && isEventActive) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.video_call),
                  label: const Text('Join Meeting'),
                  onPressed: () => _launchURL(event['meetingLink']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(List<DocumentSnapshot> events, bool showNewEvents) {
    final now = DateTime.now();
    
    final filteredEvents = events.where((event) {
      final endDate = DateTime.parse(event['endDate'] as String);
      final _ = DateTime.parse(event['startDate'] as String);
      
      if (showNewEvents) {
        // Show current and upcoming events
        return endDate.isAfter(now);
      } else {
        // Show past events
        return endDate.isBefore(now);
      }
    }).toList()
      ..sort((a, b) {
        final aDate = DateTime.parse(a['startDate'] as String);
        final bDate = DateTime.parse(b['startDate'] as String);
        return bDate.compareTo(aDate); // Sort by date descending
      });

    if (filteredEvents.isEmpty) {
      return Center(
        child: Text(
          showNewEvents ? 'No current or upcoming events.' : 'No past events.',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index].data() as Map<String, dynamic>;
        return _buildEventCard(event, showNewEvents);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text('My Events', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Current Joined Events'),
            Tab(text: 'Joined History'),
          ],
        ),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _getJoinedEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You haven\'t joined any events yet.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventsList(snapshot.data!, true),  // Current Events tab
              _buildEventsList(snapshot.data!, false), // History tab
            ],
          );
        },
      ),
    );
  }
} 