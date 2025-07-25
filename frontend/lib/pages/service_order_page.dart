import 'package:flutter/material.dart';

class ServiceOrderPage extends StatelessWidget {
    final String vehicleDetails;

  const ServiceOrderPage({Key? key, required this.vehicleDetails}) : super(key: key);
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Order'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/location_input');
          },
          child: Text('Continue to Location Input'),
        ),
      ),
    );
  }
}
