import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseRtdbService {
  final String _databaseURL =
      'https://safegaurd-6c58d-default-rtdb.firebaseio.com/';
  late final FirebaseDatabase _database;

  FirebaseRtdbService() {
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _databaseURL,
    );
  }

  // Method to write data to the database
  Future<void> writeData(String path, Map<String, dynamic> data) async {
    try {
      await _database.ref(path).set(data);
      print('Data written successfully to $path');
    } catch (e) {
      print('Error writing data: $e');
    }
  }

  // Method to push new data to the database and get its key
  Future<String?> pushData(String path, Map<String, dynamic> data) async {
    try {
      final newRef = _database.ref(path).push();
      await newRef.set(data);
      print('Data pushed successfully to $path with key ${newRef.key}');
      return newRef.key;
    } catch (e) {
      print('Error pushing data: $e');
      return null;
    }
  }

  // Method to remove data from the database
  Future<void> removeData(String path) async {
    try {
      await _database.ref(path).remove();
      print('Data removed successfully from $path');
    } catch (e) {
      print('Error removing data: $e');
    }
  }

  // Method to read data once from the database
  Future<Map<String, dynamic>?> readDataOnce(String path) async {
    try {
      final snapshot = await _database.ref(path).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        print('No data available at $path');
        return null;
      }
    } catch (e) {
      print('Error reading data: $e');
      return null;
    }
  }

  // Method to listen for real-time updates
  Stream<DatabaseEvent> listenForUpdates(String path) {
    return _database.ref(path).onValue;
  }
}
