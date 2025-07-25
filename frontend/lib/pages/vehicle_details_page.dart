import 'package:flutter/material.dart';
import 'vehicle_data.dart';
import 'add_vehicle_page.dart';
import 'fuel_type_quantity_page.dart';
import 'package:frontend/pages/service_order_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleDetailsPage extends StatefulWidget {
  final String selectedVehicle;
  final int selectedIndex;
  final String vehicleId; // Add vehicleId

  const VehicleDetailsPage({
    required this.selectedVehicle,
    required this.selectedIndex,
    required this.vehicleId, // Include vehicleId
    Key? key,
  }) : super(key: key);

  @override
  _VehicleDetailsPageState createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  String? _selectedBrand;
  String? _selectedModel;
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _brandSearchController = TextEditingController();
  final TextEditingController _modelSearchController = TextEditingController();

  List<String> _filteredBrands = [];
  List<String> _filteredModels = [];
  bool _showBrandSuggestions = false;
  bool _showModelSuggestions = false;

  Map<String, List<String>> _sessionCarData = Map.from(carData);
  Map<String, List<String>> _sessionBikeData = Map.from(bikeData);

  @override
  void initState() {
    super.initState();
    _brandSearchController.addListener(() {
      _filterBrands(_brandSearchController.text);
    });
    _modelSearchController.addListener(() {
      _filterModels(_modelSearchController.text);
    });
  }

  void _filterBrands(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBrands.clear();
        _showBrandSuggestions = false;
      } else {
        final dataSource = widget.selectedVehicle == 'Car' ? _sessionCarData : _sessionBikeData;
        _filteredBrands = dataSource.keys
            .where((brand) => brand.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _showBrandSuggestions = query.isNotEmpty && _filteredBrands.isNotEmpty;
      }
    });
  }

  void _filterModels(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredModels.clear();
        _showModelSuggestions = false;
      } else if (_selectedBrand != null) {
        final dataSource = widget.selectedVehicle == 'Car' ? _sessionCarData : _sessionBikeData;
        _filteredModels = dataSource[_selectedBrand]!
            .where((model) => model.toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (_filteredModels.isEmpty) {
          _filteredModels.add("Add Vehicle");
        }

        _showModelSuggestions = query.isNotEmpty && _filteredModels.isNotEmpty;
      }
    });
  }

  void _addTemporaryModel(String brand, String model) {
    final dataSource = widget.selectedVehicle == 'Car' ? _sessionCarData : _sessionBikeData;

    if (!dataSource.containsKey(brand)) {
      dataSource[brand] = [];
    }

    if (!dataSource[brand]!.contains(model)) {
      dataSource[brand]!.add(model);
    }

    setState(() {
      _selectedBrand = brand;
      _selectedModel = model;
      _brandSearchController.text = brand;
      _modelSearchController.text = model;
      _showModelSuggestions = false;
      _showBrandSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/vehicle_details.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTextField(_brandSearchController, 'Search Brand', () {
                  setState(() {
                    _showBrandSuggestions = _brandSearchController.text.isNotEmpty;
                    _showModelSuggestions = false;
                  });
                }),
                const SizedBox(height: 20),
                _buildTextField(_modelSearchController, 'Search Model', () {
                  if (_selectedBrand != null) {
                    setState(() {
                      _filterModels('');
                      _showModelSuggestions = true;
                      _showBrandSuggestions = false;
                    });
                  }
                }),
                const SizedBox(height: 20),
                _buildTextField(_plateNumberController, 'Enter Plate Number', null),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () => _handleContinue(),


                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'RoadRadio',
                  ),
                ),
              ),
            ),
          ),
          if (_showBrandSuggestions) _buildSuggestions(_filteredBrands, (brand) {
            setState(() {
              _selectedBrand = brand;
              _brandSearchController.text = brand;
              _showBrandSuggestions = false;
              _filteredModels.clear();
              _modelSearchController.clear();
              _selectedModel = null;
            });
          }),
          if (_showModelSuggestions) _buildSuggestions(_filteredModels, (model) {
            if (model == 'Add Vehicle') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddVehiclePage(
                    onAddVehicle: _addTemporaryModel,
                  ),
                ),
              );
            } else {
              setState(() {
                _selectedModel = model;
                _modelSearchController.text = model;
                _showModelSuggestions = false;
              });
            }
          }),
        ],
      ),
    );
  }
Widget _buildTextField(TextEditingController controller, String hintText, void Function()? onTap)
{
  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.cyan, Colors.blue],
      ),
      borderRadius: BorderRadius.circular(30),
    ),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontFamily: 'RoadRadio'),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      style: const TextStyle(fontFamily: 'RoadRadio'),
     onTap: onTap,

    ),
  );
}


  Widget _buildSuggestions(List<String> suggestions, Function(String) onTap) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 120,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: suggestions
              .map((item) => ListTile(
                    title: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'RoadRadio',
                      ),
                    ),
                    onTap: () => onTap(item),
                  ))
              .toList(),
        ),
      ),
    );
  }
void _handleContinue() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User not authenticated')),
    );
    return;
  }

  if (_selectedBrand != null && _selectedModel != null && _plateNumberController.text.isNotEmpty) {
    try {
      final vehicleId = widget.vehicleId; // Use passed vehicleId

      // Determine fuelType based on vehicle selection
      final fuelType = widget.selectedVehicle == 'Car' ? 'Petrol' : 'Diesel';

      // Store vehicle data as a log
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(vehicleId)
          .set({
        'vehicleType': widget.selectedVehicle,
        'brand': _selectedBrand,
        'model': _selectedModel,
        'licensePlate': _plateNumberController.text,

        'createdAt': FieldValue.serverTimestamp(),
      });

      final vehicleDetails = '$_selectedBrand $_selectedModel (${_plateNumberController.text})';

      // Navigate based on selected index
      if (widget.selectedIndex == 1) {
Navigator.pushNamed(
  context,
  '/fueltypequantity',
  arguments: {
    'vehicleDetails': vehicleDetails,
    'vehicleId': vehicleId, // Pass vehicleId here
  },
);


      } else if (widget.selectedIndex == 2) {
        Navigator.pushNamed(context, '/service_order', arguments: {
          'vehicleDetails': vehicleDetails,
          'vehicleId': vehicleId,

        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating vehicle: $e')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all fields')),
    );
  }
}
}