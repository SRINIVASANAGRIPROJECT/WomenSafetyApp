
import 'package:flutter/material.dart';
import 'package:android/models/contact.dart';
import 'package:android/screens/add_contact_screen.dart';
import 'package:android/services/firebase_rtdb_service.dart';
import 'dart:async';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<Contact> _contacts = [];
  final FirebaseRtdbService _firebaseRtdbService = FirebaseRtdbService();
  StreamSubscription? _contactsSubscription;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _contactsSubscription?.cancel();
    super.dispose();
  }

  void _loadContacts() {
    _contactsSubscription = _firebaseRtdbService.listenForUpdates('emergencyContacts').listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final Map<dynamic, dynamic> contactsData = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _contacts.clear();
          contactsData.forEach((key, value) {
            _contacts.add(Contact(id: key, name: value['name'], phoneNumber: value['phoneNumber']));
          });
        });
      } else {
        setState(() {
          _contacts.clear();
        });
      }
    });
  }

  void _addContact(Contact contact) async {
    try {
      final contactData = {
        'name': contact.name,
        'phoneNumber': contact.phoneNumber,
      };
      await _firebaseRtdbService.pushData('emergencyContacts', contactData);
      print('Contact added to Firebase successfully');
    } catch (e) {
      print('Error adding contact to Firebase: $e');
    }
  }

  void _deleteContact(int index) async {
    final contactToDelete = _contacts[index];
    if (contactToDelete.id != null) {
      try {
        await _firebaseRtdbService.removeData('emergencyContacts/${contactToDelete.id}');
        print('Contact deleted from Firebase successfully: ${contactToDelete.id}');
      } catch (e) {
        print('Error deleting contact from Firebase: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: _contacts.isEmpty
          ? const Center(
              child: Text(
                'No contacts added yet.\nPress the + button to add your first contact.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return ListTile(
                  title: Text(contact.name),
                  subtitle: Text(contact.phoneNumber),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteContact(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddContactScreen(onAddContact: _addContact),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
