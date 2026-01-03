import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';


class EventRegisterPage extends StatefulWidget {
  const EventRegisterPage({super.key});

  @override
  _EventRegisterPageState createState() => _EventRegisterPageState();
}

class _EventRegisterPageState extends State<EventRegisterPage> {
  bool isPhysical = true;
  String? selectedVenue;
  String? selectedMeeting;
  File? _selectedImage;

  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventStartDateTimeController = TextEditingController();
  final TextEditingController eventEndDateTimeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<String> venueOptions = [
    "Dtar",
    "Rimba",
    "Sport Complex",
    "Bangunan Tun Tan Siew Sin",
    "SME Centre",
  ];
  List<String> meetingOptions = ["Google Meet", "Zoom", "Microsoft Teams"];

  Future<String?> uploadImageToStorage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = FirebaseStorage.instance.ref().child('event_images/$fileName.jpg');
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          controller.text = selectedDateTime.toString();
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  String _generateMeetingLink(String platform) {
    switch (platform) {
      case "Google Meet":
        return "https://meet.google.com/new";
      case "Zoom":
        return "https://zoom.us/j/1234567890";
      case "Microsoft Teams":
        return "https://teams.microsoft.com/l/meetup-join/1234567890";
      default:
        return "No link available";
    }
  }

Future<bool> _isEventConflict(String venue, DateTime startTime, DateTime endTime) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('venue', isEqualTo: venue)
        .get();

    for (var doc in querySnapshot.docs) {
      String eventStartStr = doc['startDate']; // Stored as a string
      String eventEndStr = doc['endDate']; // Stored as a string

      DateTime eventStart = DateTime.parse(eventStartStr);
      DateTime eventEnd = DateTime.parse(eventEndStr);

      // Check for overlap: New event's time overlaps with existing events
      if (!(endTime.isBefore(eventStart) || startTime.isAfter(eventEnd))) {
        return true; // Conflict detected
      }
    }
    return false; // No conflict
  } catch (e) {
    print("Error checking event conflict: $e");
    return false;
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        title: const Text(
          "Host Event",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggleSwitch(),
            const SizedBox(height: 24),
            _buildLabel("Event Name"),
            _buildTextField(eventNameController),
            const SizedBox(height: 16),

            _buildLabel("Event Start"),
            _buildDateTimeField(eventStartDateTimeController),
            const SizedBox(height: 16),

            _buildLabel("Event End"),
            _buildDateTimeField(eventEndDateTimeController),
            const SizedBox(height: 16),

            _buildLabel(isPhysical ? "Venue Option" : "Meeting Option"),
            isPhysical
                ? _buildDropdown(
                    venueOptions,
                    (value) => setState(() => selectedVenue = value),
                  )
                : _buildDropdown(
                    meetingOptions,
                    (value) => setState(() => selectedMeeting = value),
                  ),
            const SizedBox(height: 16),

            _buildLabel("Description"),
            _buildTextField(descriptionController, maxLines: 3),
            const SizedBox(height: 16),

            _buildLabel("Event Image"),
            _buildImageUpload(),
            const SizedBox(height: 24),

            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          _buildToggleButton("Physical", true),
          _buildToggleButton("Online", false),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isPhysical = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPhysical == value ? Colors.purple : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isPhysical == value ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[800],
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: "Enter ${controller == eventNameController ? "event name" : "description"}",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildDateTimeField(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: "Select Date & Time",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
      ),
      onTap: () => _selectDateTime(controller),
    );
  }

  Widget _buildDropdown(List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        hintText: "Select ${isPhysical ? "venue" : "meeting platform"}",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      value: isPhysical ? selectedVenue : selectedMeeting,
      onChanged: onChanged,
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
    );
  }

  Widget _buildImageUpload() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: _selectedImage != null
                  ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[100],
            ),
            child: _selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No Image Selected",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image, color: Colors.white),
              label: const Text(
                "Upload Image",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton(
        onPressed: () async {
          // Get current user
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please login to create an event."),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          if (eventStartDateTimeController.text.isEmpty ||
              eventEndDateTimeController.text.isEmpty ||
              eventNameController.text.isEmpty ||
              (isPhysical && selectedVenue == null) ||
              (!isPhysical && selectedMeeting == null)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please fill in all event details."),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          DateTime startTime = DateTime.parse(eventStartDateTimeController.text);
          DateTime endTime = DateTime.parse(eventEndDateTimeController.text);

          // Validate if an event with the same venue and overlapping time exists
          if (isPhysical) {
            bool hasConflict = await _isEventConflict(
              selectedVenue!,
              startTime,
              endTime,
            );

            if (hasConflict) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "An event with the same venue and overlapping time already exists. "
                    "Please choose a different time or venue.",
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          }

          String? imageUrl;
          if (_selectedImage != null) {
            imageUrl = await uploadImageToStorage(_selectedImage!);
            if (imageUrl == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Failed to upload image. Please try again."),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          }

          String meetingLink = isPhysical
              ? "N/A (Physical Event)"
              : _generateMeetingLink(selectedMeeting!);

          // Calculate total cost (RM 50 per day)
          DateTime start = DateTime.parse(eventStartDateTimeController.text);
          DateTime end = DateTime.parse(eventEndDateTimeController.text);
          int days = end.difference(start).inDays + 1;
          int totalCost = days * 50;

          Navigator.pushNamed(
            context,
            '/eventpayment',
            arguments: {
              'eventName': eventNameController.text,
              'startDate': eventStartDateTimeController.text,
              'endDate': eventEndDateTimeController.text,
              'description': descriptionController.text,
              'isPhysical': isPhysical,
              'venue': isPhysical ? selectedVenue : null,
              'meetingLink': meetingLink,
              'backgroundImage': imageUrl,
              'participater': [],
              'totalCost': totalCost,
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          "Next: Confirm the details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}