import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FuelTypeQuantityPage extends StatefulWidget {
  final String vehicleDetails;
  final String vehicleId;

  FuelTypeQuantityPage({
    required this.vehicleDetails,
    required this.vehicleId,
    Key? key,
  }) : super(key: key);

  @override
  _FuelTypeQuantityPageState createState() => _FuelTypeQuantityPageState();
}

class _FuelTypeQuantityPageState extends State<FuelTypeQuantityPage> {
  String? selectedFuel;
  final TextEditingController fuelAmountController = TextEditingController();

  Widget _buildParallelogramButton(String fuelType) {
    bool isSelected = selectedFuel == fuelType;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFuel = fuelType;
        });
      },
      child: Stack(
        children: [
          Transform(
            transform: Matrix4.skewX(-0.2),
            child: Container(
              height: 55,
              width: 150,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.cyan, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned.fill(
            child: Transform(
              transform: Matrix4.skewX(-0.2),
              child: Container(
                margin: const EdgeInsets.all(6),
                color: Colors.black,
                alignment: Alignment.center,
                child: Text(
                  fuelType,
                  style: TextStyle(
                    color: isSelected ? Colors.cyanAccent : Colors.grey.shade400,
                    fontSize: 22,
                    fontFamily: 'RoadRadio',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFuelDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (selectedFuel == null || fuelAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      final int quantity = double.parse(fuelAmountController.text).toInt();

      if (quantity < 1 || quantity > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuel quantity must be between 1 and 10 liters.')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(widget.vehicleId)
          .update({
        'fuelType': selectedFuel,
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushNamed(context, '/location_input', arguments: {
        'vehicleId': widget.vehicleId,
        'fuelType': selectedFuel,
        'quantity': quantity,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving fuel details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fuel Type & Quantity',
          style: TextStyle(fontFamily: 'RoadRadio'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Select Fuel Type:',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'RoadRadio',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildParallelogramButton('Diesel'),
                _buildParallelogramButton('Petrol'),
              ],
            ),
            const SizedBox(height: 40),
            TextField(
              controller: fuelAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fuel Quantity (Liters)',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(fontFamily: 'RoadRadio'),
              ),
              style: const TextStyle(fontFamily: 'RoadRadio'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.cyanAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _saveFuelDetails,
            child: const Text(
              'Order Fuel',
              style: TextStyle(
                fontFamily: 'RoadRadio',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
