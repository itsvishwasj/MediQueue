import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    setState(() => _user = user);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${_user?.name.split(' ').first ?? 'Patient'} 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a1a2e),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'What would you like to do?',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.grey),
                    tooltip: 'Logout',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Banner card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1a73e8), Color(0xFF0d47a1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Skip the wait,\nBook your slot!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Real-time queue management',
                            style: TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.queue, size: 64, color: Colors.white24),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),

              const SizedBox(height: 16),

              // Action grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _ActionCard(
                    icon: Icons.calendar_today,
                    label: 'Book\nAppointment',
                    color: const Color(0xFF1a73e8),
                    onTap: () => Navigator.pushNamed(context, '/book'),
                  ),
                  _ActionCard(
                    icon: Icons.list_alt,
                    label: 'My\nAppointments',
                    color: const Color(0xFF34a853),
                    onTap: () => Navigator.pushNamed(context, '/appointments'),
                  ),
                  _ActionCard(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan\nQR Code',
                    color: const Color(0xFFfb8c00),
                    onTap: () => Navigator.pushNamed(context, '/scan'),
                  ),
                  _ActionCard(
                    icon: Icons.people_alt_outlined,
                    label: 'Live\nQueue',
                    color: const Color(0xFFe53935),
                    onTap: () => Navigator.pushNamed(context, '/queue'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Info cards
              const Text(
                'How it works',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),

              const SizedBox(height: 16),

              _StepCard(
                number: '1',
                title: 'Book a slot',
                subtitle: 'Choose hospital, department and doctor',
                color: const Color(0xFF1a73e8),
              ),
              _StepCard(
                number: '2',
                title: 'Get your token',
                subtitle: 'Receive a token number and QR code',
                color: const Color(0xFF34a853),
              ),
              _StepCard(
                number: '3',
                title: 'Track live queue',
                subtitle: 'See real-time updates on waiting time',
                color: const Color(0xFFfb8c00),
              ),
              _StepCard(
                number: '4',
                title: 'Scan at cabin',
                subtitle: 'Scan your QR when your turn arrives',
                color: const Color(0xFFe53935),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Action card widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a2e),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step card widget
class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Color color;

  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}