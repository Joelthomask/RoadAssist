import 'package:flutter/material.dart';

class AddVehiclePage extends StatefulWidget {
  final void Function(String brand, String model) onAddVehicle;

  const AddVehiclePage({super.key, required this.onAddVehicle});

  @override
  _AddVehiclePageState createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'RoadRadio', // Set your custom font family here
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Add Vehicle'),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Brand Field
              TextField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Model Field
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: () {
                  final brand = _brandController.text.trim();
                  final model = _modelController.text.trim();

                  if (brand.isNotEmpty && model.isNotEmpty) {
                    widget.onAddVehicle(brand, model);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in both fields'),
                      ),
                    );
                  }
                },
                child: const Text('Add Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}