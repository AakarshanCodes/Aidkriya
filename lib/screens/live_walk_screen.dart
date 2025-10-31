import 'dart:async';
import 'package:flutter/material.dart'; // <--- THIS IS THE IMPORT THAT WAS MISSING
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// --- Route Drawing Imports (Uncomment when ready) ---
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // If using dotenv for API key

import '../models/walk.dart'; // Ensure this path is correct and has the WalkStatus enum
import '../services/location_service.dart'; // Ensure this path is correct
import '../services/walk_service.dart'; // Ensure this path is correct
import '../services/payment_service.dart'; // Ensure this path is correct
import '../services/walker_location_service.dart'; // Import
import 'review_screen.dart'; // Ensure this path is correct

class LiveWalkScreen extends StatefulWidget {
  final Walk walk;
  final bool isWalker; // True if the current user is the Walker

  const LiveWalkScreen({
    super.key,
    required this.walk,
    required this.isWalker,
  });

  @override
  State<LiveWalkScreen> createState() => _LiveWalkScreenState();
}

class _LiveWalkScreenState extends State<LiveWalkScreen> {
  // --- Services ---
  final LocationService _locationService = LocationService();
  final WalkService _walkService = WalkService();
  final PaymentService _paymentService = PaymentService();
  final WalkerLocationService _walkerLocationService = WalkerLocationService(); // Service for Walker updates
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Map State ---
  final Completer<GoogleMapController> _mapControllerCompleter = Completer<GoogleMapController>();
  GoogleMapController? _mapController; // Direct access after map creation
  BitmapDescriptor? _walkerIcon;
  Set<Marker> _markers = {}; // Holds markers for Walker and Wanderer (start/end)
  // Set<Polyline> _polylines = {}; // For drawing routes (Uncomment when ready)
  // PolylinePoints _polylinePoints = PolylinePoints(); // (Uncomment when ready)

  // --- User & Walk State ---
  Position? _currentPosition; // Current user's position (Walker or Wanderer)
  Position? _otherUserPosition; // Position of the other user (fetched for Wanderer)
  StreamSubscription? _locationSubscription; // For current user's location stream
  StreamSubscription? _otherUserLocationSubscription; // For listening to the other user (Wanderer listens to Walker)

  bool _isTracking = false;
  DateTime? _walkStartTime;
  double _totalDistance = 0.0; // in meters
  Position? _lastPosition; // Used for distance calculation

  // Timer for updating walk duration
  final ValueNotifier<Duration> _durationNotifier = ValueNotifier<Duration>(Duration.zero);
  Timer? _durationTimer; // To hold the duration timer instance

  @override
  void initState() {
    super.initState();
    _loadMarkerIcon();
    _requestPermissionsAndInitLocation();
    
    // Set initial state based on walk status
    if (widget.walk.status == WalkStatus.inProgress) {
      // If walk is already in progress (e.g., user re-opened app), start tracking
      _startTracking();
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions and timers
    _locationSubscription?.cancel();
    _otherUserLocationSubscription?.cancel();
    // Stop if current user is walker. Check for null walkerId before passing.
    if (widget.isWalker && widget.walk.walkerId != null) {
      _walkerLocationService.stopSendingLocationUpdates(walkerId: widget.walk.walkerId!);
    }
    _durationTimer?.cancel();
    _mapController?.dispose();
    _durationNotifier.dispose();
    super.dispose();
  }

  // --- Initialization ---

  Future<void> _loadMarkerIcon() async {
    // Load custom icon for the Walker marker
    try {
      // Ensure you have an icon at 'assets/images/walker_icon.png'
      // and added it to pubspec.yaml assets section
      _walkerIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/images/walker_icon.png'); // Replace with your icon path
    } catch (e) {
      print("Error loading walker icon: $e");
      _walkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure); // Fallback
    }
  }

  Future<void> _requestPermissionsAndInitLocation() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      print("Location permission granted.");
      await _initializeLocation();
    } else if (status.isPermanentlyDenied) {
      print("Location permission permanently denied.");
      // Show dialog to open settings
      _showPermissionDeniedDialog();
    } else {
      print("Location permission denied.");
      // Optionally show a message explaining why location is needed
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('Location permission is permanently denied. Please enable it in app settings to use map features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings(); // From permission_handler package
              Navigator.of(context).pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeLocation() async {
    try {
      _currentPosition = await _locationService.getCurrentLocation();
      if (_currentPosition != null && mounted) {
        setState(() {}); // Update state to show map centered
        _centerMapOnPosition(_currentPosition!); // Center map initially
        print("Initial location obtained: $_currentPosition");
      }
    } catch (e) {
      print("Error getting initial location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get current location: $e')),
        );
      }
    }
  }

  // --- Walk Tracking Logic ---

  Future<void> _startTracking() async {
    // Ensure we have an initial position
    if (_currentPosition == null) {
      await _initializeLocation();
      if (_currentPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot start walk without location.')),
          );
        }
        return;
      }
    }

    try {
      // Start walk in database (only if it's not already in progress)
      if (widget.walk.status != WalkStatus.inProgress) {
        await _walkService.updateWalkStatus(widget.walk.id, WalkStatus.inProgress);
        print("Walk status updated to inProgress");
      }

      _walkStartTime = DateTime.now();
      _lastPosition = _currentPosition; // Set initial position for distance calc
      _totalDistance = 0.0; // Reset distance
      _durationNotifier.value = Duration.zero; // Reset duration

      setState(() {
        _isTracking = true;
      });

      // Start listening to MY location updates
      _startListeningToMyLocation();

      // IF I AM THE WALKER: Start sending my location to Firestore
      if (widget.isWalker) {
        _walkerLocationService.startSendingLocationUpdates(widget.walk.walkerId ?? widget.walk.wandererId); // Use appropriate ID
      }
      // IF I AM THE WANDERER: Start listening to the assigned Walker's location
      else if (widget.walk.walkerId != null) {
        _startListeningToOtherUserLocation(widget.walk.walkerId!);
      }

      // Start duration timer
      _startDurationTimer();

    } catch (e) {
      print("Error starting tracking: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting tracking: $e')),
        );
      }
    }
  }

  void _startListeningToMyLocation() {
    _locationSubscription?.cancel(); // Cancel previous subscription if any
    _locationSubscription = _locationService.getLocationUpdates(const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update more frequently during walk
    )).listen((Position position) {
      if (!mounted) return;

      // Calculate distance moved since last update
      if (_lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        _totalDistance += distance;
      }

      setState(() {
        _currentPosition = position;
        _lastPosition = position; // Update last known position
        _updateMarkers(); // Update my marker position
      });

      // Optionally keep centering the map or let user pan
      _centerMapOnPosition(position, zoom: 16.0); // Keep map centered

    }, onError: (error) {
      print("Error getting my location updates: $error");
      // Handle errors, e.g., location services disabled mid-walk
    });
  }

  // Only called by the Wanderer
  void _startListeningToOtherUserLocation(String userIdToListenTo) {
    _otherUserLocationSubscription?.cancel();
    _otherUserLocationSubscription = _firestore
        .collection('users')
        .doc(userIdToListenTo)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && mounted) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          GeoPoint? location = data['currentLocation'] as GeoPoint?;
          if (location != null) {
            setState(() {
              _otherUserPosition = Position(
                latitude: location.latitude,
                longitude: location.longitude,
                timestamp: (data['lastLocationUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0, // Fill dummy values
              );
              _updateMarkers(); // Update the other user's marker
            });
          }
        }
      }
    }, onError: (error) {
      print("Error listening to other user ($userIdToListenTo) location: $error");
    });
  }

  void _updateMarkers() {
    Set<Marker> updatedMarkers = {};

    // Marker for current user (Walker or Wanderer)
    if (_currentPosition != null) {
      updatedMarkers.add(Marker(
        markerId: MarkerId(widget.isWalker ? 'walker_me' : 'wanderer_me'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: widget.isWalker ? (_walkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure))
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: const InfoWindow(title: 'My Location'),
        anchor: const Offset(0.5, 0.5),
      ));
    }

    // Marker for the other user (only if Wanderer is viewing Walker)
    if (!widget.isWalker && _otherUserPosition != null) {
      updatedMarkers.add(Marker(
        markerId: MarkerId(widget.walk.walkerId ?? 'other_user'), // Use actual walker ID
        position: LatLng(_otherUserPosition!.latitude, _otherUserPosition!.longitude),
        icon: _walkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Walker icon
        infoWindow: InfoWindow(title: widget.walk.walkerName ?? 'Walker'),
        anchor: const Offset(0.5, 0.5),
      ));
    }

    if(mounted) {
      setState(() {
        _markers = updatedMarkers;
      });
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel(); // Cancel any existing timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted && _isTracking && _walkStartTime != null) {
        _durationNotifier.value = DateTime.now().difference(_walkStartTime!);
      } else {
        timer.cancel(); // Stop timer if not tracking or widget disposed
      }
    });
  }


  Future<void> _endWalk() async {
    if (!mounted) return;

    // Stop location updates and timer first
    _locationSubscription?.cancel();
    _otherUserLocationSubscription?.cancel();
    _durationTimer?.cancel();
    

    // If the current user is the walker, stop sending updates
    if (widget.isWalker && widget.walk.walkerId != null) {
      await _walkerLocationService.stopSendingLocationUpdates(walkerId: widget.walk.walkerId!);
    }
    
    setState(() {
        _isTracking = false;
    });

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Walk'),
        content: const Text('Are you sure you want to end this walk?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End Walk'),
          ),
        ],
      ),
    );

    // If user cancels ending, restart tracking and timers
    if (result != true) {
      // User cancelled. Restart tracking.
      setState(() { _isTracking = true; });
      _startListeningToMyLocation(); // Restart location listening
      _startDurationTimer(); // Restart timer
      if (widget.isWalker) { // Restart sending location if walker
        _walkerLocationService.startSendingLocationUpdates(widget.walk.walkerId ?? widget.walk.wandererId);
      }
      print("Walk end cancelled. Restarting tracking.");
      return;
    }

    // --- User confirmed end walk ---
    
    _durationTimer?.cancel();
    final duration = _durationNotifier.value.inMinutes; // Use final duration

    // Proceed with ending the walk if confirmed
    if (_currentPosition != null && _walkStartTime != null) {
      try {
        
        final cost = _calculateWalkCost(duration);

        await _walkService.completeWalk(
          walkId: widget.walk.id,
          endLocation: {
            "latitude": _currentPosition!.latitude,
            "longitude": _currentPosition!.longitude,
          },
          duration: duration,
          cost: cost,
          distance: _totalDistance, 
        );

        print("Walk completed in Firestore.");

        if (mounted) {
          // --- Payment Logic (Only for Wanderer) ---
          if (!widget.isWalker) {
            final commission = cost * 0.25; // Match service's 25%
            final walkerEarnings = cost - commission;

            final confirmPayment = await _paymentService.showPaymentConfirmation(
              context: context,
              wandererName: widget.walk.wandererName,
              totalCost: cost,
              commission: commission, 
              walkerEarnings: walkerEarnings,
            );

            if (confirmPayment == true) { 
              print("Processing payment...");
              bool paymentSuccess;
              try {
                await _paymentService.processPayment(
                  walkId: widget.walk.id,
                  wandererId: widget.walk.wandererId,
                  walkerId: widget.walk.walkerId ?? '', 
                  totalCost: cost,
                  paymentMethod: 'simulated_wallet',
                );
                paymentSuccess = true; 
                print("Payment successful.");
              } catch (e) {
                print("Payment failed: $e");
                paymentSuccess = false;
              }

              if (!paymentSuccess && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment failed. Please try again.'), backgroundColor: Colors.red),
                );
                return; // Stop execution here
              }
            } else {
              print("Payment cancelled by user.");
              return; // Stop execution here
            }
          }

          // --- Navigate to Review Screen (Only after successful end/payment) ---
          if (mounted) {
            print("Navigating to Review Screen...");
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ReviewScreen(
                  walk: widget.walk.copyWith( 
                    status: WalkStatus.completed, 
                    duration: duration,
                    cost: cost,
                    distance: _totalDistance,
                  ),
                  isWalker: widget.isWalker,
                ),
              ),
            );
          }
        }
      } catch (e) {
        print("Error ending walk: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error ending walk: $e')),
          );
        }
      }
    } else {
      print("Cannot end walk: Missing position or start time.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot end walk. Location or start time missing.')),
        );
      }
    }
  }


  // --- Helper Functions ---

  double _calculateWalkCost(int durationMinutes) {
    const double ratePerMinute = 5.0;
    final effectiveDuration = durationMinutes < 1 ? 1 : durationMinutes;
    return effectiveDuration * ratePerMinute;
  }

  Future<void> _centerMapOnPosition(Position position, {double zoom = 15.0}) async {
    if (!_mapControllerCompleter.isCompleted) return;
    final controller = _mapController ?? await _mapControllerCompleter.future;
    
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  // --- UI Widgets ---
  @override
  Widget build(BuildContext context) { 
    final initialLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(20.5937, 78.9629); // Default to center of India

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isWalker ? 'Walking with ${widget.walk.wandererName}' : 'Walking with ${widget.walk.walkerName ?? "Walker"}'),
        backgroundColor: Colors.teal, 
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showEmergencyOptions,
            icon: const Icon(Icons.sos),
            tooltip: 'Emergency SOS',
            color: Colors.white,
          ),
        ],
      ),
      
      body: Column(
        children: [
          // Map View
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(target: initialLatLng, zoom: 15),
              markers: _markers, 
              // polylines: _polylines, // Uncomment when ready
              myLocationEnabled: true,
              myLocationButtonEnabled: false, 
              zoomControlsEnabled: true, 
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (!_mapControllerCompleter.isCompleted) {
                  _mapControllerCompleter.complete(controller);
                }
                print("GoogleMap onMapCreated callback.");
              },
            ),
          ),

          // Walk Stats & Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius: const BorderRadius.only( 
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                )
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                ValueListenableBuilder<Duration>(
                  valueListenable: _durationNotifier,
                  builder: (context, duration, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          icon: Icons.access_time_filled, 
                          label: 'Duration',
                          value: _formatDuration(duration),
                        ),
                        _buildStatCard(
                          icon: Icons.directions_walk, 
                          label: 'Distance',
                          value: '${(_totalDistance / 1000).toStringAsFixed(2)} km',
                        ),
                        _buildStatCard(
                            icon: Icons.currency_rupee, 
                            label: 'Est. Cost',
                            value: '₹${_calculateWalkCost(duration.inMinutes).toStringAsFixed(2)}',
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16), 

                // Action buttons (Start/End)
                if (widget.isWalker) 
                  _isTracking
                      ? SizedBox( // End Button
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _endWalk,
                    icon: const Icon(Icons.stop_circle_outlined), 
                    label: const Text('End Walk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14), 
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), 
                    ),
                  ),
                )
                      : SizedBox( // Start Button
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startTracking,
                    icon: const Icon(Icons.play_circle_outline), 
                    label: const Text('Start Walking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // --- Floating Action Button for SOS ---
      floatingActionButton: FloatingActionButton(
        onPressed: _showEmergencyOptions,
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white, 
        tooltip: 'Emergency SOS',
        child: const Icon(Icons.sos), 
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, 
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize:MainAxisSize.min, 
      children: [
        Icon(icon, color: Colors.teal, size: 28), 
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17, 
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700], 
            fontSize: 11, 
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // --- Emergency Options ---
  void _showEmergencyOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded, 
              size: 48,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Emergency Alert',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet
                _triggerEmergencyAction("call");
              },
              icon: const Icon(Icons.call),
              label: const Text('Call Emergency Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet
                _triggerEmergencyAction("location");
              },
              icon: const Icon(Icons.share_location), 
              label: const Text('Share Live Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade600), 
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')
            ),
          ],
        ),
      ),
    );
  }

  void _triggerEmergencyAction(String action) {
    // TODO: Implement actual emergency actions
    print("Emergency Action Triggered: $action");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulating emergency action: $action'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}