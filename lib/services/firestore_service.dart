import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create user profile
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.uid).set(profile.toMap());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
      await _firestore.collection('users').doc(profile.uid).update(updatedProfile.toMap());
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  // Get all walkers
  Future<List<UserProfile>> getAllWalkers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userRole', isEqualTo: 'walker')
          .get();
      
      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get walkers: $e');
    }
  }

  // Get walkers by location
  Future<List<UserProfile>> getWalkersByLocation(String location) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userRole', isEqualTo: 'walker')
          .where('location', isEqualTo: location)
          .get();
      
      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get walkers by location: $e');
    }
  }

  // Get walkers by pace
  Future<List<UserProfile>> getWalkersByPace(String pace) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userRole', isEqualTo: 'walker')
          .where('pace', isEqualTo: pace)
          .get();
      
      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get walkers by pace: $e');
    }
  }

  // Stream of user profile changes
  Stream<UserProfile?> streamUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            if (data != null) {
              return UserProfile.fromMap(data);
            }
          }
          return null;
        });
  }

  // Stream of all walkers
  Stream<List<UserProfile>> streamAllWalkers() {
    return _firestore
        .collection('users')
        .where('userRole', isEqualTo: 'walker')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return UserProfile.fromMap(data);
            })
            .toList());
  }

  // Upload profile image (helper method - will be used with storage service)
  Future<String> uploadProfileImage(String uid, String imagePath) async {
    // This will be implemented with Firebase Storage
    // For now, return a placeholder
    throw UnimplementedError('Upload profile image not yet implemented');
  }
}

