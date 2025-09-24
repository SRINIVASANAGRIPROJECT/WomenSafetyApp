
import 'package:flutter/material.dart';
import 'package:android/screens/fake_incoming_call_screen.dart';

class FakeCallScreen extends StatelessWidget {
  const FakeCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fake Call'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FakeIncomingCallScreen(),
              ),
            );
          },
          child: const Text('Trigger Fake Call'),
        ),
      ),
    );
  }
}
