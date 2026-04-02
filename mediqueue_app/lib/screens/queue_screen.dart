import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http; // Make sure this import is added
import '../config/api.dart';

class QueueScreen extends StatefulWidget {
  final bool isScanned;
  
  const QueueScreen({super.key, this.isScanned = false});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  Map<String, dynamic>? selectedAppointment;
  bool isFetching = false; // Initialized as false so selector shows immediately

  // Theme Constants
  static const _bg = Color(0xFFF0F4FF);
  static const _primary = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  final appointments = [
    {'doctor': 'Dr. Sharma', 'hospital': 'City Hospital', 'token': 7, 'department': 'Cardiology'},
    {'doctor': 'Dr. Reddy', 'hospital': 'Apollo Clinic', 'token': 3, 'department': 'General'},
  ];

  // Real Data List
  List<Map<String, dynamic>> queue = [];
  int currentToken = 0; 

  @override
  void initState() {
    super.initState();
    
    // Auto-select and fetch if the user scanned a QR
    if (widget.isScanned) {
      selectedAppointment = appointments[0];
      _fetchQueue();
    }
  }

  // ✅ MERGED LOGIC: Fetch and map backend keys to UI keys
  Future<void> _fetchQueue() async {
    if (selectedAppointment == null) return;

    setState(() => isFetching = true);

    try {
      final doctor = selectedAppointment!['doctor'];
      final hospital = selectedAppointment!['hospital'];

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/queue/$hospital/$doctor"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> rawData = jsonDecode(response.body);

        setState(() {
          // Map backend keys ('patientName', 'tokenNumber') to UI keys ('name', 'token')
          queue = rawData.map((item) {
            return {
              'name': item['patientName'] ?? 'Patient',
              'token': item['tokenNumber'] ?? 0,
            };
          }).toList();

          // Set current serving token to the first person in the list
          if (queue.isNotEmpty) {
            currentToken = queue.first['token'] ?? 0;
          }
          isFetching = false;
        });
      }
    } catch (e) {
      debugPrint("Queue fetch error: $e");
      setState(() => isFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show spinner ONLY when fetching and an appointment is active
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
                onRefresh: _fetchQueue, // Pull to refresh the queue
                child: _buildQueueView(),
              ),
      ),
    );
  }

  // ─── UI COMPONENTS (Kept from Code 1) ──────────────────────────────────

  Widget _buildAppointmentSelector() {
    return Column(
      children: [
        _buildSelectorHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: appointments.length,
            itemBuilder: (_, i) => _buildAppointmentTile(appointments[i]),
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

  Widget _buildAppointmentTile(Map<String, dynamic> apt) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedAppointment = apt);
        _fetchQueue(); // Fetch when clicked
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
                  Text(apt['doctor'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
                  const SizedBox(height: 2),
                  Text('${apt['department']} · ${apt['hospital']}', style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text('Token #${apt['token']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueView() {
    final int yourToken = selectedAppointment!['token'] as int;
    final int ahead = (yourToken - currentToken).clamp(0, 999);
    double progress = yourToken == 0 ? 0 : (currentToken / yourToken).clamp(0.0, 1.0);

    return ListView( // Changed to ListView to support RefreshIndicator
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
                onTap: () => setState(() => selectedAppointment = null),
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
                    Text(selectedAppointment!['doctor'].toString(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('${selectedAppointment!['hospital']}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
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
              _StatBox(label: 'Est. Wait', value: '${ahead * 10} min'),
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
          shrinkWrap: true, // Important since it's inside a parent ListView
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: queue.length,
          itemBuilder: (_, i) {
            final person = queue[i];
            final token = person['token'] as int;
            // logic to highlight "You" if your token matches the list item
            final bool isMe = token == selectedAppointment!['token'];

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
                  else Text('~${(token - currentToken).clamp(0, 99) * 10} min', style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Helpers (Kept from Code 1) ──────────────────────────────────────────────

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