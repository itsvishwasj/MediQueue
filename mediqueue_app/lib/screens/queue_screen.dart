import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../services/socket_service.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  String? _doctorId;
  int? _myTokenNumber;

  // Queue state
  int? _currentToken;
  String? _currentPatient;
  int _waitingCount = 0;
  List<dynamic> _queue = [];
  bool _isLoading = true;
  String? _doctorName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && _doctorId == null) {
      _doctorId = args['doctorId'];
      _myTokenNumber = args['tokenNumber'];
      _loadQueue();
      _connectSocket();
    }
  }

  Future<void> _loadQueue() async {
    if (_doctorId == null) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.queue}/$_doctorId'));
      final data = jsonDecode(res.body);
      setState(() {
        _currentToken   = data['currentToken'];
        _currentPatient = data['currentPatient'];
        _waitingCount   = data['waitingCount'] ?? 0;
        _queue          = data['queue'] ?? [];
        _doctorName     = data['doctorName'];
      });
    } catch (e) {
      print('Failed to load queue: $e');
    }
    setState(() => _isLoading = false);
  }

  void _connectSocket() {
    if (_doctorId == null) return;
    SocketService.connect();
    SocketService.joinQueue(_doctorId!);
    SocketService.onQueueUpdate(_doctorId!, (data) {
      if (!mounted) return;
      if (data['type'] == 'NEXT_PATIENT') {
        setState(() {
          _currentToken   = data['currentToken'];
          _currentPatient = data['currentPatient'];
          _waitingCount   = data['waitingCount'] ?? 0;
          _queue          = data['queue'] ?? [];
        });
      } else if (data['type'] == 'QUEUE_EMPTY') {
        setState(() {
          _currentToken   = null;
          _currentPatient = null;
          _waitingCount   = 0;
          _queue          = [];
        });
      } else if (data['type'] == 'NEW_APPOINTMENT') {
        _loadQueue();
      }
    });
  }

  @override
  void dispose() {
    if (_doctorId != null) {
      SocketService.leaveQueue(_doctorId!);
      SocketService.offQueueUpdate(_doctorId!);
    }
    super.dispose();
  }

  // Find my position in queue
  int get _myPosition {
    if (_myTokenNumber == null) return -1;
    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i]['tokenNumber'] == _myTokenNumber) return i + 1;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _doctorName ?? 'Live Queue',
          style: const TextStyle(
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
            onPressed: _loadQueue,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Live indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Live updates enabled',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Currently serving
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1a73e8), Color(0xFF0d47a1)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Now Serving',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentToken != null ? '#$_currentToken' : '--',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentPatient != null)
                          Text(
                            _currentPatient!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // My token status
                  if (_myTokenNumber != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _myPosition == -1
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _myPosition == -1
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _myPosition == -1
                                ? Icons.check_circle
                                : Icons.person_pin_circle,
                            color: _myPosition == -1
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your token: #$_myTokenNumber',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _myPosition == -1
                                    ? 'Your turn has arrived!'
                                    : '$_myPosition people ahead of you',
                                style: TextStyle(
                                  color: _myPosition == -1
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _StatCard(
                        label: 'Waiting',
                        value: '$_waitingCount',
                        icon: Icons.people,
                        color: const Color(0xFF1a73e8),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Your position',
                        value: _myPosition == -1 ? 'Done' : '#$_myPosition',
                        icon: Icons.pin_drop,
                        color: Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Queue list
                  Container(
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
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Text(
                                'Waiting List',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$_waitingCount patients',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        if (_queue.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No patients waiting',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _queue.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _queue[index];
                              final isMe = item['tokenNumber'] ==
                                  _myTokenNumber;
                              return Container(
                                color: isMe
                                    ? const Color(0xFF1a73e8).withOpacity(0.05)
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    // Position
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? const Color(0xFF1a73e8)
                                            : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${item['position']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isMe
                                                ? Colors.white
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Token + name
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '#${item['tokenNumber']} ${isMe ? '(You)' : item['patientName'] ?? ''}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isMe
                                                  ? const Color(0xFF1a73e8)
                                                  : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            '~${item['estimatedWaitTime']} min wait',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Type badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: item['type'] == 'emergency'
                                            ? Colors.red.shade50
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item['type'].toString().toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: item['type'] == 'emergency'
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}