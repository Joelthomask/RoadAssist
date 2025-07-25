import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationInputPage extends StatefulWidget {
  final String vehicleId;
  final String fuelType;
  final int quantity;

  const LocationInputPage({
    Key? key,
    required this.vehicleId,
    required this.fuelType,
    required this.quantity,
  }) : super(key: key);

  @override
  _LocationInputPageState createState() => _LocationInputPageState();
}


class _LocationInputPageState extends State<LocationInputPage> {
  final _searchController = TextEditingController();
  String? _vehicleId; // To store the vehicle ID
String? _fuelType;  // To store the fuel type
int? _quantity;     // To store the quantity

  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _selectedLocation; // User-selected location from the search bar
  bool _useCurrentLocation = false; // Tracks if the current location is chosen
  List<dynamic> _suggestions = []; // Suggestions for the search bar
  bool _isSearching = false;

  final String _mapboxApiKey = 'pk.eyJ1Ijoiam9lbGsxMCIsImEiOiJjbTgwNTZzaGswcjd4MmxzYWQxems0cm51In0.DAjd-NBKKIMsbd-Qrvg1kg'; // Replace with your Mapbox API key

@override
void initState() {
  super.initState();

  // Delay accessing context until it's properly initialized
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // Store the arguments in local variables
    setState(() {
      _vehicleId = args['vehicleId'];
      _fuelType = args['fuelType'];
      _quantity = args['quantity'];
    });

    // Debugging logs to ensure arguments are received
    debugPrint("Received vehicleId: $_vehicleId");
    debugPrint("Received fuelType: $_fuelType");
    debugPrint("Received quantity: $_quantity");
  });

  _getCurrentLocation(); // Fetch current location initially
}


Future<String> _generateCustomOrderId() async {
  final prefs = await SharedPreferences.getInstance();

  // Fetch the last used order number from local storage
  final lastOrderNumber = prefs.getInt('lastOrderNumber') ?? 0; // Default to 0 if not set
  final nextOrderNumber = lastOrderNumber + 1;

  // Format the new order ID as "orderXXX"
  final newOrderId = 'order${nextOrderNumber.toString().padLeft(3, '0')}';

  // Save the updated order number locally
  await prefs.setInt('lastOrderNumber', nextOrderNumber);

  print("[DEBUG] Generated Order ID: $newOrderId");
  return newOrderId;
}


  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = latLng;
        if (_useCurrentLocation) {
          _selectedLocation = latLng; // Update selected location if using current location
        }
      });

      // Update the map to focus on the new location
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  // Fetch location suggestions from Mapbox as user types
Future<void> _fetchSuggestions(String query) async {
  final url =
      "https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$_mapboxApiKey&bbox=74.7421,8.1790,77.0434,12.9249";

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _suggestions = data['features'];
      });
    } else {
      debugPrint("Failed to fetch suggestions: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error fetching suggestions: $e");
  }
}


  // Update map when a suggestion is selected
  Future<void> _onSuggestionSelected(dynamic suggestion) async {
    final coordinates = suggestion['geometry']['coordinates'];
    final latLng = LatLng(coordinates[1], coordinates[0]);

    setState(() {
      _searchController.text = suggestion['place_name'];
      _selectedLocation = latLng;
      _useCurrentLocation = false; // User is not using the current location
      _suggestions = []; // Clear suggestions
    });

    // Update the map to focus on the new location
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    }
  }

  // Handle current location button press
  Future<void> _onCurrentLocationPressed() async {
    setState(() {
      _useCurrentLocation = true;
    });
    await _getCurrentLocation();

  }
Future<String?> _addOrderToDatabase() async {
  if (_selectedLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a location.")),
    );
    return null;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint("[ERROR] No authenticated user.");
    return null;
  }

  try {
    debugPrint("[DEBUG] User ID: ${user.uid}");

    // Generate the dynamic orderId
    final newOrderId = await _generateCustomOrderId();
    final newOrderRef = FirebaseFirestore.instance.collection('orders').doc(newOrderId);

    // Order data
    final orderData = {
      'orderId': newOrderId,
      'userId': user.uid,

      'vehicleId': widget.vehicleId,
      'pump_name': null, // ✅ Set to null
      'fuelType': widget.fuelType,
      'quantity': widget.quantity,
      'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
      'status': 'Pending',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    debugPrint("[DEBUG] Saving order data: $orderData");
    await newOrderRef.set(orderData);

    debugPrint("[DEBUG] Order added successfully with Order ID: $newOrderId");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order placed successfully")),
    );

    Navigator.pop(context);
    return newOrderId;
  } catch (e) {
    debugPrint("[ERROR] Error adding order: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Error placing order.")),
    );
    return null;
  }
}

void _onContinue() async {
  if (_selectedLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a location to continue.")),
    );
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint("[ERROR] No authenticated user.");
    return;
  }

  try {
    // Update user's location in Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
      'updatedAt': Timestamp.now(),
    });

    debugPrint("[DEBUG] Updated user location in Firestore.");

    // Create order and navigate
    String? orderId = await _addOrderToDatabase();
    if (orderId != null) {
      debugPrint("[DEBUG] Navigating to FuelOrderPage with orderId: $orderId");

      Navigator.pushNamed(
        context,
        '/fuelorder',
        arguments: {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'orderId': orderId,
        },
      );
    }
  } catch (e) {
    debugPrint("[ERROR] Failed to update user location: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to update location.")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629), // Default to India
              zoom: 5,
            ),
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: MarkerId('selectedLocation'),
                      position: _selectedLocation!,
                      infoWindow: InfoWindow(title: "Selected Location"),
                    ),
                  }
                : _currentLocation != null
                    ? {
                        Marker(
                          markerId: MarkerId('currentLocation'),
                          position: _currentLocation!,
                          infoWindow: InfoWindow(title: "Your Location"),
                        ),
                      }
                    : {},
            onMapCreated: (controller) => _mapController = controller,
          ),
          // Search Box
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _isSearching = true;
                      });
                      _fetchSuggestions(value);
                    } else {
                      setState(() {
                        _isSearching = false;
                        _suggestions = [];
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for a location...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _isSearching = false;
                          _suggestions = [];
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                if (_isSearching && _suggestions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    height: 150,
                    child: ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          title: Text(suggestion['place_name']),
                          onTap: () => _onSuggestionSelected(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Update Current Location Button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: _onCurrentLocationPressed,
              child: Icon(Icons.my_location),
            ),
          ),
          // Continue Button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _onContinue,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                "Continue",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
