
import 'package:flutter/material.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Resources'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const <Widget>[
          SafetyTipCard(
            title: 'Be Aware of Your Surroundings',
            tip: 'Avoid distractions like your phone or headphones. Pay attention to the people and environment around you.',
          ),
          SafetyTipCard(
            title: 'Trust Your Instincts',
            tip: 'If a situation or person feels unsafe, it probably is. Remove yourself from the situation immediately.',
          ),
          SafetyTipCard(
            title: 'Share Your Plans',
            tip: 'Let a friend or family member know where you are going and when you expect to be back.',
          ),
          SafetyTipCard(
            title: 'Walk in Well-Lit Areas',
            tip: 'Stick to populated and well-lit streets, especially at night.',
          ),
          SafetyTipCard(
            title: 'Emergency Numbers',
            tip: 'Know the local emergency numbers. In most countries, it is 112 or 911.',
          ),
        ],
      ),
    );
  }
}

class SafetyTipCard extends StatelessWidget {
  final String title;
  final String tip;

  const SafetyTipCard({super.key, required this.title, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(tip, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
