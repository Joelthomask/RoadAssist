import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For map functionality
import 'package:http/http.dart' as http; // For API calls
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // For Timer

class FuelOrderPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String orderId; // Pass this dynamically from arguments

  const FuelOrderPage({
    required this.latitude,
    required this.longitude,
    required this.orderId,
  });

  @override
  _FuelOrderPageState createState() => _FuelOrderPageState();
}


class _FuelOrderPageState extends State<FuelOrderPage> {
List<Map<String, dynamic>> _gasStations = []; // Ensure correct type

  bool _isLoading = true; // To show the loading indicator
  bool _isListVisible = true; // Toggle for scrollable list visibility
  LatLng _mapCenter = const LatLng(10.270204135273955, 76.39998199312039); // Default map center
  GoogleMapController? _mapController; // Map controller

@override
void initState() {
  super.initState();
  print("[DEBUG] Received orderId: ${widget.orderId}");

  _fetchGasStationsFromFirestore(widget.orderId).then((_) {
    print("Gas stations fetched successfully for orderId: ${widget.orderId}");
  }).catchError((e) {
    print("Error during initialization for orderId: ${widget.orderId}. Error: $e");
  }).whenComplete(() {
    setState(() {
      _isLoading = false;
    });
  });
}


Future<double> _getRoadDistance(double originLat, double originLng, double destLat, double destLng) async {
  const String mapboxToken = 'pk.eyJ1Ijoiam9lbGsxMCIsImEiOiJjbTgwNTZzaGswcjd4MmxzYWQxems0cm51In0.DAjd-NBKKIMsbd-Qrvg1kg'; // Replace with your Mapbox token
  final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/$originLng,$originLat;$destLng,$destLat'
      '?access_token=$mapboxToken&geometries=geojson');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        return data['routes'][0]['distance'] / 1000; // Distance in kilometers
      }
    }
    return double.infinity; // Return a high value if no route is found
  } catch (e) {
    print('Error fetching road distance: $e');
    return double.infinity;
  }
}Future<void> _fetchGasStationsFromFirestore(String orderId) async {
  try {
    QuerySnapshot stationSnapshot = await FirebaseFirestore.instance.collection('fuelStations').get();
    print("[DEBUG] Fetched ${stationSnapshot.docs.length} gas stations from Firestore.");

    List<Map<String, dynamic>> stations = [];

    for (var doc in stationSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      print("[DEBUG] Processing station: ${doc.id}, Data: $data");

      String name = data['name'] ?? 'Unnamed Station';
      GeoPoint? pumpLocation = data['pump_location']; // Ensure this is a GeoPoint
      if (pumpLocation == null) {
        print("[DEBUG] Skipping station due to missing location: $name");
        continue; // Skip stations with no location
      }

      double pumpLat = pumpLocation.latitude;
      double pumpLng = pumpLocation.longitude;

      bool isAvailable = data['isAvailable'] ?? false;

      double roadDistance = await _getRoadDistance(
        widget.latitude,
        widget.longitude,
        pumpLat,
        pumpLng,
      );

      print("[DEBUG] Station: $name, Road Distance: $roadDistance km, Is Available: $isAvailable");

      if (roadDistance <= 15 && isAvailable) {
        String? agentId;
        QuerySnapshot agentsSnapshot = await FirebaseFirestore.instance
            .collection('fuelStations')
            .doc(doc.id)
            .collection('agents')
            .get();

        if (agentsSnapshot.docs.isNotEmpty) {
          agentId = agentsSnapshot.docs.first.id;
        } else {
          agentId = null;
        }

        // Add the station to the list of available pumps
        stations.add({
          'id': doc.id,
          'name': name,
          'latitude': pumpLat,
          'longitude': pumpLng,
          'distance': roadDistance,
          'agent_id': agentId ?? 'No Agent',
          'phone': data['phone'] ?? 'N/A', // Fetch pump phone if available
        });

        print("[DEBUG] Added station: $name with agentId: $agentId to stations list.");
      }
    }

    setState(() {
      _gasStations = stations; // Update local state with filtered stations
      print("[DEBUG] _gasStations updated: $_gasStations");
    });

    // Store the stations immediately in Firestore under 'available_pumps'
    await _storeStationsInOrder(orderId, stations);

  } catch (e) {
    print("[ERROR] Error fetching gas stations from Firestore: $e");
  } finally {
    // Ensure the loading state is updated regardless of success or failure
    setState(() {
      _isLoading = false;
    });
  }
}
Future<void> _storeStationsInOrder(String orderId, List<Map<String, dynamic>> stations) async {
  try {
    if (stations.isEmpty) {
      print("[DEBUG] No available pumps to store for orderId: $orderId.");
      return;
    }

    for (var station in stations) {
      final pumpDocRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('available_pumps')
          .doc(station['id']); // Use station ID as document ID

      // Prepare the data for each pump
      final pumpData = {
        'name': station['name'] ?? 'Unknown Pump',
        'phone': station['phone'] ?? 'N/A', // Include pump phone
      };

      print("[DEBUG] Storing pump data for orderId: $orderId, Pump: $pumpData");

      // Add data to Firestore
      await pumpDocRef.set(pumpData);
      print("[DEBUG] Successfully stored pump data: ${station['name']} for orderId: $orderId.");
    }

    print("[DEBUG] All pumps successfully stored under orderId: $orderId.");
  } catch (e) {
    print("[ERROR] Failed to store available pumps for orderId: $orderId. Error: $e");
  }
}




  // Function to update the map center based on the selected petrol pump
  void _updateMapCenter(LatLng newCenter) {
    setState(() {
      _mapCenter = newCenter;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(newCenter));
    }
  }



// Generate a unique 'fuelreqXXX' ID



// Generate a unique 'fuelreqXXX' ID
Future<String> _generateCustomDocId() async {
  print("[DEBUG] Generating custom request_id..."); // ✅ Check if function executes

  final collectionRef = FirebaseFirestore.instance.collection('fuel_requests');

  final querySnapshot = await collectionRef
      .orderBy('created_at', descending: true)
      .limit(1)
      .get();

  print("[DEBUG] Query executed. Found ${querySnapshot.docs.length} docs."); // ✅ Debugging

  if (querySnapshot.docs.isNotEmpty) {
    final lastId = querySnapshot.docs.first['request_id'];
    final lastNumber = int.tryParse(lastId.replaceAll('fuelreq', '')) ?? 0;
    final newId = 'fuelreq${(lastNumber + 1).toString().padLeft(3, '0')}';

    print("[DEBUG] New request_id: $newId"); // ✅ Debugging
    return newId;
  }

  print("[DEBUG] No existing requests. Returning default request_id: fuelreq001");
  return 'fuelreq001';
}


void _showSnackBar(String message) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } else {
    print("[ERROR] Widget not mounted, cannot show snackbar.");
  }
}

bool _isRequestAccepted = false;
bool _isRequestDeclined = false;
String? _acceptedStationId;


void _sendRequestToAgent(
    String orderId, String agentId, double latitude, double longitude, double distance, String selectedPumpId) async {
  try {
    setState(() {
      _isRequestAccepted = false;
      _isRequestDeclined = false;
    });

    final requestId = await _generateCustomDocId();  
    print("[DEBUG] Generated request_id: $requestId");

    final docRef = FirebaseFirestore.instance.collection('fuel_requests').doc(requestId);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("[ERROR] User not authenticated.");
      return;
    }

    // ✅ Fetch user details
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      print("[ERROR] User data not found.");
      return;
    }
    final userData = userDoc.data();

    // ✅ Fetch `vehicleId` from the order document
    final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
      print("[ERROR] Order not found!");
      return;
    }

    final String vehicleId = orderDoc.data()?['vehicleId'] ?? '';
    if (vehicleId.isEmpty) {
      print("[ERROR] No vehicleId found in order!");
      return;
    }

    // ✅ Fetch correct vehicle details from user's collection
    final vehicleDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vehicles')
        .doc(vehicleId)
        .get();

    if (!vehicleDoc.exists) {
      print("[ERROR] Vehicle data not found in user's collection!");
      return;
    }

    final vehicleData = vehicleDoc.data();

    // ✅ Fetch `stationId` from available_pumps inside orders collection
    final availablePumpRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('available_pumps')
        .doc(selectedPumpId);

    final availablePumpSnapshot = await availablePumpRef.get();
    if (!availablePumpSnapshot.exists) {
      print("[ERROR] Selected pump not found in available_pumps!");
      return;
    }

    final String stationId = availablePumpSnapshot.id; // ✅ Correct stationId
    final String pumpName = availablePumpSnapshot.data()?['name'] ?? "Unknown";


print("[DEBUG] Preparing request data:");
print("   - Request ID: $requestId");
print("   - Station ID: $stationId");
print("   - Pump Name: $pumpName");
print("   - Order ID: $orderId");
await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
  "stationId": stationId, // ✅ Ensure stationId is set in orders
});


final request = {
  "request_id": requestId,
  "agent_id": agentId,
  "orderId": orderId,
  "userId": user.uid,
  "name": userData?["username"] ?? "Unknown",
  "email": userData?["email"] ?? "Unknown",
  "phone": userData?["phone"] ?? "Unknown",
  "vehicleId": vehicleId,
  "fuelType": vehicleData?["fuelType"] ?? "Petrol",
  "quantity": vehicleData?["quantity"] ?? 0,
  "location": {
    "latitude": latitude,
    "longitude": longitude,
  },
  "stationId": stationId, // ✅ Double-check if this is present
  "pump_name": pumpName,
  "delivery_distance": distance,
  "status": "pending",
  "created_at": FieldValue.serverTimestamp(),
};

// ✅ Print before saving
print("[DEBUG] Final request data before saving: $request");

// ✅ Save to Firestore
await docRef.set(request);


    // ✅ Debugging: Check if the document is saved
    final savedDoc = await docRef.get();
    if (savedDoc.exists) {
      print("[DEBUG] Successfully saved request: ${savedDoc.data()}");
    } else {
      print("[ERROR] Document was not saved!");
    }

    print("[SUCCESS] Fuel request sent: $request");

    _listenForRequestStatus(requestId, orderId);
  } catch (e) {
    print("[ERROR] Failed to send request: $e");
    _showSnackBar("Failed to send request.");
  }
}




// Listen for agent response
void _listenForRequestStatus(String requestId, String orderId) {
  print("[DEBUG] Listening for request status: $requestId");
  FirebaseFirestore.instance
      .collection('fuel_requests')
      .doc(requestId)
      .snapshots()
      .listen((snapshot) async {
    if (snapshot.exists) {
      final data = snapshot.data();
      final status = data?['status'];
      print("[DEBUG] Request Status: $status");

      if (status == 'accepted') {
        final String pumpName = data?['pump_name'] ?? "";
        final String agentId = data?['agent_id'] ?? "";
        final String stationId = data?['stationId'] ?? "blaa";
        final double distance = (data?['delivery_distance'] ?? 0).toDouble();
        final String fuelType = data?['fuel_type'] ?? "Petrol"; 
        final double quantity = (data?['quantity'] ?? 1).toDouble(); 

        // Fetch fuel prices & costs from Firestore settings
        final settingsSnapshot = await FirebaseFirestore.instance
            .collection('settings')
            .doc('fuel_prices')
            .get();

        if (settingsSnapshot.exists && settingsSnapshot.data() != null) {
          final settingsData = settingsSnapshot.data()!;
          
          double petrolPrice = (settingsData['petrol_price'] ?? 20).toDouble();
          double dieselPrice = (settingsData['diesel_price'] ?? 50).toDouble();
          double deliveryCostPerKm = (settingsData['delivery_price_per_km'] ?? 8).toDouble();
          double serviceCost = (settingsData['service_cost'] ?? 150).toDouble();

          double fuelPrice = (fuelType == "Petrol") ? petrolPrice : dieselPrice;
          double fuelCost = fuelPrice * quantity;
          double deliveryCost = distance * deliveryCostPerKm;
          double totalCost = fuelCost + deliveryCost + serviceCost;

          print("[DEBUG] Updating order: $orderId with pump: $pumpName, stationId: $stationId");

          await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
            'pump_name': pumpName,
            'agentId': agentId,
            'stationId': stationId,
            'fuel_cost': fuelCost,
            'delivery_cost': deliveryCost,
            'service_cost': serviceCost,
            'total_Cost': totalCost,
            'delivery_distance': distance,
            "status": "accepted",
          });

          setState(() {
            _isRequestAccepted = true;
            _acceptedStationId = stationId;
          });

          _showDialog("Request Accepted", "Your fuel request has been accepted. Order details updated.");
        } else {
          print("[ERROR] Fuel prices document is missing or empty!");
        }
      } else if (status == 'declined') {
        setState(() {
          _isRequestDeclined = true;
        });

        _showDialog("Request Declined", "Your fuel request was declined. Please try another station.");
      }
    }
  });
}





// Handle continue button
void _onContinue() {
  print("[DEBUG] Continue button pressed. _isRequestAccepted: $_isRequestAccepted, _acceptedStationId: $_acceptedStationId");

  if (_isRequestAccepted && _acceptedStationId != null) {
    Navigator.pushNamed(context, '/order_summary', arguments: {'orderId': widget.orderId});
    print("[DEBUG] Navigating to Order Summary.");
  } else {
    _showSnackBar("No accepted requests yet. Please wait.");
  }
}


// Show pop-up message
void _showDialog(String title, String content) {
  if (mounted) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Icon(Icons.location_on, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Your Location: (${widget.latitude}, ${widget.longitude})",
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
    body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Gas Stations",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isListVisible
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                      ),
                      onPressed: () {
                        setState(() {
                          _isListVisible = !_isListVisible;
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (_isListVisible)
                Container(
                  height: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _gasStations.length,
                    itemBuilder: (context, index) {
                      final station = _gasStations[index];

                      // Null-safe variable assignments
                      final String name = station['name'] ?? 'Unknown Station';
                      final double pumpLat = station['latitude'] ?? 0.0;
                      final double pumpLng = station['longitude'] ?? 0.0;
                      final double distance = station['distance'] ?? 0.0;
                      final String agentId = station['agent_id'] ?? 'No Agent';

                      return ListTile(
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Distance: ${distance.toStringAsFixed(2)} km",
                            ),
                            Text(
                              "Agent: ${agentId != 'No Agent' ? agentId : 'No Agent'}",
                            ),
                          ],
                        ),
                      trailing: agentId != 'No Agent'
    ? IconButton(
        icon: Icon(Icons.send, color: Colors.blue),
        onPressed: () {
          final String selectedPumpId = station['id'] ?? ''; // Ensure pump ID is passed
          
          if (selectedPumpId.isNotEmpty) {
            print("[DEBUG] Sending request to agent: $agentId for pump: $selectedPumpId with orderId: ${widget.orderId}");

            _sendRequestToAgent(
              widget.orderId, 
              agentId,        
              widget.latitude, 
              widget.longitude, 
              distance,       
              selectedPumpId,  // ✅ Fix: Pass the correct pump ID
            );
          } else {
            print("[ERROR] Pump ID is missing!");
          }
        },
      )
    : Text("No Agent", style: TextStyle(color: Colors.red)),


                        onTap: () {
                          // Update map center only if coordinates are valid
                          if (pumpLat != 0.0 && pumpLng != 0.0) {
                            _updateMapCenter(LatLng(pumpLat, pumpLng));
                          } else {
                            print("Error: Missing pump latitude or longitude.");
                          }
                        },
                      );
                    },
                  ),
                ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _mapCenter,
                    zoom: 12,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _gasStations.map((station) {
                    final double? pumpLat = station['latitude'];
                    final double? pumpLng = station['longitude'];
                    final String name = station['name'] ?? 'Unknown Station';

                    // Skip markers with invalid coordinates
                    if (pumpLat == null || pumpLng == null) {
                      return null;
                    }

                    return Marker(
                      markerId: MarkerId(name),
                      position: LatLng(pumpLat, pumpLng),
                      infoWindow: InfoWindow(
                        title: name,
                        snippet: station['address'] ?? 'No Address Available',
                      ),
                    );
                  }).whereType<Marker>().toSet(), // Remove null markers
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.cyan, Colors.cyanAccent],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Continue',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
  );
}
}