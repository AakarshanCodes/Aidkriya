import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> checkLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  Future<PermissionStatus> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status;
  }

  // Request location permissions
  Future<PermissionStatus> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check and request permission
      PermissionStatus permission = await checkLocationPermission();
      if (permission.isDenied) {
        permission = await requestLocationPermission();
      }

      if (permission.isPermanentlyDenied || permission.isDenied) {
        throw Exception('Location permission denied');
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      return position;
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  // Stream location updates
  Stream<Position> getLocationUpdates(LocationSettings locationSettings) {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: Duration(seconds: 30),
      ),
    );
  }

  // Calculate distance between two coordinates (in meters)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Get address from coordinates (optional - requires geocoding)
  // Future<String> getAddressFromCoordinates(double lat, double lon) async {
  //   // Implement with geocoding package if needed
  //   return 'Address not available';
  // }
}


