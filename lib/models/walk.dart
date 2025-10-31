import 'package:cloud_firestore/cloud_firestore.dart';

// 
// STEP 1: The enum MUST be in this file, at the top.
// 
enum WalkStatus { pending, accepted, inProgress, completed, cancelled }

class Walk {
  final String id;
  final String wandererId;
  final String wandererName;
  final String wandererPhotoUrl;
  final String? walkerId;
  final String? walkerName;

  // 
  // STEP 2: The status MUST be type WalkStatus, NOT String.
  // 
  final WalkStatus status;
  
  final DateTime createdAt;
  final DateTime? scheduledTime;
  final DateTime? startedTime;
  final DateTime? completedTime;
  final String? location;
  
  // NOTE: Changed to Map<String, dynamic> for flexibility, can also be double
  final Map<String, dynamic>? startLocation; 
  final Map<String, dynamic>? endLocation;
  
  final String? pace;
  final List<String>? interests;
  final double? cost;
  final double? commission; // 25% of cost
  final int? duration; // in minutes

  // 
  // STEP 3: Added the missing 'distance' field
  // 
  final double? distance; // in meters

  final String? notes;
  final int? rating;
  final String? review;

  Walk({
    required this.id,
    required this.wandererId,
    required this.wandererName,
    this.wandererPhotoUrl = '',
    this.walkerId,
    this.walkerName,
    required this.status, // Now required as WalkStatus
    required this.createdAt,
    this.scheduledTime,
    this.startedTime,
    this.completedTime,
    this.location,
    this.startLocation,
    this.endLocation,
    this.pace,
    this.interests,
    this.cost,
    this.commission,
    this.duration,
    this.distance, // Added to constructor
    this.notes,
    this.rating,
    this.review,
  });

  // 
  // STEP 4: A 'fromMap' factory to create the class FROM Firestore data
  // 
  factory Walk.fromMap(Map<String, dynamic> map) {
    return Walk(
      id: map['id'] ?? '',
      wandererId: map['wandererId'] ?? '',
      wandererName: map['wandererName'] ?? '',
      wandererPhotoUrl: map['wandererPhotoUrl'] ?? '',
      walkerId: map['walkerId'],
      walkerName: map['walkerName'],

      // 
      // STEP 5: Convert the 'status' STRING from Firestore into an ENUM
      // 
      status: WalkStatus.values.byName(map['status'] ?? 'pending'),

      // Use a safe date parser
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      scheduledTime: _parseDateTime(map['scheduledTime']),
      startedTime: _parseDateTime(map['startedTime']),
      completedTime: _parseDateTime(map['completedTime']),
      
      location: map['location'],
      
      // Handle potential type mismatches from Firestore
      startLocation: map['startLocation'] != null
          ? Map<String, dynamic>.from(map['startLocation'])
          : null,
      endLocation: map['endLocation'] != null
          ? Map<String, dynamic>.from(map['endLocation'])
          : null,
          
      pace: map['pace'],
      // Use List.from for safe casting
      interests: map['interests'] != null ? List<String>.from(map['interests']) : null,
      
      // Use (num?)?.toDouble() for safe number casting
      cost: (map['cost'] as num?)?.toDouble(),
      commission: (map['commission'] as num?)?.toDouble(),
      duration: map['duration'],
      distance: (map['distance'] as num?)?.toDouble(), // Added distance
      notes: map['notes'],
      rating: map['rating'],
      review: map['review'],
    );
  }

  // 
  // STEP 6: A 'fromFirestore' factory (what your service file uses)
  // 
  factory Walk.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Walk.fromMap(data);
  }

  // 
  // STEP 7: A 'toMap' method to convert the class TO Firestore
  // 
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wandererId': wandererId,
      'wandererName': wandererName,
      'wandererPhotoUrl': wandererPhotoUrl,
      'walkerId': walkerId,
      'walkerName': walkerName,

      // 
      // STEP 8: Convert the 'status' ENUM into a STRING for Firestore
      // 
      'status': status.name,

      // Store dates as ISO8601 strings for consistency
      'createdAt': createdAt.toIso8601String(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'startedTime': startedTime?.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'location': location,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'pace': pace,
      'interests': interests,
      'cost': cost,
      'commission': commission,
      'duration': duration,
      'distance': distance, // Added distance
      'notes': notes,
      'rating': rating,
      'review': review,
    };
  }

  // 
  // STEP 9: Update 'copyWith' to use WalkStatus and include 'distance'
  // 
  Walk copyWith({
    String? id,
    String? wandererId,
    String? wandererName,
    String? wandererPhotoUrl,
    String? walkerId,
    String? walkerName,
    WalkStatus? status, // Changed from String
    DateTime? createdAt,
    DateTime? scheduledTime,
    DateTime? startedTime,
    DateTime? completedTime,
    String? location,
    Map<String, dynamic>? startLocation,
    Map<String, dynamic>? endLocation,
    String? pace,
    List<String>? interests,
    double? cost,
    double? commission,
    int? duration,
    double? distance, // Added distance
    String? notes,
    int? rating,
    String? review,
  }) {
    return Walk(
      id: id ?? this.id,
      wandererId: wandererId ?? this.wandererId,
      wandererName: wandererName ?? this.wandererName,
      wandererPhotoUrl: wandererPhotoUrl ?? this.wandererPhotoUrl,
      walkerId: walkerId ?? this.walkerId,
      walkerName: walkerName ?? this.walkerName,
      status: status ?? this.status, // Changed from String
      createdAt: createdAt ?? this.createdAt,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      startedTime: startedTime ?? this.startedTime,
      completedTime: completedTime ?? this.completedTime,
      location: location ?? this.location,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      pace: pace ?? this.pace,
      interests: interests ?? this.interests,
      cost: cost ?? this.cost,
      commission: commission ?? this.commission,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance, // Added distance
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }

  // 
  // STEP 10: REMOVED boolean getters (isRequested, etc.)
  // They were based on Strings and will no longer work.
  // Instead of `if (walk.isRequested)`, you will now use:
  // `if (walk.status == WalkStatus.pending)`
  // 
}

// 
// STEP 11: A helper function to safely parse dates from Firestore
// 
DateTime? _parseDateTime(dynamic a) {
  if (a is String) {
    return DateTime.tryParse(a); // Handles ISO8601 strings
  }
  if (a is Timestamp) {
    return a.toDate(); // Handles Firestore Timestamps
  }
  return null; // Handles null
}