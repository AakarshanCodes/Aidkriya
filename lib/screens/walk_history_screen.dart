import 'package:flutter/material.dart';
import '../services/walk_service.dart';
import '../services/auth_service.dart';
import '../models/walk.dart';
import '../models/user_profile.dart';

class WalkHistoryScreen extends StatefulWidget {
  const WalkHistoryScreen({super.key});

  @override
  State<WalkHistoryScreen> createState() => _WalkHistoryScreenState();
}

class _WalkHistoryScreenState extends State<WalkHistoryScreen> {
  final WalkService _walkService = WalkService();
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  List<Walk> _allWalks = [];
  List<Walk> _filteredWalks = [];
  String _selectedFilter = 'all'; // 'all', 'completed', 'cancelled', 'in_progress'
  bool _isLoading = true;

  // Stats
  int _totalWalks = 0;
  int _completedWalks = 0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _authService.getUserProfile();
      setState(() => _userProfile = profile);

      if (profile != null) {
        final isWalker = profile.isWalker;
        
        // Get walks for this user
        final walksSnapshot = _walkService.getWalksForUser(
          profile.uid,
          isWalker: isWalker,
        );

        // Listen to the stream of walk lists
        walksSnapshot.listen((walkList) {
          if (mounted) {
            setState(() {
              _allWalks = walkList;
              _calculateStats();
              // Re-apply the filter every time the data changes
              _applyFilter(_selectedFilter, setState: false); 
            });
          }
        }, onError: (e) {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading walks: $e')),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateStats() {
    _totalWalks = _allWalks.length;
    // FIX: Changed from w.isCompleted to use the enum
    _completedWalks = _allWalks.where((w) => w.status == WalkStatus.completed).length;
    
    if (_userProfile?.isWalker ?? false) {
      _totalEarnings = _allWalks
          // FIX: Changed from w.isCompleted to use the enum
          .where((w) => w.status == WalkStatus.completed && w.cost != null)
          .fold(0.0, (sum, walk) => sum + (walk.cost! - (walk.commission ?? 0.0))); // Walker earnings
    }
  }

  // FIX: Added optional setState parameter to prevent calling it inside the stream
  void _applyFilter(String filter, {bool setState = true}) {
    List<Walk> newFilteredList;
    if (filter == 'all') {
      newFilteredList = List.from(_allWalks);
    } else {
      newFilteredList = _allWalks.where((walk) {
        switch (filter) {
          // FIX: Changed all boolean getters to use the enum
          case 'completed':
            return walk.status == WalkStatus.completed;
          case 'cancelled':
            return walk.status == WalkStatus.cancelled;
          case 'in_progress':
            return walk.status == WalkStatus.inProgress || walk.status == WalkStatus.accepted;
          default:
            return true;
        }
      }).toList();
    }

    if (setState) {
      this.setState(() {
        _selectedFilter = filter;
        _filteredWalks = newFilteredList;
      });
    } else {
      // Just update the lists without calling setState (for use inside another setState)
      _selectedFilter = filter;
      _filteredWalks = newFilteredList;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userProfile == null) { // Only show full loading on initial start
      return Scaffold(
        appBar: AppBar(
          title: const Text('Walk History'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk History'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _allWalks.isEmpty && !_isLoading
            ? Center( // "No walks" message
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No walks yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : Column( // Main content
                children: [
                  // Stats cards
                  _buildStatsCards(),
                  
                  // Filter chips
                  _buildFilterChips(),
                  
                  // Walk list
                  Expanded(
                    child: _isLoading && _allWalks.isEmpty
                        ? const Center(child: CircularProgressIndicator()) // Show loading if list is empty
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredWalks.length,
                            itemBuilder: (context, index) {
                              final walk = _filteredWalks[index];
                              return _buildWalkCard(walk);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Walks',
              _totalWalks.toString(),
              Icons.directions_walk,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Completed',
              _completedWalks.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          if (_userProfile?.isWalker ?? false) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Earnings',
                // FIX: Changed currency symbol
                '₹${_totalEarnings.toStringAsFixed(0)}',
                Icons.payments,
                Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('all', 'All', _selectedFilter == 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('completed', 'Completed', _selectedFilter == 'completed'),
          const SizedBox(width: 8),
          _buildFilterChip('in_progress', 'Active', _selectedFilter == 'in_progress'),
          const SizedBox(width: 8),
          _buildFilterChip('cancelled', 'Cancelled', _selectedFilter == 'cancelled'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, bool isSelected) {
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => _applyFilter(filter),
      selectedColor: Colors.deepPurple.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildWalkCard(Walk walk) {
    final isWalker = _userProfile?.isWalker ?? false;
    final otherUserName = isWalker ? walk.wandererName : (walk.walkerName ?? 'Unknown');
    final otherUserPhotoUrl = isWalker ? walk.wandererPhotoUrl : ''; // TODO: Add walker photo to walk model?

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Show walk details
          _showWalkDetails(walk);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: otherUserPhotoUrl.isNotEmpty
                        ? NetworkImage(otherUserPhotoUrl)
                        : null,
                    child: otherUserPhotoUrl.isEmpty
                        ? const Icon(Icons.person, size: 25)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUserName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // FIX: Pass the enum, not a string
                        _buildStatusChip(walk.status),
                      ],
                    ),
                  ),
                  // FIX: Changed from walk.isCompleted to use enum
                  if (walk.cost != null && walk.status == WalkStatus.completed)
                    Text(
                      // FIX: Changed currency symbol
                      '₹${walk.cost!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
              
              const Divider(height: 24),
              
              if (walk.location != null)
                _buildInfoRow(Icons.location_on, 'Location', walk.location!),
              
              if (walk.duration != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, 'Duration', '${walk.duration} minutes'),
              ],
              
              if (walk.completedTime != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Completed',
                  _formatDateTime(walk.completedTime!),
                ),
              ],
              
              if (walk.rating != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      '${walk.rating}/5',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              
              if (_userProfile?.isWalker ?? false) ...{
                // FIX: Changed from walk.isCompleted to use enum
                if (walk.commission != null && walk.status == WalkStatus.completed) ...[
                  const SizedBox(height: 8),
                  Text(
                    // FIX: Changed currency symbol and logic
                    'Your earnings: ₹${(walk.cost! - walk.commission!).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              }
            ],
          ),
        ),
      ),
    );
  }

  // FIX: Changed parameter from String to WalkStatus
  Widget _buildStatusChip(WalkStatus status) {
    Color color;
    IconData icon;
    String label;

    // FIX: Changed switch cases from strings to enum values
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
        // FIX: Use the label defined above
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
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showWalkDetails(Walk walk) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder( // Added shape
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false, // Allow it to be dismissed
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Walk Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // FIX: Use enum.name.toUpperCase()
                _buildDetailRow('Status', walk.status.name.toUpperCase()),
                if (walk.location != null)
                  _buildDetailRow('Location', walk.location!),
                if (walk.duration != null)
                  _buildDetailRow('Duration', '${walk.duration} minutes'),
                if (walk.cost != null)
                  // FIX: Changed currency symbol
                  _buildDetailRow('Total Cost', '₹${walk.cost!.toStringAsFixed(2)}'),
                if (walk.commission != null && _userProfile?.isWalker == true)
                  // FIX: Changed currency symbol
                  _buildDetailRow('Your Earnings', '₹${(walk.cost! - walk.commission!).toStringAsFixed(2)}'),
                
                if (walk.rating != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < walk.rating! ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      );
                    }),
                  ),
                ],
                
                if (walk.review != null && walk.review!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity, // Ensure it fills width
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(walk.review!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          // Use Expanded to allow text to wrap
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}