import 'package:flutter/material.dart';
import 'package:frontend/api_service.dart'; // Ensure this is the correct import

class TrackingPage extends StatelessWidget {
  final ApiService apiService; // Add ApiService instance

  TrackingPage({required this.apiService}); // Accept ApiService in the constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Track Your Order')),
      body: Center(
        child: Text('Tracking information will be displayed here.'),
      ),
    );
  }
}
