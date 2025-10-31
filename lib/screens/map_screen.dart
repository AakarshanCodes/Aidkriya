import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // This is the variable you declared
  GoogleMapController? _controller; 

  static const LatLng _defaultCenter = LatLng(28.6139, 77.2090); // New Delhi
  static const CameraPosition _initialCamera = CameraPosition(
    target: _defaultCenter,
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCamera,
        // --- THIS IS THE FIX ---
        // onMapCreated assigns the map's controller to your variable
        onMapCreated: (GoogleMapController controller) {
          setState(() {
            _controller = controller; // Now _controller is being used!
          });
          print("Map created!");
        },
        // --- END OF FIX ---
      ),
    );
  }
}
