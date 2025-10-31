import 'package:flutter/material.dart';
import '../services/walk_service.dart';
import '../services/auth_service.dart';
import '../models/walk.dart'; // Make sure this file now contains the WalkStatus enum
import '../models/user_profile.dart';
import 'live_walk_screen.dart';

class WalkRequestsScreen extends StatefulWidget {
  const WalkRequestsScreen({super.key});

  @override
  State<WalkRequestsScreen> createState() => _WalkRequestsScreenState();
}

class _WalkRequestsScreenState extends State<WalkRequestsScreen> {
  final WalkService _walkService = WalkService();
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  List<Walk> _availableWalks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Make sure widget is still mounted
    if (!mounted) return;

    setState(() => _isLoading = true);
    final profile = await _authService.getUserProfile();
    
    if (!mounted) return;
    setState(() => _userProfile = profile);

    if (profile?.isWalker ?? false) {
      await _loadAvailableWalks(); // This will also update loading state
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // TODO: Load wanderer's walks if needed
      // For now, just stop loading
    }
  }

  Future<void> _loadAvailableWalks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final walks = await _walkService.getAvailableWalks();
      if (mounted) {
        setState(() => _availableWalks = walks);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading walks: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptWalk(Walk walk) async {
    if (_userProfile == null || !_userProfile!.isWalker) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Walk Request'),
        content: const Text('Are you sure you want to accept this walk request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    // If user cancelled, do nothing
    if (confirm != true) return;

    // User confirmed
    try {
      await _walkService.acceptWalk(
        walkId: walk.id,
        walkerId: _userProfile!.uid,
        walkerName: _userProfile!.displayName,
      );

      // **FIX:** Get the fully updated walk details from Firestore
      // This is safer than using the old 'walk' object
      final updatedWalk = await _walkService.getWalkDetails(walk.id);

      if (mounted) {
        // **FIX:** Added 'await' to navigation.
        // This means the code will *wait* until the LiveWalkScreen is closed.
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LiveWalkScreen(
              // Pass the *updated* walk object
              walk: updatedWalk,
              isWalker: true,
            ),
          ),
        );

        // **FIX:** This line now runs *after* the user comes back
        // from the LiveWalkScreen, refreshing the list.
        _loadAvailableWalks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting walk: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userProfile == null) { // Show loading only on initial load
      return Scaffold(
        appBar: AppBar(title: const Text('Available Walks')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Available Walks')),
        body: const Center(child: Text('User not found. Please log in again.')),
      );
    }

    final isWalker = _userProfile!.isWalker;

    return Scaffold(
      appBar: AppBar(
        title: Text(isWalker ? 'Available Walks' : 'My Walks'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAvailableWalks,
        child: _isLoading && _availableWalks.isEmpty
            ? const Center(child: CircularProgressIndicator()) // Loading indicator while fetching
            : _availableWalks.isEmpty
                ? Center( // "No walks" message
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isWalker ? Icons.search_off : Icons.history,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isWalker
                              ? 'No walk requests available'
                              : 'No walks yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder( // The list of walks
                    padding: const EdgeInsets.all(16),
                    itemCount: _availableWalks.length,
                    itemBuilder: (context, index) {
                      final walk = _availableWalks[index];
                      return _buildWalkCard(walk, isWalker);
                    },
                  ),
      ),
    );
  }

  Widget _buildWalkCard(Walk walk, bool isWalker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: walk.wandererPhotoUrl.isNotEmpty
                      ? NetworkImage(walk.wandererPhotoUrl)
                      : null,
                  child: walk.wandererPhotoUrl.isEmpty
                      ? const Icon(Icons.person, size: 25)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        walk.wandererName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(walk.status), // This now passes the enum
                    ],
                  ),
                ),
                // **FIX:** Corrected check to use enum `WalkStatus.pending`
                if (isWalker && walk.status == WalkStatus.pending)
                  ElevatedButton(
                    onPressed: () => _acceptWalk(walk),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
              ],
            ),
            if (walk.location != null) ...[
              const Divider(height: 24),
              _buildInfoRow(Icons.location_on, 'Location', walk.location!),
            ],
            if (walk.pace != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.speed, 'Pace', walk.pace!),
            ],
            if (walk.scheduledTime != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.access_time,
                'Scheduled',
                _formatDateTime(walk.scheduledTime!),
              ),
            ],
            if (walk.interests != null && walk.interests!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: walk.interests!.map((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: Colors.deepPurple.shade50,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // **FIX:** Changed parameter from String to WalkStatus
  Widget _buildStatusChip(WalkStatus status) {
    Color color;
    IconData icon;
    String label;

    // **FIX:** Changed switch cases from strings to enum values
    switch (status) {
      case WalkStatus.pending: // Was 'requested'
        color = Colors.orange;
        icon = Icons.access_time;
        label = 'PENDING';
        break;
      case WalkStatus.accepted:
        color = Colors.blue;
        icon = Icons.check_circle_outline;
        label = 'ACCEPTED';
        break;
      case WalkStatus.inProgress: // Was 'in_progress'
        color = Colors.green;
        icon = Icons.directions_walk;
        label = 'IN PROGRESS';
        break;
      case WalkStatus.completed:
        color = Colors.grey;
        icon = Icons.check;
        label = 'COMPLETED';
        break;
      case WalkStatus.cancelled: // Added from enum
      default: // Default now includes 'cancelled'
        color = Colors.red;
        icon = Icons.cancel;
        label = 'CANCELLED';
        break;
    }

    return Chip(
      label: Text(
        // **FIX:** Use the label defined above
        label,
        style: const TextStyle(fontSize: 12),
      ),
      avatar: Icon(icon, size: 16),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    // A more standard format
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}