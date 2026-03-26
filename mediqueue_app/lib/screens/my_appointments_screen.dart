import 'package:flutter/material.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  static const _bg = Color(0xFFF0F4FF);
  static const _primary = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final data = [
      {'doctor': 'Dr. Sharma', 'hospital': 'City Hospital', 'department': 'Cardiology', 'token': '07', 'time': '10:30 AM', 'status': 'Waiting'},
      {'doctor': 'Dr. Reddy', 'hospital': 'Apollo Clinic', 'department': 'General', 'token': '03', 'time': '11:00 AM', 'status': 'Serving'},
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: data.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: data.length,
                      itemBuilder: (_, i) => _AppointmentCard(data: data[i]),
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
            child: const Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primary)),
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
  final Map<String, String> data;
  const _AppointmentCard({required this.data});

  static const _primary = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final isServing = data['status'] == 'Serving';

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
                        data['doctor'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data['department']} · ${data['hospital']}',
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(isServing: isServing, label: data['status'] ?? ''),
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
                _MetaChip(icon: Icons.confirmation_number_outlined, label: 'Token #${data['token']}'),
                const SizedBox(width: 10),
                _MetaChip(icon: Icons.access_time_rounded, label: data['time'] ?? ''),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
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
  final String label;
  const _StatusBadge({required this.isServing, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = isServing ? const Color(0xFF059669) : const Color(0xFFD97706);
    final bg = isServing ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
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