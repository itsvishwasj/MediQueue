import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../services/appointment_service.dart';
import '../services/socket_service.dart';
import '../models/appointment.dart';

class QueueScreen extends StatefulWidget {
  final bool isScanned;
  
  const QueueScreen({super.key, this.isScanned = false});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  // 🔹 Now using your real data model instead of a Map
  AppointmentModel? selectedAppointment;
  List<AppointmentModel> myAppointments = [];
  bool isFetching = false;
  bool isLoadingAppointments = true;

  // Theme Constants
  static const _bg = Color(0xFFF0F4FF);
  static const _primary = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  // Real Data List for the Live Queue
  List<Map<String, dynamic>> queue = [];
  int currentToken = 0; 

  @override
  void initState() {
    super.initState();
    _loadMyAppointments();
  }

  @override
  void dispose() {
    // 🔹 Clean up socket connection to save resources
    if (selectedAppointment != null) {
      SocketService.leaveQueue(selectedAppointment!.doctorId);
    }
    super.dispose();
  }

  // 🔹 API: Fetch user's actual booked appointments
  Future<void> _loadMyAppointments() async {
    try {
      final appointments = await AppointmentService.getMyAppointments();
      if (mounted) {
        setState(() {
          myAppointments = appointments.where((a) => a.status != 'completed' && a.status != 'cancelled').toList();
          isLoadingAppointments = false;
          
          if (widget.isScanned && myAppointments.isNotEmpty) {
            selectedAppointment = myAppointments.first;
            _fetchQueueAndConnectSocket();
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading appointments: $e");
      if (mounted) setState(() => isLoadingAppointments = false);
    }
  }

  // 🔹 API & SOCKETS: Fetch live queue and listen for updates
  Future<void> _fetchQueueAndConnectSocket() async {
    if (selectedAppointment == null) return;

    setState(() => isFetching = true);
    final doctorId = selectedAppointment!.doctorId;

    try {
      // 1. Fetch initial state from your dedicated doctor queue endpoint
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/queue/$doctorId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          currentToken = data['currentToken'] ?? 0;
          
          final List rawQueue = data['queue'] ?? [];
          queue = rawQueue.map((item) => {
            'name': item['patientName'] ?? 'Patient',
            'token': item['tokenNumber'] ?? 0,
          }).toList();
          
          isFetching = false;
        });

        // 2. Connect to Socket.io for this specific doctor
        SocketService.connect();
        SocketService.joinQueue(doctorId);
        
        SocketService.onQueueUpdate(doctorId, (socketData) {
          if (!mounted) return;
          
          // Listen for NEXT_PATIENT event from backend
          if (socketData['type'] == 'NEXT_PATIENT') {
            setState(() {
              currentToken = socketData['currentToken'] ?? currentToken;
              final List rawSocketQueue = socketData['queue'] ?? [];
              queue = rawSocketQueue.map((item) => {
                'name': item['patientName'] ?? 'Patient',
                'token': item['tokenNumber'] ?? 0,
              }).toList();
            });
          }
        });
      }
    } catch (e) {
      debugPrint("Queue fetch error: $e");
      if (mounted) setState(() => isFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isFetching && selectedAppointment != null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 3)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: selectedAppointment == null
            ? _buildAppointmentSelector()
            : RefreshIndicator(
                onRefresh: _fetchQueueAndConnectSocket,
                child: _buildQueueView(),
              ),
      ),
    );
  }

  // ─── UI COMPONENTS (Untouched, just mapped to real model) ──────────────

  Widget _buildAppointmentSelector() {
    return Column(
      children: [
        _buildSelectorHeader(),
        Expanded(
          child: isLoadingAppointments 
            ? const Center(child: CircularProgressIndicator())
            : myAppointments.isEmpty
                ? const Center(child: Text("No active appointments", style: TextStyle(color: _muted)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    itemCount: myAppointments.length,
                    itemBuilder: (_, i) => _buildAppointmentTile(myAppointments[i]),
                  ),
        ),
      ],
    );
  }

  Widget _buildSelectorHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Live Queue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5)),
          SizedBox(height: 2),
          Text('Select an appointment to track', style: TextStyle(fontSize: 13, color: _muted)),
        ],
      ),
    );
  }

  Widget _buildAppointmentTile(AppointmentModel apt) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedAppointment = apt);
        _fetchQueueAndConnectSocket(); 
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: _primary.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.person_rounded, color: _primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(apt.doctorName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
                  const SizedBox(height: 2),
                  Text('${apt.doctorDepartment} · ${apt.hospitalName}', style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text('Token #${apt.tokenNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueView() {
    final int yourToken = selectedAppointment!.tokenNumber;
    final int ahead = (yourToken - currentToken).clamp(0, 999);
    double progress = yourToken == 0 ? 0 : (currentToken / yourToken).clamp(0.0, 1.0);

    return ListView( 
      padding: EdgeInsets.zero,
      children: [
        _buildQueueHeader(currentToken, yourToken, ahead, progress),
        _buildQueueList(),
      ],
    );
  }

  Widget _buildQueueHeader(int current, int yours, int ahead, double progress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  SocketService.leaveQueue(selectedAppointment!.doctorId);
                  setState(() => selectedAppointment = null);
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedAppointment!.doctorName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(selectedAppointment!.hospitalName, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ],
                ),
              ),
              _LivePill(),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text('NOW SERVING', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text('#$current', style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, height: 1)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatBox(label: 'Your Token', value: '#$yours'),
              _VertDivider(),
              _StatBox(label: 'Ahead', value: '$ahead'),
              _VertDivider(),
              _StatBox(label: 'Est. Wait', value: '${ahead * selectedAppointment!.estimatedWaitTime} min'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              const Text('Queue List', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _ink)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Text('${queue.length} waiting', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted)),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: queue.length,
          itemBuilder: (_, i) {
            final person = queue[i];
            final token = person['token'] as int;
            final bool isMe = token == selectedAppointment!.tokenNumber;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isMe ? _primary.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isMe ? Border.all(color: _primary.withOpacity(0.2), width: 1.5) : null,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: isMe ? _primary : _primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text('#$token', style: TextStyle(color: isMe ? Colors.white : _primary, fontWeight: FontWeight.w800, fontSize: 13))),
                  ),
                  const SizedBox(width: 12),
                  Text(isMe ? "You" : person['name'].toString(), style: TextStyle(fontWeight: isMe ? FontWeight.w700 : FontWeight.w600, fontSize: 14, color: isMe ? _primary : _ink)),
                  const Spacer(),
                  if (isMe) const Icon(Icons.stars_rounded, color: _primary, size: 20)
                  else Text('~${(token - currentToken).clamp(0, 99) * selectedAppointment!.estimatedWaitTime} min', style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LivePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
            const SizedBox(width: 5),
            const Text('Live', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11))]));
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: Colors.white.withOpacity(0.2));
}