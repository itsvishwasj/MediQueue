import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'queue_screen.dart';
import 'book_appointment_screen.dart';
import 'dart:convert';
import '../config/api.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  // --- Controller ---
  late MobileScannerController _cameraController;

  // --- Logic State ---
  String? scannedData;
  bool scanned = false;
  bool isProcessing = false;
  String? processingMessage;
  String? errorMessage;

  // Parsed QR result
  String _qrType = 'unknown'; // 'hospital', 'doctor_cabin', 'appointment', 'unknown'
  Map<String, String> _qrParams = {};

  // Fetched details for display
  String? _hospitalName;
  String? _doctorName;
  String? _departmentName;

  // --- UI Constants ---
  static const _bg = Color(0xFFF0F4FF);
  static const _primary = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!scanned) _cameraController.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _cameraController.stop();
        break;
      default:
        break;
    }
  }

  // --- QR Code Parsing ---
  /// Parse the scanned QR data and determine its type
  void _processScannedData(String data) {
    setState(() {
      scannedData = data;
      scanned = true;
      isProcessing = true;
      processingMessage = 'Processing QR code...';
      errorMessage = null;
    });

    _cameraController.stop();

    final trimmed = data.trim();

    // Format 1: mediqueue://hospital?id=<hospitalId>
    if (trimmed.startsWith('mediqueue://hospital')) {
      _qrType = 'hospital';
      _qrParams = _parseUriParams(trimmed);
      _handleHospitalQr();
      return;
    }

    // Format 2: mediqueue://book?doctorId=<doctorId>&hospitalId=<hospitalId>
    if (trimmed.startsWith('mediqueue://book')) {
      _qrType = 'doctor_cabin';
      _qrParams = _parseUriParams(trimmed);
      _handleDoctorCabinQr();
      return;
    }

    // Format 3: Appointment QR (key=value&key=value with id/patient/token fields)
    final legacyParams = _parseLegacyParams(trimmed);
    if (legacyParams.containsKey('id') &&
        (legacyParams.containsKey('patient') || legacyParams.containsKey('token'))) {
      _qrType = 'appointment';
      _qrParams = legacyParams;
      _handleAppointmentQr();
      return;
    }

    // Unknown QR
    _qrType = 'unknown';
    setState(() {
      isProcessing = false;
      errorMessage = 'Unrecognized QR code format';
    });
  }

  Map<String, String> _parseUriParams(String data) {
    final params = <String, String>{};
    try {
      final uri = Uri.parse(data.replaceFirst('mediqueue://', 'https://mediqueue.app/'));
      params.addAll(uri.queryParameters);
    } catch (_) {
      // Fallback: manual parse
      if (data.contains('?')) {
        final query = data.split('?').last;
        for (final part in query.split('&')) {
          if (!part.contains('=')) continue;
          final idx = part.indexOf('=');
          final key = part.substring(0, idx).trim();
          final value = Uri.decodeComponent(part.substring(idx + 1).trim());
          if (key.isNotEmpty) params[key] = value;
        }
      }
    }
    return params;
  }

  Map<String, String> _parseLegacyParams(String data) {
    final params = <String, String>{};
    String normalized = data.trim();
    if (normalized.contains('?')) {
      normalized = normalized.split('?').last;
    }
    for (final part in normalized.split('&')) {
      if (!part.contains('=')) continue;
      final idx = part.indexOf('=');
      final key = part.substring(0, idx).trim().toLowerCase();
      final value = Uri.decodeComponent(part.substring(idx + 1).trim());
      if (key.isNotEmpty) params[key] = value;
    }
    return params;
  }

  // --- HOSPITAL QR FLOW ---
  /// Fetch hospital name from backend, then navigate to BookAppointmentScreen
  Future<void> _handleHospitalQr() async {
    final hospitalId = _qrParams['id'] ?? '';
    if (hospitalId.isEmpty) {
      setState(() {
        isProcessing = false;
        errorMessage = 'Invalid hospital QR code. Missing hospital ID.';
      });
      return;
    }

    setState(() => processingMessage = 'Fetching hospital info...');

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.hospitals),
      );

      if (response.statusCode == 200) {
        final List hospitals = jsonDecode(response.body);
        final hospital = hospitals.firstWhere(
          (h) => h['_id'] == hospitalId,
          orElse: () => null,
        );

        if (hospital != null && mounted) {
          _hospitalName = hospital['name'];
          setState(() {
            isProcessing = false;
            processingMessage = null;
          });

          // Auto-navigate to BookAppointmentScreen with hospital pre-selected
          _navigateToBookAppointment(_hospitalName!);
        } else {
          setState(() {
            isProcessing = false;
            errorMessage = 'Hospital not found in the system.';
          });
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
          errorMessage = 'Failed to fetch hospital info. Check your connection.';
        });
      }
    }
  }

  // --- DOCTOR CABIN QR FLOW ---
  /// When a doctor cabin QR is scanned, call the "next patient" API
  /// to automatically advance the queue (mark current as completed, next as serving)
  Future<void> _handleDoctorCabinQr() async {
    final doctorId = _qrParams['doctorId'] ?? _qrParams['doctorid'] ?? '';
    if (doctorId.isEmpty) {
      setState(() {
        isProcessing = false;
        errorMessage = 'Invalid doctor cabin QR. Missing doctor ID.';
      });
      return;
    }

    setState(() => processingMessage = 'Advancing queue...');

    try {
      // First fetch doctor details for display
      final doctorRes = await http.get(
        Uri.parse('${ApiConfig.doctors}/$doctorId'),
      );

      if (doctorRes.statusCode == 200) {
        final doctorData = jsonDecode(doctorRes.body);
        _doctorName = doctorData['name'] ?? 'Doctor';
        _departmentName = doctorData['department'] ?? '';
        final hospital = doctorData['hospital'];
        _hospitalName = hospital is Map ? hospital['name'] : '';
      }

      // Call the "next patient" API — this marks current serving as completed
      // and advances the next waiting patient to serving
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/queue/$doctorId/next'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final currentToken = data['currentToken'];
        final currentPatient = data['currentPatient'] ?? 'Patient';
        final waitingCount = data['waitingCount'] ?? 0;

        setState(() {
          isProcessing = false;
          processingMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text(
              'Queue advanced ✅ Now serving: $currentPatient (Token #$currentToken) · $waitingCount waiting',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        final body = jsonDecode(response.body);
        final message = body['message'] ?? 'Failed to advance queue';

        if (mounted) {
          setState(() {
            isProcessing = false;
            processingMessage = null;
          });

          // "No more patients" is a valid response, not an error
          if (message.contains('No more patients')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFFD97706),
                content: Text('No more patients in queue 📋'),
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            setState(() => errorMessage = message);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
          errorMessage = 'Failed to advance queue. Check your connection.';
        });
      }
    }
  }

  // --- APPOINTMENT QR FLOW (legacy) ---
  Future<void> _handleAppointmentQr() async {
    final appointmentId = _qrParams['id'] ?? '';
    if (appointmentId.isEmpty) {
      setState(() {
        isProcessing = false;
        errorMessage = 'Invalid appointment QR. Missing ID.';
      });
      return;
    }

    setState(() => processingMessage = 'Checking in patient...');

    try {
      // Use the checkin endpoint to mark patient as serving & advance queue
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/queue/checkin/$appointmentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          isProcessing = false;
          processingMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text(
              'Patient checked in ✅ Token #${data['tokenNumber']}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to queue screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QueueScreen(isScanned: true)),
        );
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          isProcessing = false;
          errorMessage = body['message'] ?? 'Failed to check in.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
          errorMessage = 'Failed to check in. Check your connection.';
        });
      }
    }
  }

  void _navigateToBookAppointment(String hospitalName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookAppointmentScreen(preSelectedHospital: hospitalName),
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      scanned = false;
      scannedData = null;
      isProcessing = false;
      processingMessage = null;
      errorMessage = null;
      _qrType = 'unknown';
      _qrParams = {};
      _hospitalName = null;
      _doctorName = null;
      _departmentName = null;
    });
    _cameraController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildScannerViewfinder(),
                    const SizedBox(height: 28),
                    if (isProcessing)
                      _buildProcessingCard()
                    else if (errorMessage != null)
                      _buildErrorCard()
                    else if (scanned && _qrType == 'doctor_cabin')
                      _buildDoctorCabinResultCard()
                    else if (scanned && _qrType == 'hospital')
                      _buildHospitalResultCard()
                    else if (scanned && _qrType == 'appointment')
                      _buildAppointmentResultCard()
                    else if (scanned && _qrType == 'unknown')
                      _buildUnknownResultCard()
                    else
                      _buildInstructions(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Scan QR Code',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Point your camera at the QR code to check in',
            style: TextStyle(fontSize: 13, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerViewfinder() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // LIVE CAMERA
            MobileScanner(
              controller: _cameraController,
              onDetect: (capture) {
                if (scanned) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? code = barcode.rawValue;
                  if (code != null && code.isNotEmpty) {
                    _processScannedData(code);
                    break; // Process only the first valid barcode
                  }
                }
              },
            ),

            // Corner brackets
            Positioned(top: 28, left: 28, child: _Corner(rotate: 0)),
            Positioned(top: 28, right: 28, child: _Corner(rotate: 1)),
            Positioned(bottom: 28, left: 28, child: _Corner(rotate: 3)),
            Positioned(bottom: 28, right: 28, child: _Corner(rotate: 2)),

            // Scan Line
            if (!scanned)
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, _primary.withOpacity(0.8), Colors.transparent],
                    ),
                  ),
                ),
              ),

            // Success Overlay
            if (scanned)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: isProcessing
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      : Icon(
                          errorMessage != null
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_rounded,
                          color: errorMessage != null ? Colors.orange : Colors.green,
                          size: 64,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(color: _primary, strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            processingMessage ?? 'Processing...',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait while we process the QR code',
            style: TextStyle(fontSize: 13, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Unknown error',
            style: const TextStyle(fontSize: 14, color: _muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _resetScanner,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Scan Again', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline_rounded, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Scan the QR code at the hospital reception or doctor\'s cabin to proceed.',
                  style: TextStyle(fontSize: 13, color: _muted, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _ScanStep(number: '1', text: 'Hospital QR → Book an appointment'),
        const SizedBox(height: 10),
        const _ScanStep(number: '2', text: 'Doctor cabin QR → Advances the queue'),
        const SizedBox(height: 10),
        const _ScanStep(number: '3', text: 'Appointment QR → Check in at reception'),
      ],
    );
  }

  // --- RESULT CARDS ---

  Widget _buildHospitalResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.local_hospital_rounded, size: 32, color: _primary),
          ),
          const SizedBox(height: 16),
          const Text('Hospital Reception', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
          const SizedBox(height: 8),
          Text(_hospitalName ?? 'Hospital', style: const TextStyle(fontSize: 16, color: _muted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Redirecting to book appointment...',
              style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => _navigateToBookAppointment(_hospitalName!),
                  child: const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _resetScanner,
                icon: const Icon(Icons.refresh_rounded, color: _muted),
                style: IconButton.styleFrom(
                  backgroundColor: _bg,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCabinResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.check_circle_rounded, size: 32, color: Color(0xFF059669)),
          ),
          const SizedBox(height: 16),
          const Text('Queue Advanced ✅', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
          const SizedBox(height: 12),
          if (_doctorName != null) ...[
            _resultRow(Icons.person_rounded, 'Doctor', _doctorName!),
            const SizedBox(height: 10),
          ],
          if (_departmentName != null && _departmentName!.isNotEmpty) ...[
            _resultRow(Icons.medical_services_rounded, 'Department', _departmentName!),
            const SizedBox(height: 10),
          ],
          if (_hospitalName != null && _hospitalName!.isNotEmpty) ...[
            _resultRow(Icons.business_rounded, 'Hospital', _hospitalName!),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Next patient is now being served',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _resetScanner,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: const Text('Scan Next Patient', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentResultCard() {
    final patient = _qrParams['patient'] ?? 'Guest';
    final doctor = _qrParams['doctor'] ?? '';
    final hospital = _qrParams['hospital'] ?? '';
    final department = _qrParams['department'] ?? '';
    final token = _qrParams['token'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Patient Checked In ✅',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink),
              ),
              const Spacer(),
              if (token.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('#$token', style: const TextStyle(color: _primary, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (patient.isNotEmpty) ...[_resultRow(Icons.person, 'Patient', patient), const SizedBox(height: 12)],
          if (doctor.isNotEmpty) ...[_resultRow(Icons.medical_services, 'Doctor', doctor), const SizedBox(height: 12)],
          if (hospital.isNotEmpty) ...[_resultRow(Icons.business_rounded, 'Hospital', hospital), const SizedBox(height: 12)],
          if (department.isNotEmpty) ...[_resultRow(Icons.local_hospital, 'Department', department), const SizedBox(height: 12)],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _resetScanner,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: const Text('Scan Again', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('Unknown QR Code', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
          const SizedBox(height: 8),
          const Text('This QR code is not recognized by MediQueue', style: TextStyle(fontSize: 14, color: _muted)),
          if (scannedData != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                scannedData!,
                style: const TextStyle(fontSize: 11, color: _muted, fontFamily: 'monospace'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _resetScanner,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Scan Again', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _muted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: _muted, fontSize: 14)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w600, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// --- Custom Components ---

class _Corner extends StatelessWidget {
  final int rotate;
  const _Corner({required this.rotate});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate * 1.5708,
      child: SizedBox(
        width: 24, height: 24,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanStep extends StatelessWidget {
  final String number, text;
  const _ScanStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
          child: Center(
            child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
      ],
    );
  }
}