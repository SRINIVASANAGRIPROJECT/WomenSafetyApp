
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _emergencyContactController = TextEditingController();
  String _savedContact = '';

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  Future<void> _loadEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedContact = prefs.getString('emergencyContact') ?? '';
      _emergencyContactController.text = _savedContact;
    });
  }

  Future<void> _saveEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergencyContact', _emergencyContactController.text);
    setState(() {
      _savedContact = _emergencyContactController.text;
    });
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency contact saved!')),
    );
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.phone,
      Permission.microphone,
    ].request();

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Status'),
          content: SingleChildScrollView(
            child: ListBody(
              children: statuses.entries.map((entry) {
                return Text(
                    '${entry.key.toString().split('.').last}: ${entry.value}');
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Emergency Contact Number',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emergencyContactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Phone Number',
                hintText: 'e.g., +11234567890',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveEmergencyContact,
              child: const Text('Save Contact'),
            ),
            const SizedBox(height: 30),
            const Text(
              'App Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _requestPermissions,
              child: const Text('Request All Permissions'),
            ),
          ],
        ),
      ),
    );
  }
}
