import 'package:flutter/material.dart';
import 'package:android/models/contact.dart'
    as AppContact; // Alias for your app's Contact model
import 'package:contacts_service/contacts_service.dart' as CService;
import 'package:permission_handler/permission_handler.dart';

class AddContactScreen extends StatefulWidget {
  final Function(AppContact.Contact) onAddContact;

  const AddContactScreen({super.key, required this.onAddContact});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openContactPicker() async {
    final PermissionStatus permissionStatus = await Permission.contacts
        .request();

    if (permissionStatus.isGranted) {
      try {
        final CService.Contact? contact =
            await CService.ContactsService.openDeviceContactPicker();
        if (contact != null) {
          setState(() {
            _nameController.text = contact.displayName ?? '';
            _phoneController.text = contact.phones?.isNotEmpty == true
                ? contact.phones!.first.value ?? ''
                : '';
          });
        }
      } catch (e) {
        print('Error picking contact: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking contact: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts permission denied.')),
      );
      openAppSettings(); // Option to open app settings to grant permission
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Emergency Contact')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _openContactPicker,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Select from Contacts'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final contact = AppContact.Contact(
                      name: _nameController.text,
                      phoneNumber: _phoneController.text,
                    );
                    widget.onAddContact(contact);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Save Contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
