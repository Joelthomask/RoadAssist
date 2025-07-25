import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_page.dart';

class OrderSummaryPage extends StatefulWidget {
  final String orderId;

  const OrderSummaryPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderSummaryPageState createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  Map<String, dynamic>? orderDetails;
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderSummary();
  }

  Future<void> _fetchOrderSummary() async {
    try {
      final orderSnapshot = await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();
      if (orderSnapshot.exists) {
        final orderData = orderSnapshot.data();
        if (orderData != null) {
          final userId = orderData['userId'];
          final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          setState(() {
            orderDetails = orderData;
            userDetails = userSnapshot.data();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("[ERROR] Failed to fetch order summary: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userName = userDetails?['username'] ?? "N/A";
    final stationName = orderDetails?['pump_name'] ?? "N/A";
    final fuelType = orderDetails?['fuelType'] ?? "N/A";
    final quantity = orderDetails?['quantity'] ?? 0;

    final fuelCost = ((orderDetails?['fuel_cost'] ?? 0) as num).toDouble().toStringAsFixed(1);
    final deliveryCost = ((orderDetails?['delivery_cost'] ?? 0) as num).toDouble().toStringAsFixed(1);
    final serviceCost = ((orderDetails?['service_cost'] ?? 0) as num).toDouble().toStringAsFixed(1);
    final totalCost = ((orderDetails?['total_Cost'] ?? 0) as num).toDouble().toStringAsFixed(1);

    final dateTime = orderDetails?['createdAt'] != null
        ? (orderDetails?['createdAt'] as Timestamp).toDate().toString()
        : "N/A";

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Order Summary",
                style: TextStyle(fontFamily: "RoadRadio", fontSize: 26.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // Gradient Border Box
              Container(
                width: MediaQuery.of(context).size.width * 0.92, // Slightly thin, fits screen
                padding: const EdgeInsets.all(3.0), // Creates a border effect
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.cyan, Colors.blueAccent], // Gradient border
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18.0), // Slightly rounded
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0), // Longer box
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    color: Colors.white, // Inner white box
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildDetailRow("User Name:", userName),
                      buildDetailRow("Order ID:", widget.orderId),
                      buildDetailRow("Date & Time:", dateTime),
                      buildDetailRow("Fuel Station:", stationName),
                      buildDetailRow("Fuel Quantity:", "$quantity liters"),
                      buildDetailRow("Fuel Type:", fuelType),
                      const Divider(thickness: 1.5, color: Colors.cyan),
                      buildDetailRow("Fuel Cost:", "₹$fuelCost"),
                      buildDetailRow("Delivery Cost:", "₹$deliveryCost"),
                      buildDetailRow("Service Cost:", "₹$serviceCost"),
                      const Divider(thickness: 1.5, color: Colors.cyan),
                      buildDetailRow("Total Cost:", "₹$totalCost", isBold: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Proceed to Payment Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentPage(orderId: widget.orderId)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                  backgroundColor: Colors.cyan,
                ),
                child: const Center(
                  child: Text("Proceed to Payment", style: TextStyle(fontFamily: "RoadRadio", fontSize: 18.0, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDetailRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontFamily: "RoadRadio", fontSize: 16.0, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontFamily: "RoadRadio", fontSize: 16.0, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
