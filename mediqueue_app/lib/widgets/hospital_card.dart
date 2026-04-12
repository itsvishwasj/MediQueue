import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/smart_travel_service.dart';

class HospitalCard extends StatefulWidget {
  final String hospitalName;
  final double hospitalLat; // Passed down from your MongoDB backend
  final double hospitalLon; 
  final int currentQueueWait; // e.g., 45 minutes
  final VoidCallback onTap;

  const HospitalCard({
    super.key, 
    required this.hospitalName, 
    required this.hospitalLat, 
    required this.hospitalLon, 
    required this.currentQueueWait,
    required this.onTap,
  });

  @override
  State<HospitalCard> createState() => _HospitalCardState();
}

class _HospitalCardState extends State<HospitalCard> {
  String travelInfo = "Calculating ETA...";
  String departureAlert = "";

  @override
  void initState() {
    super.initState();
    _calculateSmartTravel();
  }

  @override
  void didUpdateWidget(covariant HospitalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate ETA and alerts if the parent feeds us a newly fetched queue wait value!
    if (oldWidget.currentQueueWait != widget.currentQueueWait) {
      _calculateSmartTravel();
    }
  }

  Future<void> _calculateSmartTravel() async {
    if (widget.hospitalLat == 0.0 && widget.hospitalLon == 0.0) {
      if (mounted) {
        setState(() => travelInfo = "Location not available");
      }
      return;
    }

    // 1. Get User Location
    Position? userPos = await SmartTravelService.getUserLocation();
    if (userPos == null) {
      if (mounted) {
        setState(() => travelInfo = "Location access denied");
      }
      return;
    }

    // 2. Get ETA from OSRM
    final routingData = await SmartTravelService.getETA(
      userPos.latitude, userPos.longitude, 
      widget.hospitalLat, widget.hospitalLon
    );

    if (mounted && routingData['success']) {
      int travelMins = routingData['minutes'];
      String distance = routingData['distance'];
      
      // 3. The "Smart" Logic: Compare travel time to queue wait time
      int bufferTime = widget.currentQueueWait - travelMins;
      String alertMsg;
      
      if (widget.currentQueueWait <= 0) {
        alertMsg = "Select a doctor to calculate when to leave";
      } else if (bufferTime <= 5) {
        alertMsg = "🚨 Leave NOW to reach on time!";
      } else {
        alertMsg = "✅ Leave in $bufferTime mins";
      }

      setState(() {
        travelInfo = "🚗 $distance km • $travelMins mins drive";
        departureAlert = alertMsg;
      });
    } else if (mounted) {
      setState(() {
        travelInfo = "Failed to calculate ETA";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF2563EB).withOpacity(0.1)),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_hospital_rounded, color: Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.hospitalName, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                   const Icon(Icons.access_time_rounded, size: 16, color: Colors.orange),
                   const SizedBox(width: 6),
                    Text(
                    widget.currentQueueWait > 0 ? "Wait Time: ${widget.currentQueueWait} mins" : "Wait Time: Calculating...", 
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13)
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFE8ECFF)),
              // Display the dynamically calculated travel data
              Row(
                children: [
                  Expanded(
                    child: Text(travelInfo, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ),
                ],
              ),
              if (departureAlert.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(departureAlert, style: const TextStyle(color: Color(0xFF00C97A), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
