import 'package:flutter/material.dart';
import 'package:android/screens/contacts_screen.dart';
import 'package:android/screens/fake_call_screen.dart';
import 'package:android/screens/resources_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android/screens/settings_screen.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';
import 'package:android/services/firebase_rtdb_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  final FirebaseRtdbService _firebaseRtdbService = FirebaseRtdbService();
  String _realtimeData = "No data";
  TextEditingController _dataController = TextEditingController();
  StreamSubscription? _rtdbSubscription;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    FlutterBackgroundService().on('shakeDetected').listen((event) {
      if (event != null && event['action'] == 'shakeDetected') {
        _showSosConfirmationDialog();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dataController.dispose();
    _rtdbSubscription?.cancel();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult &&
              result.recognizedWords.toLowerCase().contains('help')) {
            _speechToText.stop();
            _sendSOS();
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
      );
    }
  }

  Future<void> _sendSOS() async {
    // Retrieve emergency contact from Firebase
    String? emergencyContact;
    try {
      final snapshot = await _firebaseRtdbService.readDataOnce('emergencyContacts');
      if (snapshot != null && snapshot.isNotEmpty) {
        // Assuming you want the first contact as the primary emergency contact
        final firstContactKey = snapshot.keys.first;
        emergencyContact = snapshot[firstContactKey]['phoneNumber'];
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No emergency contacts found in Firebase.')),
        );
        return;
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error retrieving emergency contact from Firebase: $e')),
      );
      return;
    }

    if (emergencyContact == null || emergencyContact.isEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set an emergency contact in settings.'),
        ),
      );
      return;
    }

    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final locationUrl =
            'https://maps.google.com/?q=${position.latitude},${position.longitude}';

        // Update Firebase with SOS information
        final sosData = {
          'emergencyContact': emergencyContact,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        };
        await _firebaseRtdbService.writeData(
          'sosAlerts/${DateTime.now().millisecondsSinceEpoch}',
          sosData,
        );

        // Initiate call
        await launchUrl(Uri.parse('tel:$emergencyContact'));

        // Send SMS
        await launchUrl(
          Uri.parse(
            'sms:$emergencyContact?body=Emergency! I need help. My location: $locationUrl',
          ),
        );

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SOS sent and Firebase updated! Location: ${position.latitude}, ${position.longitude}',
            ),
          ),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error getting location, sending SOS or updating Firebase: $e',
            ),
          ),
        );
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required to send SOS.'),
        ),
      );
    }
  }

  void _showSosConfirmationDialog() {
    Timer? dialogTimer;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogTimer = Timer(const Duration(seconds: 10), () {
          Navigator.of(context).pop(); // Dismiss dialog
          _startListening(); // Start voice recognition
        });
        return AlertDialog(
          title: const Text('SOS Confirmation'),
          content: const Text('Are you sure you want to send an SOS alert?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                dialogTimer?.cancel();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Yes, Send SOS'),
              onPressed: () {
                dialogTimer?.cancel();
                Navigator.of(context).pop();
                _sendSOS();
              },
            ),
          ],
        );
      },
    ).then((_) {
      dialogTimer
          ?.cancel(); // Ensure timer is cancelled if dialog is dismissed manually
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  void _writeTestData() async {
    final data = {
      'message': _dataController.text,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _firebaseRtdbService.writeData('testData/messages', data);
    _dataController.clear();
  }

  void _readTestDataOnce() async {
    final data = await _firebaseRtdbService.readDataOnce('testData/messages');
    if (data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('One-time read: ${data['message']}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data for one-time read')),
      );
    }
  }

  void _startRtdbListener() {
    _rtdbSubscription = _firebaseRtdbService
        .listenForUpdates('testData/messages')
        .listen((event) {
          if (event.snapshot.exists) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            setState(() {
              _realtimeData = 'Real-time: ${data['message'] ?? 'N/A'}';
            });
          } else {
            setState(() {
              _realtimeData = 'No real-time data';
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: <Widget>[
          HomeScreenBody(
            onSosPressed: _sendSOS,
            realtimeData: _realtimeData,
            dataController: _dataController,
            writeTestData: _writeTestData,
            readTestDataOnce: _readTestDataOnce,
            startRtdbListener: _startRtdbListener,
          ),
          const ContactsScreen(),
          const FakeCallScreen(),
          const ResourcesScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Fake Call'),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Resources',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreenBody extends StatelessWidget {
  final VoidCallback onSosPressed;
  final String realtimeData;
  final TextEditingController dataController;
  final VoidCallback writeTestData;
  final VoidCallback readTestDataOnce;
  final VoidCallback startRtdbListener;

  const HomeScreenBody({
    super.key,
    required this.onSosPressed,
    required this.realtimeData,
    required this.dataController,
    required this.writeTestData,
    required this.readTestDataOnce,
    required this.startRtdbListener,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeGuard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Press the button in case of emergency',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onSosPressed,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(50),
                backgroundColor: Colors.redAccent,
                shadowColor: Colors.redAccent.withOpacity(0.5),
                elevation: 10,
              ),
              child: const Icon(Icons.sos, size: 100, color: Colors.white),
            ),
            const SizedBox(height: 40),
            Text(
              realtimeData,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: dataController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter data to write',
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: writeTestData,
                  child: const Text('Write Data'),
                ),
                ElevatedButton(
                  onPressed: readTestDataOnce,
                  child: const Text('Read Data Once'),
                ),
                ElevatedButton(
                  onPressed: startRtdbListener,
                  child: const Text('Start Realtime Listener'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
