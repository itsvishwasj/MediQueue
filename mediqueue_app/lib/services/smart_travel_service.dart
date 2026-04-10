import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class SmartTravelService {
  
  // 1. Get the patient's current live location
  static Future<Position?> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // 2. Calculate Travel Time using OSRM
  static Future<Map<String, dynamic>> getETA(double userLat, double userLon, double hospitalLat, double hospitalLon) async {
    // CRITICAL: OSRM strictly uses Longitude first, then Latitude!
    // Format: userLon,userLat;hospitalLon,hospitalLat
    final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/$userLon,$userLat;$hospitalLon,$hospitalLat?overview=false'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract distance (meters) and duration (seconds)
        double distanceMeters = data['routes'][0]['distance'];
        double durationSeconds = data['routes'][0]['duration'];

        int minutes = (durationSeconds / 60).round();
        String distanceKm = (distanceMeters / 1000).toStringAsFixed(1);

        return {
          'success': true,
          'minutes': minutes,
          'distance': distanceKm,
        };
      }
    } catch (e) {
      print("OSRM API Error: $e");
    }
    return {'success': false, 'minutes': 0, 'distance': '0'};
  }
}
