
import 'package:flutter/material.dart';

class FakeIncomingCallScreen extends StatelessWidget {
  const FakeIncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(flex: 2),
            const Text(
              'Incoming Call',
              style: TextStyle(color: Colors.white54, fontSize: 20),
            ),
            const SizedBox(height: 10),
            const Text(
              'Mom',
              style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const Spacer(flex: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.white, size: 40),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(20),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text('Decline', style: TextStyle(color: Colors.white)),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call, color: Colors.white, size: 40),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.all(20),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text('Accept', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
