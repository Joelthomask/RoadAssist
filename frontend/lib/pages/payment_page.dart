import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;

  const PaymentPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  double? totalCost;
  String? selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _fetchTotalCost();
  }

  Future<void> _fetchTotalCost() async {
    final doc = await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();
    if (doc.exists) {
      setState(() {
        totalCost = (doc.data()?['totalCost'] as num?)?.toDouble() ?? 0.0;
      });
    }
  }

  void _updatePaymentMethod() {
    if (selectedPaymentMethod != null) {
      FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'paymentMethod': selectedPaymentMethod,
        'status': 'Completed', // ✅ Updates order status to "Completed"
      }).then((_) {
        _showPaymentSuccessPopup();
      });
    }
  }

  void _showPaymentSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.cyan, size: 70),
            const SizedBox(height: 10),
            const Text(
              "Payment Successful!",
              style: TextStyle(fontFamily: "RoadRadio", fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("OK", style: TextStyle(fontFamily: "RoadRadio", fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: totalCost == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Payment Method",
                    style: TextStyle(fontFamily: "RoadRadio", fontSize: 22.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20.0),

                  _buildPaymentOption("GPay"),
                  _buildPaymentOption("PhonePay"),
                  _buildPaymentOption("Card"),

                  const Spacer(),
                  Center(
                    child: Text(
                      "Total: ₹${totalCost!.toStringAsFixed(1)}",
                      style: const TextStyle(fontFamily: "RoadRadio", fontSize: 22.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  ElevatedButton(
                    onPressed: _updatePaymentMethod,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                      backgroundColor: Colors.cyan,
                    ),
                    child: const Center(
                      child: Text("Pay", style: TextStyle(fontFamily: "RoadRadio", fontSize: 18.0, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentOption(String method) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          color: Colors.white,
          border: Border.all(color: selectedPaymentMethod == method ? Colors.cyan : Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(method, style: const TextStyle(fontFamily: "RoadRadio", fontSize: 18.0)),
            if (selectedPaymentMethod == method)
              const Icon(Icons.check_circle, color: Colors.cyan, size: 24),
          ],
        ),
      ),
    );
  }
}
