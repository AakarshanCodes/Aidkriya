import 'package:flutter/material.dart';
import '../services/walk_service.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class RequestWalkScreen extends StatefulWidget {
  const RequestWalkScreen({super.key});

  @override
  State<RequestWalkScreen> createState() => _RequestWalkScreenState();
}

class _RequestWalkScreenState extends State<RequestWalkScreen> {
  final WalkService _walkService = WalkService();
  final AuthService _authService = AuthService();
  
  String _selectedOption = 'now'; // 'now' or 'schedule'
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  final _locationController = TextEditingController();
  String? _selectedPace;
  final List<String> _selectedInterests = [];
  
  bool _isLoading = false;
  UserProfile? _userProfile;

  final List<String> _paceOptions = ['slow', 'moderate', 'fast'];
  final List<String> _interestOptions = [
    'Nature walks',
    'City tours',
    'Exercise',
    'Dog walking',
    'Photography',
    'Historic sites',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile();
    setState(() => _userProfile = profile);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  DateTime? get _scheduledDateTime {
    if (_selectedDate != null && _selectedTime != null) {
      return DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }
    return null;
  }

  Future<void> _requestWalk() async {
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location')),
      );
      return;
    }

    if (_selectedOption == 'schedule' && _scheduledDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _walkService.createWalkRequest(
        wandererId: _userProfile!.uid,
        wandererName: _userProfile!.displayName,
        wandererPhotoUrl: _userProfile!.photoUrl ?? '',
        scheduledTime: _selectedOption == 'now' ? null : _scheduledDateTime,
        location: _locationController.text.trim(),
        pace: _selectedPace,
        interests: _selectedInterests.isEmpty ? null : _selectedInterests,
        notes: null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Walk request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request a Walk'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient
            Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade700,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.directions_walk,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Walk now or schedule
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildOptionButton(
                                  'now',
                                  'Walk Now',
                                  Icons.access_time,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildOptionButton(
                                  'schedule',
                                  'Schedule',
                                  Icons.calendar_today,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedOption == 'schedule') ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _selectDate,
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(
                                      _selectedDate == null
                                          ? 'Select Date'
                                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _selectTime,
                                    icon: const Icon(Icons.access_time),
                                    label: Text(
                                      _selectedTime == null
                                          ? 'Select Time'
                                          : _selectedTime!.format(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Location
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Where do you want to walk?',
                      hintText: 'e.g., Central Park, New York',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Pace selection
                  const Text(
                    'Preferred Walking Pace',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paceOptions.map((pace) {
                      return FilterChip(
                        label: Text(pace.toUpperCase()),
                        selected: _selectedPace == pace,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPace = selected ? pace : null;
                          });
                        },
                        selectedColor: Colors.blue.shade100,
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Interests
                  const Text(
                    'Interests (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interestOptions.map((interest) {
                      return FilterChip(
                        label: Text(interest),
                        selected: _selectedInterests.contains(interest),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedInterests.add(interest);
                            } else {
                              _selectedInterests.remove(interest);
                            }
                          });
                        },
                        selectedColor: Colors.deepPurple.shade100,
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _requestWalk,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Request Walk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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

  Widget _buildOptionButton(String value, String label, IconData icon, Color color) {
    final isSelected = _selectedOption == value;
    return InkWell(
      onTap: () => setState(() => _selectedOption = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

