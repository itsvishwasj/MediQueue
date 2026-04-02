import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─── CONSTANTS ──────────────────────────────────────────────────────────────
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF00C97A);
const _bg = Color(0xFFF0F4FF);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _surface = Colors.white;
const _border = Color(0xFFE8ECFF);

// ─── TOKEN SCREEN ────────────────────────────────────────────────────────────
class TokenScreen extends StatelessWidget {
  final String doctor;
  final String hospital;
  final String department;
  final int token;
  final String? scheduledTime;

  const TokenScreen({
    super.key,
    required this.doctor,
    required this.hospital,
    required this.department,
    required this.token,
    this.scheduledTime,
  });

  @override
  Widget build(BuildContext context) {
    final isScheduled = scheduledTime != null;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 🔥 HEADER CARD (Token Display) — Old UI style
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, Color(0xFF6A8DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      isScheduled ? '📅 Scheduled' : '⚡ Walk-in',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'YOUR TOKEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      '#$token',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 68,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    if (isScheduled)
                      Text(
                        scheduledTime!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🔥 DETAILS CARD — Old UI style
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _row('Doctor', doctor, Icons.person_outline_rounded),
                    const Divider(height: 28, color: Color(0xFFF1F5F9)),
                    _row('Hospital', hospital, Icons.local_hospital_outlined),
                    const Divider(height: 28, color: Color(0xFFF1F5F9)),
                    _row('Department', department, Icons.medical_services_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🔥 QR CODE BOX — Old UI style
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 140, color: _ink),
                      const SizedBox(height: 16),
                      const Text(
                        'SCAN AT RECEPTION',
                        style: TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Data: doctor=$doctor&token=$token',
                        style: TextStyle(color: _muted.withOpacity(0.4), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🔥 DONE BUTTON
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primary),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink),
        ),
      ],
    );
  }
}

// ─── BOOK APPOINTMENT SCREEN ─────────────────────────────────────────────────
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen>
    with SingleTickerProviderStateMixin {
  String? hospital;
  String? department;
  String? doctor;
  bool isBooking = false;
  bool _isScheduled = false;
  String? _selectedSlot;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchMode(bool scheduled) {
    _animController.reverse().then((_) {
      setState(() {
        _isScheduled = scheduled;
        _selectedSlot = null;
      });
      _animController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // 🔥 INFO BANNER — Old UI style
                  _buildInfoCard(),
                  const SizedBox(height: 24),

                  _label('Select Hospital'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    'Hospital', hospital,
                    ['City Hospital', 'Apollo'],
                    Icons.local_hospital_outlined,
                    (v) => setState(() => hospital = v),
                  ),
                  const SizedBox(height: 18),

                  _label('Select Department'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    'Department', department,
                    ['General', 'Cardiology'],
                    Icons.medical_services_outlined,
                    (v) => setState(() => department = v),
                  ),
                  const SizedBox(height: 18),

                  _label('Select Doctor'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    'Doctor', doctor,
                    ['Dr. Sharma', 'Dr. Reddy'],
                    Icons.person_outlined,
                    (v) => setState(() => doctor = v),
                  ),

                  if (doctor != null) ...[
                    const SizedBox(height: 28),
                    _buildModeToggle(),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: _isScheduled ? _buildScheduleSection() : _buildWalkInView(),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    _buildPlaceholder(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 TOP BAR — Old UI style (with subtitle)
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Book Appointment',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Reserve your consultation slot instantly',
            style: TextStyle(fontSize: 13, color: _muted),
          ),
        ],
      ),
    );
  }

  // 🔥 INFO BANNER — Old UI style
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primary.withOpacity(0.1)),
      ),
      child: Row(
        children: const [
          Icon(Icons.bolt_rounded, color: _primary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your digital token will be generated immediately after confirmation.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF1D4ED8), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _ink),
      );

  // 🔥 DROPDOWN — Old UI style (highlighted border when selected, shadow)
  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    IconData icon,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value != null ? _primary.withOpacity(0.3) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          'Choose $label',
          style: const TextStyle(fontSize: 14, color: _muted),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: value != null ? _primary : _muted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        icon: const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.expand_more_rounded, color: _muted),
        ),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ))
            .toList(),
        onChanged: isBooking ? null : onChanged,
      ),
    );
  }

  // 🔥 MODE TOGGLE — New UI
  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _toggleOption(label: '⚡  Join Now', selected: !_isScheduled, onTap: () => _switchMode(false)),
          _toggleOption(label: '📅  Schedule Slot', selected: _isScheduled, onTap: () => _switchMode(true)),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? _surface : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? _primary : _muted,
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 WALK-IN VIEW — New UI
  Widget _buildWalkInView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'LIVE STATUS',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.circle, color: _success, size: 8),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('8', 'Waiting'),
                  _statItem('~45', 'Mins'),
                  _statItem('#12', 'Serving'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildConfirmButton('Get Instant Token', Icons.bolt_rounded, _handleBookingFlow),
      ],
    );
  }

  // 🔥 SCHEDULE SECTION — New UI
  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Slots',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _ink),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['09:00 AM', '10:30 AM', '11:00 AM', '05:00 PM'].map((time) {
            final isSel = _selectedSlot == time;
            return GestureDetector(
              onTap: () => setState(() => _selectedSlot = time),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSel ? _primary : _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSel ? _primary : _border),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: isSel ? Colors.white : _ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        _buildConfirmButton(
          'Confirm Booking',
          Icons.calendar_today_rounded,
          _selectedSlot != null ? _handleBookingFlow : null,
        ),
      ],
    );
  }

  Widget _statItem(String val, String label) {
    return Column(children: [
      Text(val,
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]);
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Text('Select a doctor to continue', style: TextStyle(color: _muted)),
    );
  }

  // 🔥 CONFIRM BUTTON — Old UI style (animated color + shadow)
  Widget _buildConfirmButton(String label, IconData icon, VoidCallback? onTap) {
    final bool isReady = onTap != null && !isBooking;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 58,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isReady ? _primary : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(18),
        boxShadow: isReady
            ? [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isReady ? onTap : null,
          child: Center(
            child: isBooking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // 🔥 BOOKING FLOW — With real API call + slot support
  Future<void> _handleBookingFlow() async {
    setState(() => isBooking = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing Appointment...')),
    );

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.125:5000/api/appointments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctor': doctor!,
          'hospital': hospital!,
          'department': department!,
          if (_isScheduled && _selectedSlot != null) 'slot': _selectedSlot,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TokenScreen(
              doctor: doctor!,
              hospital: hospital!,
              department: department!,
              token: DateTime.now().millisecondsSinceEpoch % 1000,
              scheduledTime: _isScheduled ? _selectedSlot : null,
            ),
          ),
        );
      } else {
        throw Exception('Booking failed: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => isBooking = false);
    }
  }
}