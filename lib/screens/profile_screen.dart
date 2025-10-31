import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const ProfileScreen({super.key, this.userProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile? _userProfile;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userProfile = widget.userProfile;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      UserProfile? profile = await _authService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDefaultProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final newProfile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? (user.email ?? 'User'),
        userRole: 'wanderer',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUserProfile(newProfile);
      setState(() {
        _userProfile = newProfile;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created successfully.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No profile found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your profile to get started.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createDefaultProfile,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create Profile'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _userProfile!.photoUrl != null
                            ? NetworkImage(_userProfile!.photoUrl!)
                            : null,
                        child: _userProfile!.photoUrl == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userProfile!.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userProfile!.userRole.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_userProfile!.isVerified) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Profile details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    icon: Icons.email,
                    label: 'Email',
                    value: _userProfile!.email,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.info_outline,
                    label: 'Bio',
                    value: _userProfile!.bio ?? 'No bio yet',
                  ),
                  
                  // Walker-specific info
                  if (_userProfile!.isWalker) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.location_on,
                      label: 'Location',
                      value: _userProfile!.location ?? 'Not specified',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.speed,
                      label: 'Walking Pace',
                      value: _userProfile!.pace ?? 'Not specified',
                    ),
                    if (_userProfile!.averageRating != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.star,
                        label: 'Average Rating',
                        value: '${_userProfile!.averageRating!.toStringAsFixed(1)}/5.0',
                      ),
                    ],
                    if (_userProfile!.hourlyRate != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.attach_money,
                        label: 'Hourly Rate',
                        value: '₹${_userProfile!.hourlyRate}',
                      ),
                    ],
                  ],
                  
                  // Wanderer-specific info
                  if (_userProfile!.isWanderer) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.emergency,
                      label: 'Emergency Contact',
                      value: _userProfile!.emergencyContact ?? 'Not set',
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Edit profile button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit profile feature coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

