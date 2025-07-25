import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class OrderStatusPage extends StatefulWidget {
  final String requestId; // The ID of the user's fuel request

  const OrderStatusPage({Key? key, required this.requestId}) : super(key: key);

  @override
  _OrderStatusPageState createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  String statusMessage = "Waiting for agent's response..."; // Initial message
  bool isAccepted = false; // To track if the agent has accepted the request
  int countdown = 60; // 60-second cooldown timer
  late Timer _timer; // Timer for the countdown

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _listenToRequestStatus();
  }

  // Function to start the 60-second cooldown
  void _startCooldown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Function to listen to Firestore for status updates
  void _listenToRequestStatus() {
    FirebaseFirestore.instance
        .collection('fuel_requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['status'] == 'accepted') {
          setState(() {
            isAccepted = true;
            statusMessage = "Your request has been accepted!";
          });
          _timer.cancel(); // Stop the countdown if request is accepted
        } else if (data != null && data['status'] == 'declined') {
          setState(() {
            statusMessage = "Your request was declined by the agent.";
          });
          _timer.cancel(); // Stop the countdown
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order Status"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                statusMessage,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (!isAccepted) // Show countdown only if not accepted
                Text(
                  "Time remaining: $countdown seconds",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              const SizedBox(height: 40),
              if (isAccepted) // Show a confirmation button after acceptance
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Navigate back
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  child: Text(
                    "Go Back",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
