import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateEventPage extends StatefulWidget {
  final DocumentSnapshot event;

  const UpdateEventPage({super.key, required this.event});

  @override
  _UpdateEventPageState createState() => _UpdateEventPageState();
}

class _UpdateEventPageState extends State<UpdateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _meetingLinkController = TextEditingController();

  // Variables for dropdown and date/time pickers
  String? selectedVenue;
  DateTime? _startDate;
  DateTime? _endDate;

  // Venue options for the dropdown
  final List<String> venueOptions = [
    "Dtar",
    "Rimba",
    "Sport Complex",
    "Bangunan Tun Tan Siew Sin",
    "SME Centre",
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing event data
    _eventNameController.text = widget.event['eventName'];
    _descriptionController.text = widget.event['description'];
    _meetingLinkController.text = widget.event['meetingLink'];
    selectedVenue = widget.event['venue'];

    // Parse existing start and end dates
    if (widget.event['startDate'] != null) {
      _startDate = DateTime.parse(widget.event['startDate']);
    }
    if (widget.event['endDate'] != null) {
      _endDate = DateTime.parse(widget.event['endDate']);
    }
  }


Future<void> _updateEvent() async {
  if (_formKey.currentState!.validate()) {
    if (_startDate == null || _endDate == null || selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a venue and date.")),
      );
      return;
    }

    final String startDate = _startDate!.toLocal().toString();
    final String endDate = _endDate!.toLocal().toString();

    try {
      // Query Firestore to check if another event has the same venue and date
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('venue', isEqualTo: selectedVenue)
          .where('startDate', isEqualTo: startDate)
          .where('endDate', isEqualTo: endDate)
          .get();

      // Check if there are duplicate events (excluding the current event)
      if (querySnapshot.docs.isNotEmpty &&
          querySnapshot.docs.any((doc) => doc.id != widget.event.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Duplicate event found! Change venue or date.")),
        );
        return;
      }

      // Proceed with update if no duplicate found
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({
            'eventName': _eventNameController.text,
            'startDate': startDate,
            'endDate': endDate,
            'description': _descriptionController.text,
            'venue': selectedVenue,
            'meetingLink': _meetingLinkController.text,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event updated successfully!")),
      );

      Navigator.pop(context); // Go back to the previous page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating event: $e")),
      );
    }
  }
}


  // Function to show date picker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
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
        setState(() {
          final DateTime selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStartDate) {
            _startDate = selectedDateTime;
          } else {
            _endDate = selectedDateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        title: const Text(
          "Update Event",
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomTextField("Event Name", _eventNameController),
              const SizedBox(height: 24),

              _buildDateTimeField("Start Date & Time", _startDate, true),
              const SizedBox(height: 24),

              _buildDateTimeField("End Date & Time", _endDate, false),
              const SizedBox(height: 24),

              _buildDropdown("Venue", selectedVenue, (value) {
                setState(() {
                  selectedVenue = value;
                });
              }),
              const SizedBox(height: 24),

              _buildCustomTextField("Description", _descriptionController),
              const SizedBox(height: 24),

              _buildCustomTextField("Meeting Link", _meetingLinkController),
              const SizedBox(height: 32),

              _buildButton("Update Event", _updateEvent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter $label",
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
            prefixIcon: Icon(Icons.edit, color: Colors.grey[600]),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "This field is required";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeField(
    String label,
    DateTime? dateTime,
    bool isStartDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, isStartDate),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  dateTime != null
                      ? "${dateTime.toLocal()}"
                      : "Select Date & Time",
                  style: TextStyle(
                    color: dateTime != null ? Colors.black : Colors.grey[600],
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...venueOptions.map(
                        (option) => ListTile(
                          title: Text(
                            option,
                            style: TextStyle(
                              color: value == option ? Colors.purple : Colors.black,
                              fontWeight: value == option ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            onChanged(option);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  value ?? "Select Venue",
                  style: TextStyle(
                    color: value != null ? Colors.black : Colors.grey[600],
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
