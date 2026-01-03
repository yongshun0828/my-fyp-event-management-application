import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentPage extends StatefulWidget {
  final String eventName;
  final String startDate;
  final String endDate;
  final String description;
  final String venue;
  final String meetingLink;
  final bool isPhysical;
  final String backgroundImage; 
  final int totalCost;
  final String createdBy; 

  const PaymentPage({
    super.key,
    required this.eventName,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.venue,
    required this.meetingLink,
    required this.isPhysical,
    required this.backgroundImage,
    required this.totalCost,
    required this.createdBy, 
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isUploading = false;
  String? _imageUrl; // Holds the uploaded image URL

  @override
  void initState() {
    super.initState();
    // If the backgroundImage is already a URL, use it directly
    if (widget.backgroundImage.startsWith('https://')) {
      _imageUrl = widget.backgroundImage;
    }
  }

  // Function to upload image to Firebase Storage
  Future<String?> uploadImageToStorage(String filePath) async {
    try {
      print("Starting image upload...");
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference =
          FirebaseStorage.instance.ref().child('event_images/$fileName.jpg');
      File file = File(filePath);
      if (!await file.exists()) {
        print("File does not exist at path: $filePath");
        return null;
      }
      UploadTask uploadTask = storageReference.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      print("Image uploaded successfully. URL: $downloadURL");
      return downloadURL;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

Future<void> _showConfirmationDialog(BuildContext context) async {
  print("Showing Confirmation Dialog...");

  return showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing by tapping outside
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Your event has been created successfully."),
        actions: [
          TextButton(
            onPressed: () async {
              print("OK button pressed, closing dialog...");
              Navigator.of(dialogContext).pop(); // Close dialog

              if (mounted) {
                print("Calling _processPayment...");
                await _processPayment(context);
              }
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}


Future<void> _processPayment(BuildContext context) async {
  if (_isUploading) return; 

  setState(() {
    _isUploading = true;
  });

  print("Processing Payment Started");

  if (_imageUrl == null && widget.backgroundImage.isNotEmpty) {
    print("Uploading Image...");
    _imageUrl = await uploadImageToStorage(widget.backgroundImage);

    if (_imageUrl == null) {
      print("Image Upload Failed");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to upload image. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }
  }

  print("Saving Event to Firestore...");
  await _saveEventToFirestore();

  if (mounted) {
    print("Navigating to Home Page...");
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  setState(() {
    _isUploading = false;
  });

  print("Processing Payment Finished");
}



  // Function to save event details to Firestore
  Future<void> _saveEventToFirestore() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User must be logged in to create an event');
    }

    await firestore.collection('events').add({
      'eventName': widget.eventName,
      'startDate': widget.startDate,
      'endDate': widget.endDate,
      'description': widget.description,
      'venue': widget.venue,
      'meetingLink': widget.isPhysical ? "N/A (Physical Event)" : widget.meetingLink,
      'totalCost': widget.totalCost,
      'backgroundImage': _imageUrl ?? "No Image",
      'createdAt': Timestamp.now(),
      'participater': [],
      'createdBy': user.email, // Use the current user's email directly
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Event Payment",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Image Box
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: _imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_imageUrl!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.2),
                                BlendMode.darken,
                              ),
                            )
                          : widget.backgroundImage.isNotEmpty
                              ? DecorationImage(
                                  image: FileImage(File(widget.backgroundImage)),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.2),
                                    BlendMode.darken,
                                  ),
                                )
                              : null,
                      color: widget.backgroundImage.isEmpty ? Colors.grey[200] : null,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: widget.backgroundImage.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "No Image Available",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Event Details Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Event Details",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(Icons.event, "Event Name", widget.eventName),
                          _buildDetailRow(Icons.calendar_today, "Start Date", widget.startDate),
                          _buildDetailRow(Icons.event, "End Date", widget.endDate),
                          _buildDetailRow(Icons.description, "Description", widget.description),
                          _buildDetailRow(Icons.location_on, "Venue", widget.venue),
                          _buildDetailRow(
                            Icons.video_call,
                            "Meeting Link",
                            widget.isPhysical ? "N/A (Physical Event)" : widget.meetingLink,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Cost",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple,
                                  ),
                                ),
                                Text(
                                  "RM ${widget.totalCost}",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Button
                  Container(
                    width: double.infinity,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : () => _showConfirmationDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Proceed to Payment",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}