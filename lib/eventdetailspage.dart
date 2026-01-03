import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tarumt_event_app/update_event_page.dart'; // Import Update Event Page
import 'dart:io'; // For handling local files

class EventDetailsPage extends StatelessWidget {
  const EventDetailsPage({super.key, required DocumentSnapshot<Object?> event});

  // Function to delete an event
  Future<void> _deleteEvent(BuildContext context, String eventId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this event?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('events')
                    .doc(eventId)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Event deleted successfully!")),
                );

                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Function to determine the image provider
  ImageProvider? getImageProvider(String imagePath) {
    if (imagePath.isEmpty) {
      return null;
    } else if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      return NetworkImage(imagePath);
    } else if (imagePath.startsWith('file://') || imagePath.startsWith('/')) {
      return FileImage(File(imagePath));
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Events"),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var events = snapshot.data!.docs;

          if (events.isEmpty) {
            return const Center(
              child: Text("No events available"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              var event = events[index];
              final String eventName = event['eventName'] ?? "Unknown Event";
              final String startDate = event['startDate'] ?? "N/A";
              final String endDate = event['endDate'] ?? "N/A";
              final String description =
                  event['description'] ?? "No description available";
              final String venue = event['venue'] ?? "Unknown Venue";
              final String backgroundImage = event['backgroundImage'] ?? "";
              final int totalCost = event['totalCost'] ?? 0;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Image
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: getImageProvider(backgroundImage) != null
                              ? DecorationImage(
                                  image: getImageProvider(backgroundImage)!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: getImageProvider(backgroundImage) == null
                            ? const Center(
                                child: Text(
                                  "No Image Available",
                                  style: TextStyle(color: Colors.black54),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Event Details
                      Text(
                        eventName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildDetailRow("Start Date", startDate),
                      _buildDetailRow("End Date", endDate),
                      _buildDetailRow("Venue", venue),
                      _buildDetailRow("Description", description),
                      _buildDetailRow("Total Cost", "RM $totalCost"),

                      const SizedBox(height: 20),

                      // Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UpdateEventPage(event: event),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: const Text("Update",
                                style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () => _deleteEvent(context, event.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: const Text("Delete",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper function to build detail rows
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.black),
          children: [
            TextSpan(
              text: "$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
