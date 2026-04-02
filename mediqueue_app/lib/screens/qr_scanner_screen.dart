import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http; // 🔥 Added for backend connectivity
import 'queue_screen.dart'; 
import 'dart:convert';
import '../config/api.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // --- Logic State ---
  String? scannedData;
  bool scanned = false;
  bool isUpdatingQueue = false;

  // --- UI Constants ---
  static const _bg = Color(0xFFF0F4FF);
  static const _primary = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

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
                    
                    // Toggle between Result Card and Instructions
                    scanned ? _buildResultCard() : _buildInstructions(),
                    
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
              letterSpacing: -0.5
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Point your camera at the QR code to check in', 
            style: TextStyle(fontSize: 13, color: _muted)
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
              onDetect: (capture) {
                if (scanned) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? code = barcode.rawValue;
                  if (code != null) {
                    setState(() {
                      scannedData = code;
                      scanned = true;
                    });
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
                child: const Center(
                  child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                ),
              ),
          ],
        ),
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
                  'Scan the QR code from your appointment confirmation to check in at the cabin.',
                  style: TextStyle(fontSize: 13, color: _muted, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _ScanStep(number: '1', text: 'Open your appointment confirmation'),
        const SizedBox(height: 10),
        const _ScanStep(number: '2', text: 'Point camera at the QR code'),
        const SizedBox(height: 10),
        const _ScanStep(number: '3', text: 'Wait for the system to verify'),
      ],
    );
  }

  Widget _buildResultCard() {
    if (scannedData == null) return const SizedBox();

    // Data Extraction Logic
    final parts = scannedData!.split('&');
    String doctor = 'Not Found';
    String hospital = 'Not Found';
    String token = '00';

    for (var part in parts) {
      if (part.startsWith('doctor=')) doctor = part.replaceFirst('doctor=', '');
      if (part.startsWith('hospital=')) hospital = part.replaceFirst('hospital=', '');
      if (part.startsWith('token=')) token = part.replaceFirst('token=', '');
    }

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
              const Text('Patient Verified ✅', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('#$token', style: const TextStyle(color: _primary, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          _resultRow(Icons.person, 'Doctor', doctor),
          const SizedBox(height: 12),
          _resultRow(Icons.business_rounded, 'Hospital', hospital),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _muted.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: isUpdatingQueue ? null : () => _handleQueueUpdate(),
                  child: isUpdatingQueue 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add to Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: isUpdatingQueue ? null : () => setState(() { scanned = false; scannedData = null; }),
                icon: const Icon(Icons.refresh_rounded, color: _muted),
                style: IconButton.styleFrom(
                  backgroundColor: _bg,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- 🔥 UPDATED ASYNC LOGIC WITH REAL HTTP POST ---
  void _handleQueueUpdate() async {
    setState(() => isUpdatingQueue = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updating Queue...'), duration: Duration(milliseconds: 800)),
    );

    // Re-parse data for the request
    final parts = scannedData!.split('&');
    String doctor = '';
    String hospital = '';
    String token = '';

    for (var part in parts) {
      if (part.startsWith('doctor=')) doctor = part.replaceFirst('doctor=', '');
      if (part.startsWith('hospital=')) hospital = part.replaceFirst('hospital=', '');
      if (part.startsWith('token=')) token = part.replaceFirst('token=', '');
    }

    try {
      // 🚀 REAL API CALL TO YOUR BACKEND
      final response = await http.post(
        Uri.parse(ApiConfig.queue), // Replace with your server URL
       body: jsonEncode({
  'doctor': doctor,
  'hospital': hospital,
  'token': token,
}),
headers: {
  'Content-Type': 'application/json',
},
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Patient Added to Queue ✅')),
        );

        // Navigate to the Queue Screen
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => const QueueScreen(isScanned: true))
        );
      } else {
        throw Exception('Failed to update queue');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text('Failed to update queue ❌')),
        );
      }
    } finally {
      if (mounted) setState(() => isUpdatingQueue = false);
    }
  }

  Widget _resultRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _muted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: _muted, fontSize: 14)),
        Text(value, style: const TextStyle(color: _ink, fontWeight: FontWeight.w600, fontSize: 14)),
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