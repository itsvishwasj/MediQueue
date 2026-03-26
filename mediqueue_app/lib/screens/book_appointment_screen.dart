import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class TokenScreen extends StatelessWidget {
  final String doctor;
  final String hospital;
  final String department;
  final int token;

  const TokenScreen({
    super.key,
    required this.doctor,
    required this.hospital,
    required this.department,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              // 🔥 HEADER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A6CF7), Color(0xFF6A8DFF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: const [
                    Text(
                      'Your Token',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🔥 TOKEN NUMBER
              Text(
                '#$token',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6CF7),
                ),
              ),

              const SizedBox(height: 20),

              // 🔥 DETAILS CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _row('Doctor', doctor),
                    _row('Hospital', hospital),
                    _row('Department', department),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🔥 QR PLACEHOLDER
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code, size: 120),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Scan this at hospital',
                style: TextStyle(color: Colors.grey),
              ),

              const Spacer(),

              // 🔥 BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String? hospital;
  String? department;
  String? doctor;

  static const _bg = Color(0xFFF0F4FF);
  static const _primary = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _surface = Colors.white;

  @override
void didChangeDependencies() {
  super.didChangeDependencies();

  // 🔥 Reset fields every time screen is rebuilt
  hospital = null;
  department = null;
  doctor = null;
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _fieldLabel('Hospital'),
                  const SizedBox(height: 8),
                  _buildDropdown('Hospital', hospital, ['City Hospital', 'Apollo'], Icons.local_hospital_outlined),
                  const SizedBox(height: 16),
                  _fieldLabel('Department'),
                  const SizedBox(height: 8),
                  _buildDropdown('Department', department, ['General', 'Cardiology'], Icons.medical_services_outlined),
                  const SizedBox(height: 16),
                  _fieldLabel('Doctor'),
                  const SizedBox(height: 8),
                  _buildDropdown('Doctor', doctor, ['Dr. Sharma', 'Dr. Reddy'], Icons.person_outlined),
                  const SizedBox(height: 32),
                  _buildConfirmButton(),
                ],
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
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Book Appointment',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Fill in the details to reserve your slot',
                style: TextStyle(fontSize: 13, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Select your preferred hospital, department, and doctor to confirm your appointment.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF1D4ED8), height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: -0.1,
        ),
      );

  Widget _buildDropdown(String label, String? value, List<String> items, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != null ? _primary.withOpacity(0.4) : Colors.grey.withOpacity(0.15),
          width: value != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(icon, size: 18, color: value != null ? _primary : _muted),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              hint: Text('Select $label', style: const TextStyle(fontSize: 14, color: _muted)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 14, color: _ink, fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  if (label == 'Hospital') hospital = val;
                  if (label == 'Department') department = val;
                  if (label == 'Doctor') doctor = val;
                });
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    final bool isReady = hospital != null && department != null && doctor != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        color: isReady ? _primary : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isReady
            ? [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isReady
    ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TokenScreen(
              doctor: doctor!,
              hospital: hospital!,
              department: department!,
              token: 23, // 🔥 dummy for now
            ),
          ),
        );
      }
    : null,
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Confirm Booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}