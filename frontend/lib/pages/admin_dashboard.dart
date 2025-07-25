import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _deleteUser(String userId, String userType) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      await _logAdminAction("Delete User", userId, "Deleted a $userType");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted successfully")));
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  Future<void> _updateFuelCost(String field, double newCost) async {
  try {
    DocumentReference fuelPricesRef = _firestore.collection('settings').doc('fuel_prices');

    // Ensure the document exists before updating
    DocumentSnapshot doc = await fuelPricesRef.get();
    if (!doc.exists) {
      await fuelPricesRef.set({}); // Create the document if it doesn't exist
    }

    await fuelPricesRef.update({
      field: newCost,
      'updatedAt': Timestamp.now(),
    });

    await _logAdminAction("Update Price", field, "Updated $field to $newCost");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$field updated successfully")),
    );
  } catch (e) {
    print("Error updating $field: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error updating $field")),
    );
  }
}

Future<void> _logAdminAction(String action, String targetId, String details) async {
  try {
    CollectionReference adminLogsRef = _firestore.collection('adminLogs');

    // Ensure the collection exists by adding a dummy log if empty
    QuerySnapshot logsSnapshot = await adminLogsRef.limit(1).get();
    if (logsSnapshot.docs.isEmpty) {
      await adminLogsRef.add({
        'adminId': "System",
        'action': "Initialize Logs",
        'targetId': "N/A",
        'details': "Admin logs collection created",
        'createdAt': Timestamp.now(),
      });
    }

    // Now add the actual log
    await adminLogsRef.add({
      'adminId': "Admin123", // Replace with actual admin ID
      'action': action,
      'targetId': targetId,
      'details': details,
      'createdAt': Timestamp.now(),
    });

    print("Admin log added successfully");
  } catch (e) {
    print("Error logging admin action: $e");
  }
}


  void _showUpdateDialog(String field, String title) {
    TextEditingController costController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update $title"),
          content: TextField(
            controller: costController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Enter new value"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () {
                double? newCost = double.tryParse(costController.text);
                if (newCost != null) {
                  _updateFuelCost(field, newCost);
                  Navigator.pop(context);
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _showUserDetails(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(userData['name'] ?? 'No Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Email: ${userData['email']}"),
              Text("Phone: ${userData['phone']}"),
              if (userData['location'] != null)
                Text("Location: ${userData['location'].latitude}, ${userData['location'].longitude}"),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
        );
      },
    );
  }
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login'); // Redirect to login screen
    } catch (e) {
      print("Error logging out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logout failed")),
      );
    }
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          const Text("Fuel Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.local_gas_station),
                  title: const Text("Update Petrol Price"),
                  onTap: () => _showUpdateDialog("petrol_price", "Petrol Price"),
                ),
                ListTile(
                  leading: const Icon(Icons.local_gas_station),
                  title: const Text("Update Diesel Price"),
                  onTap: () => _showUpdateDialog("diesel_price", "Diesel Price"),
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text("Update Delivery Price per km"),
                  onTap: () => _showUpdateDialog("delivery_price_per_km", "Delivery Price per km"),
                ),
                ListTile(
                  leading: const Icon(Icons.miscellaneous_services),
                  title: const Text("Update Service Cost"),
                  onTap: () => _showUpdateDialog("service_cost", "Service Cost"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text("Users & Agents", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.docs;
                return Column(
                  children: users.map((user) {
                    var userData = user.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage('assets/avatars/${userData['profilePhotoName'] ?? 'avatar1.png'}'),
                      ),
                      title: Text(userData['name'] ?? 'No Name'),
                      subtitle: Text("${userData['userType']} - ${userData['email']}"),
                      onTap: () => _showUserDetails(userData),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user.id, userData['userType']),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const Text("Admin Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('adminLogs').orderBy('createdAt', descending: true).limit(5).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: snapshot.data!.docs.map((log) {
                    var logData = log.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(logData['action']),
                      subtitle: Text(logData['details']),
                      trailing: Text(logData['createdAt'].toDate().toString().split('.')[0]),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}