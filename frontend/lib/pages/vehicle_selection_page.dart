import 'package:flutter/material.dart';
import 'vehicle_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleSelectionPage extends StatefulWidget {
  final int selectedIndex;

  const VehicleSelectionPage({Key? key, required this.selectedIndex})
      : super(key: key);

  @override
  VehicleSelectionPageState createState() => VehicleSelectionPageState();
}

class VehicleSelectionPageState extends State<VehicleSelectionPage>
    with SingleTickerProviderStateMixin {
  bool isCarSelected = false;
  late AnimationController _animationController;
  late Animation<Offset> _vehicleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _setVehicleAnimation(isCarSelected);
    _animationController.forward();
  }

  void _setVehicleAnimation(bool isCar) {
    _vehicleAnimation = Tween<Offset>(
      begin: isCar ? const Offset(2, 0) : const Offset(-2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  void _onVehicleChange(bool isCar) {
    if (isCarSelected != isCar) {
      setState(() {
        isCarSelected = isCar;
        _setVehicleAnimation(isCarSelected);
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
void _storeVehicleType() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final vehicleType = isCarSelected ? 'Car' : 'Bike';
    final vehicleId = FirebaseFirestore.instance.collection('vehicles').doc().id;

    final vehicleDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vehicles')
        .doc(vehicleId);

    await vehicleDoc.set({
      'vehicleType': vehicleType,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailsPage(
          selectedVehicle: vehicleType,
          selectedIndex: widget.selectedIndex,
          vehicleId: vehicleId, // Pass unique vehicleId
        ),
      ),
    );
  } catch (e) {
    debugPrint("Error storing vehicle type: $e");
  }
}

void _navigateToVehicleDetailsPage() async {
  final vehicleId = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('vehicles')
      .doc()
      .id; // Generate new vehicleId

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VehicleDetailsPage(
        selectedVehicle: isCarSelected ? 'Car' : 'Bike',
        selectedIndex: widget.selectedIndex,
        vehicleId: vehicleId, // Pass vehicleId
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Select Vehicle",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 180,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.cyan, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withAlpha(25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      alignment: isCarSelected
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 90,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isCarSelected ? 'Car' : 'Bike',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onVehicleChange(!isCarSelected),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(width: 180, height: 40),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              Expanded(
                child: SlideTransition(
                  position: _vehicleAnimation,
                  child: Transform.translate(
                    offset: isCarSelected
                        ? const Offset(0, 130)
                        : const Offset(-35, 80),
                    child: SizedBox(
                      width: isCarSelected
                          ? screenWidth * 1.8
                          : screenWidth * 1.2,
                      height: isCarSelected
                          ? screenWidth * 1.6
                          : screenWidth * 0.8,
                      child: Image.asset(
                        isCarSelected
                            ? 'assets/images/car.png'
                            : 'assets/images/bike.png',
                        fit: BoxFit.cover,
                        alignment: isCarSelected
                            ? Alignment.bottomLeft
                            : Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 30),
                child: GestureDetector(
                  onTap: _navigateToVehicleDetailsPage,
                  child: Container(
                    width: screenWidth * 0.7,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.cyan, Colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withAlpha(25),
                          blurRadius: 20,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
