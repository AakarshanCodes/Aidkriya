import 'package:cloud_firestore/cloud_firestore.dart';
// REMOVED: import 'package:flutter_application_1/screens/live_walk_screen.dart';
import '../models/walk.dart'; // Make sure WalkStatus enum is in this file

class WalkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a walk request
  Future<Walk> createWalkRequest({
    required String wandererId,
    required String wandererName,
    required String wandererPhotoUrl,
    DateTime? scheduledTime,
    String? location,
    String? pace,
    List<String>? interests,
    String? notes,
  }) async {
    try {
      final walkId = _firestore.collection('walks').doc().id;
      final walk = Walk(
        id: walkId,
        wandererId: wandererId,
        wandererName: wandererName,
        wandererPhotoUrl: wandererPhotoUrl,
        // FIX: Use the enum, not a string
        status: WalkStatus.pending, 
        createdAt: DateTime.now(),
        scheduledTime: scheduledTime,
        location: location,
        pace: pace,
        interests: interests,
        notes: notes,
      );

      // Your Walk.toMap() model MUST convert the enum to a string
      await _firestore.collection('walks').doc(walkId).set(walk.toMap());
      return walk;
    } catch (e) {
      throw Exception('Failed to create walk request: $e');
    }
  }

  // Get available walks (for walkers)
 // Paste this entire function into lib/services/walk_service.dart

  // Get available walks (for walkers)
  Future<List<Walk>> getAvailableWalks() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('walks')
          // FIX: We have removed the .orderBy() to stop the index error
          .where('status', isEqualTo: WalkStatus.pending.name) 
          .get();

      return snapshot.docs
          .map((doc) => Walk.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get available walks: $e');
    }
  }

  // Get walks for a specific user
  Stream<List<Walk>> getWalksForUser(String userId, {required bool isWalker}) {
    Query query;
    if (isWalker) {
      query = _firestore
          .collection('walks')
          .where('walkerId', isEqualTo: userId);
    } else {
      query = _firestore
          .collection('walks')
          .where('wandererId', isEqualTo: userId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            // FIX: Added proper casting to prevent crashes
            .map((doc) => Walk.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Accept a walk (walker accepts wanderer's request)
  Future<void> acceptWalk({
    required String walkId,
    required String walkerId,
    required String walkerName,
  }) async {
    try {
      await _firestore.collection('walks').doc(walkId).update({
        // FIX: Use the enum's string name
        'status': WalkStatus.accepted.name, 
        'walkerId': walkerId,
        'walkerName': walkerName,
      });
    } catch (e) {
      throw Exception('Failed to accept walk: $e');
    }
  }

  // **FIX:** Renamed from 'startWalk' to match your live_walk_screen.dart
  // This is the correct implementation for the empty method you had.
  Future<void> updateWalkStatus(String walkId, WalkStatus newStatus) async {
    try {
      await _firestore.collection('walks').doc(walkId).update({
        'status': newStatus.name,
      });
    } catch (e) {
      throw Exception('Failed to update walk status: $e');
    }
  }

  // Complete a walk
  Future<void> completeWalk({
    required String walkId,
    required Map<String, double> endLocation,
    required int duration,
    required double cost,
    required double distance, // Added distance here
  }) async {
    try {
      final commission = cost * 0.25;

      await _firestore.collection('walks').doc(walkId).update({
        // FIX: Use the enum's string name
        'status': WalkStatus.completed.name, 
        'completedTime': DateTime.now(),
        'endLocation': endLocation,
        'duration': duration,
        'cost': cost,
        'commission': commission,
        'distance': distance, // Added distance
      });
    } catch (e) {
      throw Exception('Failed to complete walk: $e');
    }
  }

  // Cancel a walk
  Future<void> cancelWalk(String walkId, {required bool isWalker}) async {
    try {
      // FIX: Use the enum's string name
      final status = isWalker ? WalkStatus.pending.name : WalkStatus.cancelled.name;
      await _firestore.collection('walks').doc(walkId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to cancel walk: $e');
    }
  }

  // Submit rating and review
  Future<void> submitReview({
    required String walkId,
    required int rating,
    required String review,
  }) async {
    try {
      await _firestore.collection('walks').doc(walkId).update({
        'rating': rating,
        'review': review,
      });
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  // **FIX:** Renamed from 'getWalkById' to 'getWalkDetails'
  // This will fix the error in your screenshot.
  Future<Walk> getWalkDetails(String walkId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('walks').doc(walkId).get();

      if (doc.exists) {
        return Walk.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        throw Exception('Walk not found');
      }
    } catch (e) {
      throw Exception('Failed to get walk: $e');
    }
  }
}