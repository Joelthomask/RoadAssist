import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import 'offers_page.dart'; // Ensure OffersPage is imported
import 'vehicle_details_page.dart';
import 'vehicle_selection_page.dart';


class AnimatedTextWidget extends StatefulWidget {
  final ScrollController scrollController;

  const AnimatedTextWidget({Key? key, required this.scrollController})
      : super(key: key);

  @override
  _AnimatedTextWidgetState createState() => _AnimatedTextWidgetState();
}
class _AnimatedTextWidgetState extends State<AnimatedTextWidget> {
  final List<String> parts = ['Hi', 'WELCOME', 'BACK'];
  List<String> currentTexts = ['', '', ''];
  int currentPart = -1;
  bool isScrollingUp = true;
  bool isBackspacing = false;
  bool animationCompleted = false;
  Timer? animationTimer;
  Timer? backspaceTimer;
  double lastOffset = 0;

  @override
  void initState() {
    super.initState();
    startFullAnimation();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    animationTimer?.cancel();
    backspaceTimer?.cancel();
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!animationCompleted) return;

    final offset = widget.scrollController.offset;
    final goingUp = offset < lastOffset;

    if (goingUp != isScrollingUp) {
      isScrollingUp = goingUp;
      if (isScrollingUp) {
        startTypingBackPart();
      } else {
        startBackspacing();
      }
    }

    lastOffset = offset;
  }

  void startFullAnimation() {
    animationTimer?.cancel();
    backspaceTimer?.cancel();

    currentPart = -1;
    currentTexts = ['', '', ''];
    animationCompleted = false;

    animationTimer = Timer.periodic(const Duration(milliseconds: 170), (timer) {
      if (currentPart == -1) {
        setState(() {
          currentPart = 0;
        });
        return;
      }

      if (currentPart >= parts.length) {
        timer.cancel();
        animationCompleted = true;
        return;
      }

      final targetText = parts[currentPart];

      if (currentTexts[currentPart].length < targetText.length) {
        setState(() {
          currentTexts[currentPart] += targetText[currentTexts[currentPart].length];
        });
      } else {
        if (currentPart < parts.length - 1) {
          setState(() {
            currentPart++;
          });
        } else {
          timer.cancel();
          animationCompleted = true;
        }
      }
    });
  }

  void startBackspacing() {
    if (currentTexts[2].isEmpty) return;

    backspaceTimer?.cancel();
    isBackspacing = true;

    backspaceTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (currentTexts[2].isNotEmpty) {
        setState(() {
          currentTexts[2] = currentTexts[2].substring(0, currentTexts[2].length - 1);
        });
      } else {
        timer.cancel();
        isBackspacing = false;
        setState(() {
          currentPart = -1;
        });
      }
    });
  }

  void startTypingBackPart() {
    if (currentTexts[2] == parts[2]) return;

    backspaceTimer?.cancel();
    isBackspacing = false;

    animationTimer?.cancel();

    setState(() {
      if (currentPart < 2) {
        currentPart = 2;
      }
    });

    animationTimer = Timer.periodic(const Duration(milliseconds: 170), (timer) {
      final targetText = parts[2];
      if (currentTexts[2].length < targetText.length) {
        setState(() {
          currentTexts[2] += targetText[currentTexts[2].length];
        });
      } else {
        timer.cancel();
        animationCompleted = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: startFullAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "HI"
          Row(
            children: [
              Text(
                currentTexts[0],
                style: textStyle,
              ),
              if (currentPart == 0 && currentTexts[0].length < parts[0].length) // "!" only while typing "HI"
                Text(
                  '!',
                  style: textStyle.copyWith(color: Colors.red),
                ),
            ],
          ),

          // "WELCOME"
          Row(
            children: [
              Text(
                currentTexts[1],
                style: textStyle.copyWith(fontSize: 45, height: 0.9),
              ),
              if (currentPart == 1 && currentTexts[1].length < parts[1].length)
                Text(
                  '!',
                  style: textStyle.copyWith(color: Colors.red, fontSize: 45),
                ),
            ],
          ),

          // "BACK"
          Row(
            children: [
              Text(
                currentTexts[2],
                style: textStyle.copyWith(fontSize: 60, height: 0.9),
              ),
              if ((currentPart == 2 && currentTexts[2].length < parts[2].length) || isBackspacing)
                Text(
                  '!',
                  style: textStyle.copyWith(color: Colors.red, fontSize: 60),
                ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle get textStyle => const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontFamily: 'RoadRadio',
        height: 0.9, 
      );
}






class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String selectedVehicle = '';
  String profileImageName = 'avatar1.png';

  // Handle bottom navigation and page navigation
  void _onItemTapped(int index) {
    if (index == 1 || index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleSelectionPage(selectedIndex: index),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Update the profile image when changed from AccountScreen
  void _updateProfileImage(String newPhoto) {
    setState(() {
      profileImageName = newPhoto;
    });
  }

  // Widget options for bottom navigation
List<Widget> _widgetOptions() => [
  HomeScreen(
    profileImageName: profileImageName,
    onProfilePhotoChange: _updateProfileImage,
  ),
  FuelScreenEmpty(),
  ServicesScreen(),
  AccountScreen(onProfilePhotoChange: _updateProfileImage),
];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_gas_station), label: 'Fuel'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}



class FuelOrderSection extends StatefulWidget {
  @override
  _FuelOrderSectionState createState() => _FuelOrderSectionState();
}

class _FuelOrderSectionState extends State<FuelOrderSection> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  
  Widget build(BuildContext context) {
    final quantities = ['2L', '4L', '6L'];

    return SizedBox(
      height: 180, // Increased height for larger effect
      child: PageView.builder(
        controller: _pageController,
        itemCount: quantities.length,
        itemBuilder: (context, index) {
          double scale = 1.0;
          if (_pageController.position.haveDimensions) {
            double pageOffset = _pageController.page! - index;
            scale = (1 - (pageOffset.abs() * 0.3)).clamp(0.8, 1.2);
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            transform: Matrix4.identity()..scale(scale), // Popping effect
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/fuel_order',
                    arguments: quantities[index]);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Order Now -> ${quantities[index]}',
                    style: const TextStyle(
                      fontFamily: 'RoadRadio',
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
class ServiceOrderSection extends StatefulWidget {
  @override
  _ServiceOrderSectionState createState() => _ServiceOrderSectionState();
}

class _ServiceOrderSectionState extends State<ServiceOrderSection> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  
  Widget build(BuildContext context) {
    final quantities = ['Engine Breakdown', 'Punchure Fix', 'Emergency Assist'];

    return SizedBox(
      height: 180, // Increased height for larger effect
      child: PageView.builder(
        controller: _pageController,
        itemCount: quantities.length,
        itemBuilder: (context, index) {
          double scale = 1.0;
          if (_pageController.position.haveDimensions) {
            double pageOffset = _pageController.page! - index;
            scale = (1 - (pageOffset.abs() * 0.3)).clamp(0.8, 1.2);
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            transform: Matrix4.identity()..scale(scale), // Popping effect
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/service_order',
                    arguments: quantities[index]);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Fix Now -> ${quantities[index]}',
                    style: const TextStyle(
                      fontFamily: 'RoadRadio',
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
class SponsorSection extends StatefulWidget {
  @override
  _SponsorSectionState createState() => _SponsorSectionState();
}

class _SponsorSectionState extends State<SponsorSection> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  
  Widget build(BuildContext context) {
    final quantities = ['Ad#1', 'Ad#2', 'Ad#3'];

    return SizedBox(
      height: 180, // Increased height for larger effect
      child: PageView.builder(
        controller: _pageController,
        itemCount: quantities.length,
        itemBuilder: (context, index) {
          double scale = 1.0;
          if (_pageController.position.haveDimensions) {
            double pageOffset = _pageController.page! - index;
            scale = (1 - (pageOffset.abs() * 0.3)).clamp(0.8, 1.2);
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            transform: Matrix4.identity()..scale(scale), // Popping effect
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/sponsor',
                    arguments: quantities[index]);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Tap -> ${quantities[index]}',
                    style: const TextStyle(
                      fontFamily: 'RoadRadio',
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();
  final String profileImageName;
  final Function(String) onProfilePhotoChange; // Accept callback

  HomeScreen({
    super.key,
    required this.profileImageName,
    required this.onProfilePhotoChange,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "RoadAssist",
                    style: TextStyle(
                      fontFamily: 'RoadRadio',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountScreen(
                            onProfilePhotoChange: onProfilePhotoChange,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.cyan, Colors.blueAccent],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundImage:
                            AssetImage('assets/avatars/$profileImageName'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              AnimatedTextWidget(scrollController: _scrollController),
              const SizedBox(height: 20),

              // Search Bar
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/location_input');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        'Enter Current Location',
                        style: TextStyle(
                          fontFamily: 'RoadRadio',
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // "Want Better Pick-Ups?" Box
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/location_input');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/vehicle_bg.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Want Better Pick-Ups?',
                        style: TextStyle(
                          fontFamily: 'RoadRadio',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Share location ->',
                        style: TextStyle(
                          fontFamily: 'RoadRadio',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Empty Fuel',
                style: TextStyle(
                  fontFamily: 'RoadRadio',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              FuelOrderSection(),
              const SizedBox(height: 20),

              // Offers Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OffersPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "OFFERS",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                      Text(
                        "click to apply ->",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'NEEDS FIXING?',
                style: TextStyle(
                  fontFamily: 'RoadRadio',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ServiceOrderSection(),
              const SizedBox(height: 20),

              // "Emergency" Section
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/location_input');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/vehicle_bg.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'EMERGENCY?',
                        style: TextStyle(
                          fontFamily: 'RoadRadio',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Share location ->',
                        style: TextStyle(
                          fontFamily: 'RoadRadio',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Sponsored:',
                style: TextStyle(
                  fontFamily: 'RoadRadio',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              SponsorSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}





class FuelScreenEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Fuel Section (Empty)'),
    );
  }
}





class ServicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Services Screen'),
    );
  }
}

class AccountScreen extends StatefulWidget {
  final Function(String) onProfilePhotoChange;

  const AccountScreen({super.key, required this.onProfilePhotoChange});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  DocumentSnapshot? userProfile;
  String selectedPhotoName = 'avatar1.png';
  String userType = 'user'; // Default user type

  final List<String> availableAvatars = [
    'avatar1.png',
    'avatar2.png',
    'avatar3.png',
    'avatar4.png',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    user = _auth.currentUser;
    if (user != null) {
      userProfile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (userProfile?.exists ?? false) {
        final data = userProfile!.data() as Map<String, dynamic>;
        selectedPhotoName = data['profilePhotoName'] ?? 'avatar1.png';
        userType = data['userType'] ?? 'user';
      }
      widget.onProfilePhotoChange(selectedPhotoName); // Notify parent
      setState(() {});
    }
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showPhotoSelectionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: availableAvatars.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final photoName = availableAvatars[index];
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _updateProfilePhoto(photoName);
              },
              child: Image.asset('assets/avatars/$photoName'),
            );
          },
        );
      },
    );
  }

Future<void> _updateProfilePhoto(String selectedPhoto) async {
  if (user != null) {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'profilePhotoName': selectedPhoto}, SetOptions(merge: true));

      setState(() {
        selectedPhotoName = selectedPhoto;
      });
      widget.onProfilePhotoChange(selectedPhoto); // Notify parent
    } catch (e) {
      print("Error updating profile photo: $e");
    }
  }
}


void _checkAndNavigateToAdmin(BuildContext context) {
  print("User Type: $userType"); // Debug print
  if (userType == 'admin') {
    Navigator.pushNamed(context, '/AdminDashboard');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Access Denied: You are not an Admin')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage('assets/avatars/$selectedPhotoName'),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: _showPhotoSelectionDialog,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          userProfile!['email'] ?? 'No Email',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Activity'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {},
                  ),
                 if (userType == 'admin')
  GestureDetector(
    onTap: () {
      print("Admin Mode tapped"); // Debug print
      _checkAndNavigateToAdmin(context);
    },
    child: ListTile(
      leading: const Icon(Icons.admin_panel_settings),
      title: const Text('Admin Mode'),
    ),
  ),

                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
    );
  }
}
