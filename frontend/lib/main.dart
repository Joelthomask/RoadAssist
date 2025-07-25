import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/pages/AgentDashboard.dart';

import 'firebase_options.dart';
import 'package:frontend/api_service.dart';
import 'package:frontend/pages/welcome_page.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/login_page.dart' as login;

import 'package:frontend/pages/location_input_page.dart';
import 'package:frontend/pages/admin_dashboard.dart';
import 'package:frontend/pages/payment_page.dart';
import 'package:frontend/pages/tracking_page.dart';
import 'package:frontend/pages/forgot_password_page.dart' as forgotPassword;
import 'package:frontend/pages/reset_password_page.dart';
import 'package:frontend/pages/sign_up.dart';
import 'package:frontend/pages/vehicle_selection_page.dart';
import 'package:frontend/pages/vehicle_details_page.dart';
import 'package:frontend/pages/service_order_page.dart';
import 'package:frontend/pages/fuel_type_quantity_page.dart';
import 'package:frontend/pages/fuel_order.dart';
import 'package:frontend/pages/order_summary.dart';
Future<void> requestLocationPermission() async {
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Activate App Check
    await FirebaseAppCheck.instance.activate(
  webProvider: ReCaptchaV3Provider('your-public-key'),
  androidProvider: AndroidProvider.debug,
);

  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ApiService apiService = ApiService(baseUrl: 'http://192.168.1.3:3001'); // Replace with your backend URL or deploy it for a stable domain

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fuel Delivery App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthCheck(apiService: apiService),
      routes: {
        '/home': (context) => HomePage(),
  '/AdminDashboard': (context) => const AdminDashboard(),
        '/welcome': (context) => WelcomePage(),
        '/login': (context) => login.LoginPage(),
'/location_input': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return LocationInputPage(
    vehicleId: args['vehicleId'],
    fuelType: args['fuelType'],
    quantity: args['quantity'],
  );
},

  
'/payment': (context) => PaymentPage(
  orderId: "",  // Default value (to be replaced dynamically)

),

        '/tracking': (context) => TrackingPage(apiService: apiService),
        '/forgot_password': (context) => forgotPassword.ForgotPasswordPage(apiService: apiService),
        '/reset_password': (context) => ResetPasswordPage(apiService: apiService),
        '/sign_up': (context) => SignUpPage(),
        '/vehicleselection': (context) => VehicleSelectionPage(selectedIndex: 0),
'/fueltypequantity': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return FuelTypeQuantityPage(
    vehicleDetails: args['vehicleDetails'],
    vehicleId: args['vehicleId'],
  );
},



        '/service_order': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ServiceOrderPage(vehicleDetails: args['vehicleDetails']);
        },

    '/fuelorder': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      print("[DEBUG] Route arguments received: $args");

      return FuelOrderPage(
        latitude: args['latitude'],
        longitude: args['longitude'],
        orderId: args['orderId'], // Dynamically assign orderId
      );
    },

'/order_summary': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return OrderSummaryPage(orderId: args['orderId']);
},


'/vehicle_details': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return VehicleDetailsPage(
    selectedVehicle: args['selectedVehicle'],
    selectedIndex: args['selectedIndex'],
    vehicleId: args['vehicleId'], // ✅ Pass vehicleId here
  );
},

      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  final ApiService apiService; // Define the apiService field

  const AuthCheck({Key? key, required this.apiService}) : super(key: key);

  Future<Map<String, dynamic>?> _getUserDetails() async {
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  print('User not authenticated!');
  return null;
}


    // Fetch the user's data from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      return null;
    }

    return userDoc.data() as Map<String, dynamic>;
  }

  Future<bool> _shouldRememberUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('rememberMe') ?? false;
  }
@override
Widget build(BuildContext context) {
  print("[DEBUG] 🔄 Building main widget...");

  return FutureBuilder<Map<String, dynamic>?>(
    future: _getUserDetails(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        print("[DEBUG] ❌ Error: ${snapshot.error}");
        return Scaffold(
          body: Center(child: Text('Error: ${snapshot.error}')),
        );
      }

      final userDetails = snapshot.data;

      if (userDetails == null) {
        print("[DEBUG] ❓ UserDetails is null → Navigating to WelcomePage");
        return const WelcomePage();
      }

      final userType = userDetails['userType'] ?? 'unknown';
      final agentId = userDetails['agent_id'];
      print("[DEBUG] 🔍 User Type: $userType, Agent ID: $agentId");

      return FutureBuilder<bool>(
        future: _shouldRememberUser(),
        builder: (context, rememberSnapshot) {
          if (rememberSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rememberMe = rememberSnapshot.data ?? false;
          print("[DEBUG] 🔄 RememberMe: $rememberMe");

          if (userType == 'admin') {
            print("[DEBUG] ✅ Navigating to AdminDashboard...");
            return const AdminDashboard();
          }

          if (rememberMe && userType == 'agent' && agentId != null) {
            print("[DEBUG] 🚚 Navigating to AgentDashboard...");
            return AgentDashboard(agentId: agentId);
          } else if (userType == 'user') {
            print("[DEBUG] 🏠 Navigating to HomePage...");
            return HomePage();
          } else {
            print("[DEBUG] ❓ Navigating to WelcomePage...");
            return const WelcomePage();
          }
        },
      );
    },
  );
}
}