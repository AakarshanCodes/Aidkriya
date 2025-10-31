class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String userRole; // 'walker' or 'wanderer'
  final String? photoUrl;
  final String? bio;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Walker-specific fields
  final String? location;
  final String? pace; // 'slow', 'moderate', 'fast'
  final List<String>? interests;
  final double? hourlyRate;
  final double? averageRating;
  final int? totalWalks;
  
  // Wanderer-specific fields
  final String? emergencyContact;
  final String? emergencyPhone;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.userRole,
    this.photoUrl,
    this.bio,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
    // Walker fields
    this.location,
    this.pace,
    this.interests,
    this.hourlyRate,
    this.averageRating,
    this.totalWalks,
    // Wanderer fields
    this.emergencyContact,
    this.emergencyPhone,
  });

  // Create UserProfile from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      userRole: map['userRole'] ?? '',
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
      location: map['location'],
      pace: map['pace'],
      interests: map['interests']?.cast<String>(),
      hourlyRate: map['hourlyRate']?.toDouble(),
      averageRating: map['averageRating']?.toDouble(),
      totalWalks: map['totalWalks'],
      emergencyContact: map['emergencyContact'],
      emergencyPhone: map['emergencyPhone'],
    );
  }

  // Convert UserProfile to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'userRole': userRole,
      'photoUrl': photoUrl,
      'bio': bio,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
      'location': location,
      'pace': pace,
      'interests': interests,
      'hourlyRate': hourlyRate,
      'averageRating': averageRating,
      'totalWalks': totalWalks,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
    };
  }

  // Copy with method for easy updates
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? userRole,
    String? photoUrl,
    String? bio,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? location,
    String? pace,
    List<String>? interests,
    double? hourlyRate,
    double? averageRating,
    int? totalWalks,
    String? emergencyContact,
    String? emergencyPhone,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      userRole: userRole ?? this.userRole,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      pace: pace ?? this.pace,
      interests: interests ?? this.interests,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      averageRating: averageRating ?? this.averageRating,
      totalWalks: totalWalks ?? this.totalWalks,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
    );
  }

  bool get isWalker => userRole.toLowerCase() == 'walker';
  bool get isWanderer => userRole.toLowerCase() == 'wanderer';
}

