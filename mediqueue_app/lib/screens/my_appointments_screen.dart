import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final appointments = await AppointmentService.getMyAppointments();
      setState(() => _appointments = appointments);
    } catch (e) {
      setState(() => _error = 'Failed to load appointments');
    }
    setState(() => _isLoading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'serving':   return const Color(0xFF1a73e8);
      case 'completed': return const Color(0xFF34a853);
      case 'cancelled': return Colors.red;
      default:          return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'serving':   return Icons.medical_services;
      case 'completed': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default:          return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Appointments',
          style: TextStyle(
            color: Color(0xFF1a1a2e),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1a73e8)),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAppointments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _appointments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            'No appointments today',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Book an appointment to get started',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/book'),
                            icon: const Icon(Icons.add),
                            label: const Text('Book Appointment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1a73e8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        final apt = _appointments[index];
                        return _AppointmentCard(
                          appointment: apt,
                          statusColor: _statusColor(apt.status),
                          statusIcon: _statusIcon(apt.status),
                          onViewQueue: () {
                            Navigator.pushNamed(
                              context,
                              '/queue',
                              arguments: {
                                'doctorId': apt.doctorName,
                                'tokenNumber': apt.tokenNumber,
                              },
                            );
                          },
                        );
                      },
                    ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onViewQueue;

  const _AppointmentCard({
    required this.appointment,
    required this.statusColor,
    required this.statusIcon,
    required this.onViewQueue,
  });

  @override
  Widget build(BuildContext context) {
    final apt = appointment;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apt.doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        apt.doctorDepartment,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    apt.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Token number
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Token',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${apt.tokenNumber}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a73e8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(width: 1, height: 60, color: Colors.grey.shade200),

                // QR Code
                Expanded(
                  child: Center(
                    child: QrImageView(
                      data: apt.checkinUrl ??
                          'mediqueue://checkin?appointmentId=${apt.id}',
                      version: QrVersions.auto,
                      size: 80,
                    ),
                  ),
                ),

                // Divider
                Container(width: 1, height: 60, color: Colors.grey.shade200),

                // Wait time
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Est. Wait',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${apt.estimatedWaitTime}m',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Type badge + view queue button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: apt.type == 'emergency'
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    apt.type.toUpperCase(),
                    style: TextStyle(
                      color: apt.type == 'emergency'
                          ? Colors.red
                          : Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (apt.status == 'waiting' || apt.status == 'serving')
                  TextButton.icon(
                    onPressed: onViewQueue,
                    icon: const Icon(Icons.people_alt_outlined, size: 16),
                    label: const Text('View Queue'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1a73e8),
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