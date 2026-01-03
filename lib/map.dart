import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<Marker> _markers = {};
  String? _selectedLocation;
  List<Map<String, dynamic>> _eventList = [];
  GoogleMapController? _mapController;
  bool _isLoading = false;

  // Predefined Locations with descriptions
  final List<Map<String, dynamic>> _defaultLocations = [
    {
      "name": "Dtar",
      "lat": 3.2164337,
      "lng": 101.7293198,
      "description": "Main campus building",
      "icon": Icons.school
    },
    {
      "name": "Rimba",
      "lat": 3.215872,
      "lng": 101.726659,
      "description": "Student residential area",
      "icon": Icons.home
    },
    {
      "name": "Sport Complex",
      "lat": 3.2181132,
      "lng": 101.7294812,
      "description": "Sports and recreation center",
      "icon": Icons.sports
    },
    {
      "name": "Bangunan Tun Tan Siew Sin",
      "lat": 3.2145999,
      "lng": 101.726078,
      "description": "Administrative building",
      "icon": Icons.business
    },
    {
      "name": "SME Centre",
      "lat": 3.2157535,
      "lng": 101.7290403,
      "description": "Business and entrepreneurship center",
      "icon": Icons.store
    },
  ];

  @override
  void initState() {
    super.initState();
    _addDefaultLocations();
    _loadEvents();
  }

  void _addDefaultLocations() {
    setState(() {
      _markers.clear();
      for (var location in _defaultLocations) {
        _markers.add(
          Marker(
            markerId: MarkerId(location["name"]),
            position: LatLng(location["lat"], location["lng"]),
            infoWindow: InfoWindow(
              title: location["name"],
              snippet: location["description"],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    });
  }

  void _addFilteredLocationMarker() {
    setState(() {
      _markers.clear();
      if (_selectedLocation != null) {
        final location = _defaultLocations.firstWhere(
          (loc) => loc["name"] == _selectedLocation,
          orElse: () => {},
        );

        if (location.isNotEmpty) {
          _markers.add(
            Marker(
              markerId: MarkerId(location["name"]),
              position: LatLng(location["lat"], location["lng"]),
              infoWindow: InfoWindow(title: location["name"]),
            ),
          );

          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(location["lat"], location["lng"]),
                zoom: 19,
              ),
            ),
          );
        }
      } else {
        _addDefaultLocations();
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            const CameraPosition(
              target: LatLng(3.2163834, 101.7277707),
              zoom: 17,
            ),
          ),
        );
      }
    });
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      Query query = _firestore.collection('events');

      if (_selectedLocation != null) {
        query = query.where('venue', isEqualTo: _selectedLocation);
      }

      final QuerySnapshot snapshot = await query.get();
      final DateTime now = DateTime.now();

      setState(() {
        _eventList.clear();
        _markers.clear();
        _addFilteredLocationMarker();
      });

      for (final doc in snapshot.docs) {
        final event = doc.data() as Map<String, dynamic>;

        if (!event.containsKey('eventName') || !event.containsKey('venue')) {
          continue;
        }

        // Parse event dates
        DateTime? startDate;
        DateTime? endDate;
        try {
          startDate = DateTime.parse(event['startDate']);
          endDate = DateTime.parse(event['endDate']);
        } catch (e) {
          print("Error parsing dates: $e");
          continue;
        }

        // Skip past events
        // ignore: unnecessary_null_comparison
        if (endDate != null && endDate.isBefore(now)) {
          continue;
        }

        String eventVenue = event['venue'];

        if (_selectedLocation == null || eventVenue == _selectedLocation) {
          _eventList.add({
            'eventName': event['eventName'],
            'eventDate': event['startDate'],
            'venue': eventVenue,
            'description': event['description'] ?? 'No description available',
            'totalCost': event['totalCost'] ?? 0,
            'startDate': startDate,
            'endDate': endDate,
          });

          if (event.containsKey('latitude') && event.containsKey('longitude')) {
            final double lat = event['latitude'];
            final double lng = event['longitude'];

            setState(() {
              _markers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(
                    title: event['eventName'],
                    snippet: 'Venue: $eventVenue\nDate: ${_formatDate(event['startDate'])}',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
              );
            });
          }
        }
      }

      // Sort events by start date
      _eventList.sort((a, b) {
        final DateTime dateA = a['startDate'] as DateTime;
        final DateTime dateB = b['startDate'] as DateTime;
        return dateA.compareTo(dateB);
      });

    } catch (e) {
      print("❌ Error loading events: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading events. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Filter Events by Venue',
            style: TextStyle(color: Colors.purple),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purple),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedLocation,
                  hint: const Text('Choose a location'),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _defaultLocations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location["name"],
                      child: Row(
                        children: [
                          Icon(location["icon"], color: Colors.purple),
                          const SizedBox(width: 8),
                          Text(location["name"]),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLocation = newValue;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadEvents();
                _addFilteredLocationMarker();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildEventDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final DateTime startDate = event['startDate'] as DateTime;
    final DateTime? endDate = event['endDate'] as DateTime?;
    final bool isUpcoming = startDate.isAfter(DateTime.now());
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              isUpcoming ? Colors.green.shade50 : Colors.orange.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event,
                    color: isUpcoming ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event['eventName'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isUpcoming)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Upcoming',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildEventDetail(
                Icons.location_on,
                'Venue: ${event['venue']}',
              ),
              _buildEventDetail(
                Icons.calendar_today,
                'Start: ${_formatDate(event['eventDate'])}',
              ),
              if (endDate != null)
                _buildEventDetail(
                  Icons.event_available,
                  'End: ${_formatDate(endDate.toString())}',
                ),
              _buildEventDetail(
                Icons.attach_money,
                'Cost: RM ${event['totalCost']}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text(
          'Event Map',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            color: Colors.white,
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 6,
                child: GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    setState(() {});
                  },
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(3.2163834, 101.7277707),
                    zoom: 17,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _eventList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No upcoming events found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _eventList.length,
                              itemBuilder: (context, index) {
                                return _buildEventCard(_eventList[index]);
                              },
                            ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}