import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class AgentDashboard extends StatefulWidget {
  final String agentId;

  const AgentDashboard({Key? key, required this.agentId}) : super(key: key);

  @override
  _AgentDashboardState createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  Stream<QuerySnapshot> _getRequests() {
    return FirebaseFirestore.instance
        .collection('fuel_requests')
        .where('agent_id', isEqualTo: widget.agentId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

Future<Map<String, dynamic>> _fetchOrderDetails(String orderId, String userId, String vehicleId) async {
  // Fetch order details
  final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
  final orderData = orderDoc.exists ? orderDoc.data()! : {};

  // Fetch user details
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  final userData = userDoc.exists ? userDoc.data()! : {};

  // Fetch vehicle details from subcollection
  Map<String, dynamic> vehicleData = {};
  if (vehicleId.isNotEmpty) {
    final vehicleDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(vehicleId)
        .get();
    vehicleData = vehicleDoc.exists ? vehicleDoc.data()! : {};
  }

  return {
    "phone": userData['phone'] ?? 'N/A',
    "vehicleType": vehicleData['vehicleType'] ?? 'N/A',
    "brand": vehicleData['brand'] ?? 'N/A',
    "model": vehicleData['model'] ?? 'N/A',
    "fuelType": vehicleData['fuelType'] ?? 'N/A',
    "quantity": vehicleData['quantity'] ?? 0,
    "plateNumber": vehicleData['licensePlate'] ?? 'N/A',
    "totalCost": orderData['totalCost'] ?? 0,
    "stationId": orderData['stationId'] ?? '',
  };
}

Future<void> _acceptRequest(String requestId, String stationId) async {
  try {
    final requestSnapshot = await FirebaseFirestore.instance.collection('fuel_requests').doc(requestId).get();

    if (!requestSnapshot.exists) {
      print("[ERROR] Fuel request not found!");
      return;
    }

    final requestData = requestSnapshot.data()!;
    final String orderId = requestData['orderId'] ?? '';

    print("[DEBUG] Accepting request with stationId: $stationId for order: $orderId");

    // ✅ Start a Firestore batch update to ensure consistency
    final batch = FirebaseFirestore.instance.batch();

    // ✅ Update fuel_requests with stationId
    final fuelRequestRef = FirebaseFirestore.instance.collection('fuel_requests').doc(requestId);
    batch.update(fuelRequestRef, {
      "status": "accepted",
      "agent_id": widget.agentId,
      "stationId": stationId, 
    });

    // ✅ Update orders with stationId
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
    batch.update(orderRef, {
      "status": "accepted",
      "agentId": widget.agentId,
      "stationId": stationId, 
    });

    // ✅ Commit the batch operation
    await batch.commit();

    print("[SUCCESS] Fuel request and order updated with stationId: $stationId");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request accepted!")),
    );
  } catch (e) {
    print("[ERROR] Failed to accept request: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to accept request: $e")),
    );
  }
}




  Future<void> _declineRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('fuel_requests').doc(requestId).update({
        "status": "declined",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request declined!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to decline request: $e")),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', false);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agent Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _getRequests(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print("Snapshot error: ${snapshot.error}");
              return const Center(child: Text("Error loading requests."));
            }

            final requests = snapshot.data?.docs ?? [];
            if (requests.isEmpty) {
              return const Center(child: Text("No pending requests."));
            }

            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index].data() as Map<String, dynamic>?;
                final requestId = requests[index].id;

                if (request == null) return const SizedBox();

                final String orderId = request['orderId'] ?? '';
                final String userName = request['name'] ?? 'Unknown User';
                final double distance = (request['delivery_distance'] ?? 0).toDouble();
                final Map<String, dynamic>? userLocation = request['location'];
return FutureBuilder<Map<String, dynamic>>(
  future: _fetchOrderDetails(orderId, request['userId'], request['vehicleId']),
  builder: (context, orderSnapshot) {
    if (!orderSnapshot.hasData) {
      return const SizedBox();
    }

    final orderData = orderSnapshot.data!;
    final String phone = orderData['phone'] ?? 'N/A';
    final String vehicleType = orderData['vehicleType'] ?? 'N/A';
    final String brand = orderData['brand'] ?? 'N/A';
    final String vehicleModel = orderData['model'] ?? 'N/A';
    final String fuelType = orderData['fuelType'] ?? 'N/A';
    final double quantity = (orderData['quantity'] ?? 0).toDouble();
    final String plateNumber = orderData['plateNumber'] ?? 'N/A';
    final double totalCost = (orderData['totalCost'] ?? 0).toDouble();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ExpansionTile(
        title: Text(
          "$userName - Distance: $distance km",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Tap to view details"),
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📞 Phone: $phone"),
                Text("🚗 Vehicle: $brand $vehicleModel ($vehicleType)"),
                Text("⛽ Fuel Type: $fuelType"),
                Text("⏳ Quantity: $quantity Litres"),
                Text("🔢 Plate Number: $plateNumber"),
                Text("📍 Location: ${userLocation?['latitude'] ?? 'N/A'}, ${userLocation?['longitude'] ?? 'N/A'}"),
                Text("💰 Total Cost: ₹$totalCost"),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _acceptRequest(requestId, orderData['stationId']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _declineRequest(requestId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  },
);

              },
            );
          },
        ),
      ),
    );
  }
}
