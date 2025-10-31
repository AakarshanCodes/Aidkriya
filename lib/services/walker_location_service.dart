import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class WalkerLocationService {
  StreamSubscription<Position>? _locationSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Call this when the Walker goes online/available
  Future<void> startSendingLocationUpdates(String walkerId) async {
    // Ensure permissions are handled before calling this
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // High accuracy needed for tracking
      distanceFilter: 10, // Update only if moved 10 meters
    );

    // Cancel any existing subscription 
    await stopSendingLocationUpdates();

    _locationSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      // Update Firestore with the new location
      _firestore.collection('users').doc(walkerId).update({
        'currentLocation': GeoPoint(position.latitude, position.longitude),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'isAvailable': true, // Keep marking as available while sending updates
      }).catchError((error) {
        print("Error updating Walker location: $error");
        // Consider adding more robust error handling
      });
    });
     print("Started sending location updates for Walker: $walkerId");
  }

  // Call this when the Walker goes offline or finishes a walk
  Future<void> stopSendingLocationUpdates({String? walkerId}) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null; // Clear the subscription
    print("Stopped sending location updates.");

    // Optionally update the Walker's status in Firestore when they stop
    if (walkerId != null) {
       try {
         await _firestore.collection('users').doc(walkerId).update({
           'isAvailable': false,
           'lastLocationUpdate': FieldValue.serverTimestamp(), // Mark when they went offline
         });
         print("Marked Walker $walkerId as unavailable.");
       } catch (e) {
         print("Error marking Walker unavailable: $e");
       }
    }
  }
}