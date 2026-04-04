import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../models/appointment.dart';
import 'queue_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  static const _bg = Color(0xFFF0F4FF);
  static const _primary = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  // 🔥 API: Fetch user's actual booked appointments
  Future<void> _fetchAppointments() async {
    try {
      final data = await AppointmentService.getMyAppointments();
      if (mounted) {
        setState(() {
          // Sort so newest or currently waiting are at the top
          _appointments = data.reversed.toList(); 
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : _appointments.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _fetchAppointments,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        itemCount: _appointments.length,
                        itemBuilder: (_, i) => _AppointmentCard(appointment: _appointments[i]),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: _bg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'My Appointments',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5),
              ),
              SizedBox(height: 2),
              Text('Track your upcoming visits', style: TextStyle(fontSize: 13, color: _muted)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: const Text('Refresh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.calendar_today_outlined, color: _primary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No appointments yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _ink)),
          const SizedBox(height: 6),
          const Text('Book your first appointment to get started', style: TextStyle(fontSize: 13, color: _muted)),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentCard({required this.appointment});

  static const _primary = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final isServing = appointment.status == 'serving';
    final isCompleted = appointment.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Top row ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_rounded, color: _primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${appointment.doctorDepartment} · ${appointment.hospitalName}',
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(isServing: isServing, isCompleted: isCompleted, label: appointment.status.toUpperCase()),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────
          Divider(height: 1, color: Colors.grey.shade100),

          // ── Bottom row ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _MetaChip(icon: Icons.confirmation_number_outlined, label: 'Token #${appointment.tokenNumber}'),
                const SizedBox(width: 10),
                _MetaChip(icon: Icons.access_time_rounded, label: appointment.type == 'emergency' ? 'EMERGENCY' : 'Regular'),
                const Spacer(),
                if (!isCompleted)
                  GestureDetector(
                    onTap: () {
                      // Navigate to queue screen and auto-select this appointment
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QueueScreen(isScanned: false),
                        ),
                      );
                    },
                    child: Row(
                      children: const [
                        Text('Track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: _primary),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isServing;
  final bool isCompleted;
  final String label;
  
  const _StatusBadge({required this.isServing, required this.isCompleted, required this.label});

  @override
  Widget build(BuildContext context) {
    Color color = const Color(0xFFD97706); // Waiting (Orange)
    Color bg = const Color(0xFFFFFBEB);
    
    if (isServing) {
      color = const Color(0xFF059669); // Serving (Green)
      bg = const Color(0xFFECFDF5);
    } else if (isCompleted) {
      color = const Color(0xFF64748B); // Completed (Gray)
      bg = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}