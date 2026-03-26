import 'package:flutter/material.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  Map<String, dynamic>? selectedAppointment;

  static const _bg = Color(0xFFF0F4FF);
  static const _primary = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  final appointments = [
    {'doctor': 'Dr. Sharma', 'hospital': 'City Hospital', 'token': 7, 'department': 'Cardiology'},
    {'doctor': 'Dr. Reddy', 'hospital': 'Apollo Clinic', 'token': 3, 'department': 'General'},
  ];

  final queue = [
    {'token': 4, 'name': 'Rahul'},
    {'token': 5, 'name': 'Anita'},
    {'token': 6, 'name': 'Kiran'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: selectedAppointment == null
            ? _buildAppointmentSelector()
            : _buildQueueView(),
      ),
    );
  }

  // ─── SELECT APPOINTMENT ─────────────────────────────────────────────────

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
          Text(
            'Live Queue',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5),
          ),
          SizedBox(height: 2),
          Text('Select an appointment to track', style: TextStyle(fontSize: 13, color: _muted)),
        ],
      ),
    );
  }

  Widget _buildAppointmentTile(Map<String, dynamic> apt) {
    return GestureDetector(
      onTap: () => setState(() => selectedAppointment = apt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
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
                    apt['doctor'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${apt['department']} · ${apt['hospital']}',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Token #${apt['token']}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primary),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── QUEUE VIEW ─────────────────────────────────────────────────────────

  Widget _buildQueueView() {
    const int currentToken = 3;
    final int yourToken = selectedAppointment!['token'] as int;
    final int ahead = (yourToken - currentToken - 1).clamp(0, 999);

    return Column(
      children: [
        _buildQueueHeader(currentToken, yourToken, ahead),
        Expanded(child: _buildQueueList()),
      ],
    );
  }

  Widget _buildQueueHeader(int current, int yours, int ahead) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Back + title
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => selectedAppointment = null),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedAppointment!['doctor'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${selectedAppointment!['hospital']}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              _LivePill(),
            ],
          ),

          const SizedBox(height: 24),

          // Now serving token
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  'NOW SERVING',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#$current',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats row
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
              const Text(
                'Queue List',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A), letterSpacing: -0.3),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${queue.length} waiting',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: queue.length,
            itemBuilder: (_, i) {
              final person = queue[i];
              final token = person['token'] as int;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '#$token',
                          style: const TextStyle(color: _primary, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      person['name'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const Spacer(),
                    Text(
                      '~${(token - 3) * 10} min',
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

class _LivePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
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
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
          ],
        ),
      );
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: Colors.white.withOpacity(0.2),
      );
}