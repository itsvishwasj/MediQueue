import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  UserModel? _user;

  // ── Page entrance ─────────────────────────────────────────────────
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Result expand ────────────────────────────────────────────────
  late AnimationController _expandController;
  late Animation<double> _expandAnim;

  // ── Thinking dots ────────────────────────────────────────────────
  late AnimationController _dotsController;

  // ── Pulse for live badge ─────────────────────────────────────────
  late AnimationController _pulseController;

  // ── Omni-bar state ───────────────────────────────────────────────
  final TextEditingController _symptomsController = TextEditingController();
  final FocusNode _symptomsFocus = FocusNode();
  _OmniBarState _omniState = _OmniBarState.idle;
  bool _hasText = false;
  String _aiResult = '';
  String _aiSpecialty = '';
  String _aiEmoji = '';

  // ── Design tokens ────────────────────────────────────────────────
  // Deep navy + clinical teal palette — premium medical feel
  static const _bg            = Color(0xFFF0F4F8);
  static const _surface       = Color(0xFFFFFFFF);
  static const _navy          = Color(0xFF0B1D3A);
  static const _navyLight     = Color(0xFF1A3560);
  static const _teal          = Color(0xFF0EA5A0);
  static const _primary       = Color(0xFF2563EB);
  static const _tealDark      = Color(0xFF0B8580);
  static const _accent        = Color(0xFF06C8A0); // mint green highlight
  static const _ink           = Color(0xFF0B1D3A);
  static const _subtext       = Color(0xFF64748B);
  static const _border        = Color(0xFFE2E8F0);
  static const _cardShadow    = Color(0x14000000);

  // ── Triage knowledge base ────────────────────────────────────────
  static const _triageMap = <String, _TriageResponse>{
    'chest':   _TriageResponse('Cardiology',        '❤️',  Color(0xFFE53E3E), 'Chest discomfort can indicate cardiac conditions. Prompt evaluation by a cardiologist is strongly recommended.'),
    'heart':   _TriageResponse('Cardiology',        '❤️',  Color(0xFFE53E3E), 'Chest discomfort can indicate cardiac conditions. Prompt evaluation by a cardiologist is strongly recommended.'),
    'breath':  _TriageResponse('Pulmonology',       '🫁',  Color(0xFF805AD5), 'Difficulty breathing may point to a respiratory condition. A pulmonologist can provide a thorough assessment.'),
    'breathe': _TriageResponse('Pulmonology',       '🫁',  Color(0xFF805AD5), 'Difficulty breathing may point to a respiratory condition. A pulmonologist can provide a thorough assessment.'),
    'head':    _TriageResponse('Neurology',         '🧠',  Color(0xFF3182CE), 'Persistent headaches warrant a neurological review to rule out underlying causes.'),
    'fever':   _TriageResponse('General Medicine',  '🌡️', Color(0xFFDD6B20), 'Fever alongside other symptoms may need immediate attention. A general physician visit is the right first step.'),
    'stomach': _TriageResponse('Gastroenterology', '🩺',  Color(0xFF38A169), 'Stomach complaints vary widely in cause. A gastroenterologist can accurately diagnose and treat you.'),
    'skin':    _TriageResponse('Dermatology',       '✨',  Color(0xFF805AD5), 'Skin concerns are best evaluated by a dermatologist for an accurate and timely diagnosis.'),
    'eye':     _TriageResponse('Ophthalmology',     '👁️', Color(0xFF3182CE), 'Eye symptoms should be assessed promptly by an ophthalmologist to protect your vision.'),
    'back':    _TriageResponse('Orthopedics',       '🦴',  Color(0xFF92400E), 'Back pain has many causes. An orthopedic specialist can pinpoint the issue and recommend treatment.'),
    'joint':   _TriageResponse('Rheumatology',      '🦴',  Color(0xFF92400E), 'Joint discomfort can stem from various conditions. Rheumatology testing will provide clarity.'),
    'throat':  _TriageResponse('ENT',               '👄',  Color(0xFFB83280), 'Throat pain or irritation is best assessed by an ENT (Ear, Nose & Throat) specialist.'),
    'ear':     _TriageResponse('ENT',               '👂',  Color(0xFFB83280), 'Ear-related symptoms should be evaluated by an ENT specialist for accurate diagnosis.'),
  };

  static const _defaultTriage = _TriageResponse(
    'General Medicine', '🩺', Color(0xFF0EA5A0),
    'Based on your description, we recommend starting with a General Physician for a comprehensive evaluation.',
  );

  @override
  void initState() {
    super.initState();
    _loadUser();

    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    _entranceController.forward();

    _expandController = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _expandAnim = CurvedAnimation(parent: _expandController, curve: Curves.easeOutCubic);

    _dotsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _symptomsController.addListener(() {
      final hasText = _symptomsController.text.isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _expandController.dispose();
    _dotsController.dispose();
    _pulseController.dispose();
    _symptomsController.dispose();
    _symptomsFocus.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _runTriage(String text) async {
    if (text.trim().isEmpty) return;
    _symptomsFocus.unfocus();
    setState(() {
      _omniState   = _OmniBarState.thinking;
      _aiResult    = '';
      _aiSpecialty = '';
      _aiEmoji     = '';
    });
    _expandController.reverse();

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final lower = text.toLowerCase();
    var triage = _defaultTriage;
    for (final entry in _triageMap.entries) {
      if (lower.contains(entry.key)) { triage = entry.value; break; }
    }

    setState(() {
      _omniState   = _OmniBarState.result;
      _aiResult    = triage.message;
      _aiSpecialty = triage.specialty;
      _aiEmoji     = triage.emoji;
    });
    _expandController.forward();
  }

  void _resetOmniBar() {
    setState(() {
      _omniState = _OmniBarState.idle;
      _aiResult = _aiSpecialty = _aiEmoji = '';
      _hasText = false;
      _symptomsController.clear();
    });
    _expandController.reverse();
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _buildTopBar(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildHeroBlock(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: _sectionLabel('Quick Actions'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate(_buildActionCards()),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final firstName = _user?.name.split(' ').first ?? '';
    final greeting = _getGreeting();

    return Row(
      children: [
        // Logo mark — rounded square with cross icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _teal.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'MediQueue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.7,
                  height: 1.1,
                ),
              ),
              if (_user != null)
                Text(
                  '$greeting, $firstName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _subtext,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                )
              else
                const Text(
                  'Smart Healthcare Queue',
                  style: TextStyle(
                    fontSize: 12,
                    color: _subtext,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        // Live badge
        _LiveBadge(pulseController: _pulseController),
        const SizedBox(width: 10),
        // Profile / logout
        _buildAvatarButton(),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildAvatarButton() {
    return GestureDetector(
      onTap: () async {
        await AuthService.logout();
        if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _navy.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 1.2),
        ),
        child: const Icon(Icons.logout_rounded, color: _subtext, size: 20),
      ),
    );
  }

  // ── Hero block ────────────────────────────────────────────────────

  Widget _buildHeroBlock() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _navyLight, Color(0xFF1E4A7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.30),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // ── Decorative geometry ──────────────────────────────────
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _teal.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Top row: badge + reset ──────────────────────────
                Row(
                  children: [
                    _AiBadge(),
                    const Spacer(),
                    if (_omniState != _OmniBarState.idle)
                      GestureDetector(
                        onTap: _resetOmniBar,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.18)),
                          ),
                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 18),

                // ── Headline ─────────────────────────────────────────
                const Text(
                  'AI-Powered\nSymptom Triage',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.18,
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 8),

                // ── Subtext ──────────────────────────────────────────
                Text(
                  'Describe how you feel — we\'ll route you to the right specialist instantly.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.60),
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Input field ──────────────────────────────────────
                _buildSymptomInput(),

                // ── Thinking indicator ───────────────────────────────
                if (_omniState == _OmniBarState.thinking) ...[
                  const SizedBox(height: 14),
                  _buildThinkingIndicator(),
                ],

                // ── Result card ──────────────────────────────────────
                if (_omniState == _OmniBarState.result) ...[
                  const SizedBox(height: 14),
                  SizeTransition(
                    sizeFactor: _expandAnim,
                    axisAlignment: -1,
                    child: FadeTransition(
                      opacity: _expandAnim,
                      child: _buildResultCard(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Symptom input ─────────────────────────────────────────────────

  Widget _buildSymptomInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 18, right: 8, top: 2, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _symptomsController,
              focusNode: _symptomsFocus,
              enabled: _omniState == _OmniBarState.idle,
              style: const TextStyle(
                fontSize: 14,
                color: _ink,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. I have a headache and fever…',
                hintStyle: TextStyle(
                  color: _subtext.withOpacity(0.50),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: _runTriage,
              textInputAction: TextInputAction.send,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: _hasText
                ? GestureDetector(
                    key: const ValueKey('send'),
                    onTap: () => _runTriage(_symptomsController.text),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primary, _tealDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _teal.withOpacity(0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                    ),
                  )
                : GestureDetector(
                    key: const ValueKey('mic'),
                    onTap: _omniState == _OmniBarState.idle
                        ? () {
                            _symptomsController.text = 'My chest hurts and I feel short of breath';
                            _runTriage(_symptomsController.text);
                          }
                        : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: _teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mic_none_rounded, color: _teal, size: 20),
                    ),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Thinking indicator ────────────────────────────────────────────

  Widget _buildThinkingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.16), width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              valueColor: AlwaysStoppedAnimation<Color>(_accent.withOpacity(0.9)),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _dotsController,
            builder: (_, __) {
              final dots = '.' * (1 + (_dotsController.value * 3).floor());
              return Text(
                'Analysing your symptoms$dots',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Result card ───────────────────────────────────────────────────

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: _teal, size: 11),
                    const SizedBox(width: 5),
                    Text(
                      'AI Recommendation',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _teal,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.onNavigate(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _tealDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _teal.withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Specialty row ────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FAFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _teal.withOpacity(0.15), width: 1),
                ),
                child: Center(
                  child: Text(_aiEmoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECOMMENDED DEPT.',
                    style: TextStyle(
                      fontSize: 9,
                      color: _subtext.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _aiSpecialty,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: _border, height: 1, thickness: 1),
          const SizedBox(height: 12),

          // ── Message ──────────────────────────────────────────────
          Text(
            _aiResult,
            style: TextStyle(
              fontSize: 12.5,
              color: _ink.withOpacity(0.55),
              height: 1.6,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────

  Widget _sectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  // ── Action cards ──────────────────────────────────────────────────

  List<Widget> _buildActionCards() {
    final actions = [
      _Action(1, Icons.calendar_month_rounded, 'Book\nAppointment', const Color(0xFF2563EB), const Color(0xFFEFF6FF), () => widget.onNavigate(1)),
      _Action(2, Icons.receipt_long_rounded,   'My\nAppointments',  const Color(0xFF059669), const Color(0xFFECFDF5), () => widget.onNavigate(2)),
      _Action(3, Icons.people_alt_rounded,     'Live\nQueue',       const Color(0xFFDC2626), const Color(0xFFFEF2F2), () => widget.onNavigate(3)),
      _Action(4, Icons.qr_code_scanner_rounded,'Scan\nQR Code',     const Color(0xFFD97706), const Color(0xFFFFFBEB), () => widget.onNavigate(4)),
    ];

    return actions.map((a) => _ActionCard(action: a)).toList();
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────

class _ActionCard extends StatefulWidget {
  final _Action action;
  const _ActionCard({required this.action});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _pressController;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _pressController.reverse();
  void _onTapUp(_)   { _pressController.forward(); widget.action.onTap(); }
  void _onTapCancel() => _pressController.forward();

  @override
  Widget build(BuildContext context) {
    final a = widget.action;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: a.color.withOpacity(0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: a.color.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Faded watermark number ──────────────────────────
              Positioned(
                right: -10,
                bottom: -14,
                child: Text(
                  '${a.number}',
                  style: TextStyle(
                    fontSize: 66,
                    fontWeight: FontWeight.w900,
                    color: a.color.withOpacity(0.07),
                    height: 1.0,
                    letterSpacing: -2.0,
                  ),
                ),
              ),

              // ── Foreground ──────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: a.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: a.color.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: Icon(a.icon, color: a.color, size: 19),
                  ),

                  // Label
                  Text(
                    a.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B1D3A),
                      height: 1.28,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live Badge ───────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  final AnimationController pulseController;
  const _LiveBadge({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22C55E).withOpacity(0.28),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, __) => Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF22C55E),
                  const Color(0xFF4ADE80),
                  pulseController.value,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Live',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Badge ─────────────────────────────────────────────────────────────────

class _AiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 11),
          SizedBox(width: 5),
          Text(
            'AI TRIAGE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── State enum ───────────────────────────────────────────────────────────────

enum _OmniBarState { idle, thinking, result }

// ─── Data classes ─────────────────────────────────────────────────────────────

class _Action {
  final int number;
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _Action(this.number, this.icon, this.label, this.color, this.bg, this.onTap);
}

class _TriageResponse {
  final String specialty;
  final String emoji;
  final Color color;
  final String message;
  const _TriageResponse(this.specialty, this.emoji, this.color, this.message);
}