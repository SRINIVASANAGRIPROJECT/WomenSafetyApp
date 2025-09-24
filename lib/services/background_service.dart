
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(
      onBackground: onIosBackground,
      onForeground: onStart,
      autoStart: true,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
  }

  // Update notification whenever the service receives a foreground command
  service.on('update').listen((event) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "SafeGuard Running",
        content: "Monitoring for emergencies",
      );
    }
  });

  // Function to trigger SOS actions
  Future<void> triggerSosActions() async {
    final prefs = await SharedPreferences.getInstance();
    final emergencyContact = prefs.getString('emergencyContact');

    if (emergencyContact == null || emergencyContact.isEmpty) {
      print('Emergency contact not set in background service.');
      return;
    }

    final locationStatus = await Permission.location.request();
    if (locationStatus.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final locationUrl = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';

        // Initiate call
        await launchUrl(Uri.parse('tel:$emergencyContact'));

        // Send SMS
        await launchUrl(Uri.parse('sms:$emergencyContact?body=Emergency! I need help. My location: $locationUrl'));

        print('SOS triggered from background! Location: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('Error getting location or sending SOS from background: $e');
      }
    } else {
      print('Location permission not granted for background SOS.');
    }
  }

  // Set up foreground/background listeners
  // These listeners are for the UI to send commands to the service, not for the service to set its own mode.
  // The foreground mode is primarily set during configuration and can be toggled via FlutterBackgroundService().setAsForegroundMode(true/false)

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Shake detection logic
  double shakeThreshold = 30.0; // Adjust this value as needed
  bool isShaking = false;

  accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen((AccelerometerEvent event) async {
    double currentAcceleration = (event.x * event.x + event.y * event.y + event.z * event.z);

    if (currentAcceleration > shakeThreshold && !isShaking) {
      isShaking = true;
      print('Hard shake detected!');

      // Always trigger SOS directly from background service on shake
      print('Shake detected, triggering direct SOS.');
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 3000); // Vibrate for 3 seconds
      }
      await Future.delayed(const Duration(seconds: 5)); // Give user a moment to react
      triggerSosActions();

    } else if (currentAcceleration < shakeThreshold && isShaking) {
      isShaking = false;
    }
  });
}
