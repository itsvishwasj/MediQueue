import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Add these imports to connect to your existing backend services & models
import '../config/api.dart';
import '../services/hospital_service.dart';
import '../models/hospital.dart';
import '../models/doctor.dart';
import '../services/appointment_service.dart';
import '../services/auth_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/hospital_card.dart';

// ─── CONSTANTS ──────────────────────────────────────────────────────────────
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF00C97A);
const _bg = Color(0xFFF0F4FF);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _surface = Colors.white;
const _border = Color(0xFFE8ECFF);

// ─── TOKEN SCREEN ────────────────────────────────────────────────────────────
class TokenScreen extends StatefulWidget {
  final String appointmentId;
  final String doctor;
  final String hospital;
  final String department;
  final int token;
  final String? scheduledTime;

  const TokenScreen({
    super.key,
    required this.appointmentId,
    required this.doctor,
    required this.hospital,
    required this.department,
    required this.token,
    this.scheduledTime,
  });

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  String _patientName = '';
  String _patientPhone = '';
  bool _isLoadingPatient = true;

  @override
  void initState() {
    super.initState();
    _loadPatientInfo();
  }

  Future<void> _loadPatientInfo() async {
    try {
      // Get patient info from auth service
      final user = await AuthService.getUser();
      if (mounted) {
        setState(() {
          _patientName = user?.name ?? 'Guest';
          _patientPhone = user?.phone ?? '';
          _isLoadingPatient = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _patientName = 'Guest';
          _patientPhone = '';
          _isLoadingPatient = false;
        });
      }
    }
  }

  String _generateQrData() {
    final date = widget.scheduledTime ?? DateTime.now().toIso8601String().split('T')[0];
    return 'id=${widget.appointmentId}&patient=${_patientName.isNotEmpty ? _patientName : "Guest"}&doctor=${widget.doctor}&hospital=${widget.hospital}&department=${widget.department}&token=${widget.token}&date=$date&phone=${_patientPhone.isNotEmpty ? _patientPhone : ""}';
  }

  @override
  Widget build(BuildContext context) {
    final isScheduled = widget.scheduledTime != null;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
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
                      '#${widget.token}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 68,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    if (isScheduled)
                      Text(
                        widget.scheduledTime!,
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
                padding: const EdgeInsets.all(16), // Reduced padding
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
                    _row('Patient', _patientName.isNotEmpty ? _patientName : 'Loading...', Icons.person_outline_rounded),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)), // Reduced height
                    _row('Doctor', widget.doctor, Icons.person_outline_rounded),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)), // Reduced height
                    _row('Hospital', widget.hospital, Icons.local_hospital_outlined),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)), // Reduced height
                    _row('Department', widget.department, Icons.medical_services_outlined),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)), // Reduced height
                    _row('Date', widget.scheduledTime ?? 'Not scheduled', Icons.calendar_today_outlined),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)), // Reduced height
                    _row('Token', widget.token.toString(), Icons.confirmation_number_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 16), // Reduced spacing

              // 🔥 QR CODE BOX — Old UI style
              Container(
                width: double.infinity,
                height: 250, // Reduced height
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _primary.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_patientName.isNotEmpty)
                      QrImageView(
                        data: _generateQrData(),
                        version: QrVersions.auto,
                        size: 160.0, // Reduced QR code size
                        backgroundColor: Colors.white,
                      )
                    else
                      const CircularProgressIndicator(),
                    const SizedBox(height: 12), // Reduced spacing
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
                      'Token: ${widget.token}',
                      style: TextStyle(color: _muted.withOpacity(0.4), fontSize: 10),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16), // Reduced spacing

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
  final String? preSelectedHospital;
  final String? preSelectedDepartment;

  const BookAppointmentScreen({
    super.key, 
    this.preSelectedHospital,
    this.preSelectedDepartment,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen>
    with SingleTickerProviderStateMixin {
  String? department;
  String? hospital;
  String? doctor;
  bool isBooking = false;
  bool _isScheduled = false;
  String? _selectedSlot;
  String? _pendingPreselectedHospital;
  Position? _userPosition;
  String? _pendingPreselectedDepartment;
  late final bool _isHospitalFirstFlow;

  // Real Database Lists
  List<String> _allDepartmentList = [];
  List<HospitalModel> _filteredHospitalList = [];
  List<HospitalModel> _allHospitalList = [];
  List<DoctorModel> _doctorList = [];
  List<String> _hospitalDepartmentList = [];

  // Live Queue Insight Variables
  int waitingCount = 0;
  int estimatedTime = 10;
  int currentServing = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    debugPrint('📄 [BOOKING] BookAppointmentScreen initiated');
    debugPrint('📄 [BOOKING] preSelectedDepartment: ${widget.preSelectedDepartment}');
    debugPrint('📄 [BOOKING] preSelectedHospital: ${widget.preSelectedHospital}');
    
    _pendingPreselectedHospital = widget.preSelectedHospital;
    _pendingPreselectedDepartment = widget.preSelectedDepartment;
    _isHospitalFirstFlow = (widget.preSelectedHospital != null && widget.preSelectedHospital!.trim().isNotEmpty);
    _loadAllDepartments(); // Load all departments first
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  Future<void> _loadAllDepartments() async {
    try {
      debugPrint('📡 [BOOKING] Loading all departments...');
      final hospitals = await HospitalService.getHospitals();
      debugPrint('🏥 [BOOKING] Got ${hospitals.length} hospitals');
      
      setState(() => _allHospitalList = hospitals);

      // Collect all unique departments from all hospitals
      final Set<String> allDepts = {};
      for (final hospital in hospitals) {
        final depts = await HospitalService.getDepartments(hospital.id);
        allDepts.addAll(depts);
        debugPrint('  - ${hospital.name}: $depts');
      }
      debugPrint('📂 [BOOKING] All departments collected: $allDepts');
      
      setState(() => _allDepartmentList = allDepts.toList()..sort());

      // Handle pre-selected department first if available
      if (_pendingPreselectedDepartment != null && _allDepartmentList.isNotEmpty) {
        debugPrint('🎯 [BOOKING] Handling pre-selected department: $_pendingPreselectedDepartment');
        _handlePreSelectedDepartment(_pendingPreselectedDepartment!);
        _pendingPreselectedDepartment = null;
      } else if (_pendingPreselectedHospital != null && _allHospitalList.isNotEmpty) {
        debugPrint('🏥 [BOOKING] Handling pre-selected hospital: $_pendingPreselectedHospital');
        _handlePreSelectedHospital(_pendingPreselectedHospital!);
        _pendingPreselectedHospital = null;
      } else {
        debugPrint('ℹ️  [BOOKING] No pre-selected department or hospital');
      }
      _determinePositionAndSort();
    } catch (e) {
      debugPrint("❌ [BOOKING] Error loading departments: $e");
    }
  }


  Future<void> _determinePositionAndSort() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userPosition = position;
      });
      _sortHospitals();
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _sortHospitals() {
    if (_userPosition == null || _allHospitalList.isEmpty) return;
    
    for (var h in _allHospitalList) {
      if (h.latitude != null && h.longitude != null) {
        h.distanceInKm = Geolocator.distanceBetween(
          _userPosition!.latitude, 
          _userPosition!.longitude, 
          h.latitude!, 
          h.longitude!
        ) / 1000.0;
      }
    }
    
    setState(() {
      _allHospitalList.sort((a, b) {
        if (a.distanceInKm == null && b.distanceInKm == null) return 0;
        if (a.distanceInKm == null) return 1;
        if (b.distanceInKm == null) return -1;
        return a.distanceInKm!.compareTo(b.distanceInKm!);
      });
      // also ensure _filteredHospitalList is sorted if it has items
      if (_filteredHospitalList.isNotEmpty) {
        _filteredHospitalList.sort((a, b) {
          if (a.distanceInKm == null && b.distanceInKm == null) return 0;
          if (a.distanceInKm == null) return 1;
          if (b.distanceInKm == null) return -1;
          return a.distanceInKm!.compareTo(b.distanceInKm!);
        });
      }
    });
  }

  void _handlePreSelectedDepartment(String dept) {
    // Normalize the department name for matching
    final normalizedDept = dept.trim();
    final fallbackGeneralDept = _resolveGeneralMedicineDepartment();
    
    // Try to find exact match first (case-insensitive)
    final matchingDept = _allDepartmentList.firstWhere(
      (d) => d.toLowerCase() == normalizedDept.toLowerCase(),
      orElse: () => '',
    );
    
    if (matchingDept.isNotEmpty) {
      debugPrint('✓ Department matched: $matchingDept');
      setState(() {
        department = matchingDept;
        hospital = null;
        doctor = null;
        _filteredHospitalList = [];
        _doctorList = [];
      });
      // Filter hospitals by this department
      _filterHospitalsByDepartment(matchingDept);
    } else {
      final resolvedDept = fallbackGeneralDept ?? normalizedDept;
      debugPrint(
        '⚠ Department not found: $normalizedDept. '
        'Falling back to: $resolvedDept. Available: $_allDepartmentList',
      );
      setState(() {
        department = resolvedDept;
        hospital = null;
        doctor = null;
        _filteredHospitalList = [];
        _doctorList = [];
      });
      _filterHospitalsByDepartment(resolvedDept);
    }
  }

  String? _resolveGeneralMedicineDepartment() {
    final exactMatch = _allDepartmentList.firstWhere(
      (d) => d.toLowerCase().trim() == 'general medicine',
      orElse: () => '',
    );
    if (exactMatch.isNotEmpty) return exactMatch;

    final generalLikeMatch = _allDepartmentList.firstWhere(
      (d) {
        final normalized = d.toLowerCase().trim();
        return normalized.contains('general') ||
            normalized.contains('medicine') ||
            normalized == 'gp';
      },
      orElse: () => '',
    );
    return generalLikeMatch.isNotEmpty ? generalLikeMatch : null;

  }

  void _handlePreSelectedHospital(String hospitalName) {
    // Find the hospital in the list and pre-select it
    final selectedHospital = _allHospitalList.firstWhere(
      (h) => h.name.toLowerCase() == hospitalName.toLowerCase(),
      orElse: () => _allHospitalList.isNotEmpty ? _allHospitalList[0] : throw Exception('No hospitals available'),
    );

    setState(() {
      hospital = selectedHospital.name;
      department = null;
      doctor = null;
      _filteredHospitalList = [];
      _doctorList = [];
    });
    // Load departments for the pre-selected hospital
    _loadDepartmentsForHospital(selectedHospital.id);
  }

  Future<void> _loadDepartmentsForHospital(String hospitalId) async {
    try {
      final depts = await HospitalService.getDepartments(hospitalId);
      setState(() => _hospitalDepartmentList = depts);
    } catch (e) {
      debugPrint("Error loading departments for hospital: $e");
      setState(() => _hospitalDepartmentList = []);
    }
  }

  void _filterHospitalsByDepartment(String dept) {
    final normalizedDept = dept.toLowerCase().trim();
    
    final filteredHospitals = _allHospitalList.where((hospital) {
      return hospital.departments.any((d) => d.toLowerCase().trim() == normalizedDept);
    }).toList();
    
    debugPrint('Filtered hospitals for $dept: ${filteredHospitals.length} found');
    setState(() => _filteredHospitalList = filteredHospitals);
  }

  Future<void> _loadDoctors(String hospitalId, String dept) async {
    try {
      final docs = await HospitalService.getDoctors(hospitalId: hospitalId, department: dept);
      setState(() => _doctorList = docs);
    } catch (e) {
      debugPrint("Error loading doctors: $e");
    }
  }

  Future<void> _fetchDoctorQueueInfo() async {
    if (doctor == null) return;
    try {
      final dId = _doctorList.firstWhere((d) => d.name == doctor).id;
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/queue/$dId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            waitingCount = data['waitingCount'] ?? 0;
            currentServing = data['currentToken'] ?? 0;
            
            // Calculate dynamic estimate
            estimatedTime = (waitingCount > 0) ? waitingCount * 10 : 10;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching queue info: $e");
    }
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // 🔥 INFO BANNER — Old UI style
                  _buildInfoCard(),
                  const SizedBox(height: 24),

                  if (_isHospitalFirstFlow) ...[
                    _label('Select Hospital'),
                    const SizedBox(height: 8),
                    _buildHospitalDropdown(
                      _allHospitalList,
                      hospital,
                      (v) async {
                        setState(() {
                          hospital = v;
                          department = null;
                          doctor = null;
                          _doctorList = [];
                          _hospitalDepartmentList = [];
                        });
                        if (v != null) {
                          final hId = _allHospitalList.firstWhere((h) => h.name == v).id;
                          await _loadDepartmentsForHospital(hId);
                        }
                      },
                    ),
                    // Hospital card removed to be placed at the bottom
                    _label('Select Department'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      'Department',
                      department,
                      _hospitalDepartmentList,
                      Icons.medical_services_outlined,
                      (v) {
                        setState(() {
                          department = v;
                          doctor = null;
                          _doctorList = [];
                        });
                        if (v != null && hospital != null) {
                          final hId = _allHospitalList.firstWhere((h) => h.name == hospital).id;
                          _loadDoctors(hId, v);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    _label('Select Department'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      'Department',
                      department,
                      _allDepartmentList,
                      Icons.medical_services_outlined,
                      (v) {
                        setState(() {
                          department = v;
                          hospital = null;
                          doctor = null;
                          _filteredHospitalList = [];
                          _doctorList = [];
                        });
                        if (v != null) {
                          _filterHospitalsByDepartment(v);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    _label('Select Hospital'),
                    const SizedBox(height: 8),
                    _buildHospitalDropdown(
                      _filteredHospitalList,
                      hospital,
                      (v) {
                        setState(() {
                          hospital = v;
                          doctor = null;
                          _doctorList = [];
                        });
                        if (v != null && department != null) {
                          final hId = _filteredHospitalList.firstWhere((h) => h.name == v).id;
                          _loadDoctors(hId, department!);
                        }
                      },
                    ),
                    // Hospital card moved to bottom
                  ],

                  _label('Select Doctor'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    'Doctor', 
                    doctor,
                    _doctorList.map((d) => d.name).toList(),
                    Icons.person_outlined,
                    (v) {
                      setState(() => doctor = v);
                      _fetchDoctorQueueInfo();
                    },
                  ),

                  if (doctor != null) ...[
                    const SizedBox(height: 28),
                    _buildModeToggle(),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: _isScheduled ? _buildScheduleSection() : _buildWalkInView(),
                    ),
                    if (hospital != null) ...[
                      const SizedBox(height: 24),
                      Builder(builder: (ctx) {
                        final h = _allHospitalList.firstWhere((e) => e.name == hospital);
                        return HospitalCard(
                          hospitalName: h.name,
                          hospitalLat: h.hospitalLat,
                          hospitalLon: h.hospitalLon,
                          currentQueueWait: estimatedTime,
                          onTap: () {},
                        );
                      }),
                    ],
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
    return Material(
      color: Colors.transparent,
      child: Container(
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
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ))
              .toList(),
          onChanged: isBooking ? null : onChanged,
          dropdownColor: _surface,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
        ),
      ),
    );
  }

  // 🔥 CUSTOM LOCATION HOSPITAL DROPDOWN
  Widget _buildHospitalDropdown(
    List<HospitalModel> hospitals,
    String? value,
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
        isExpanded: true,
        hint: const Text(
          'Choose Hospital',
          style: TextStyle(fontSize: 14, color: _muted),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.local_hospital_outlined, size: 20, color: value != null ? _primary : _muted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        icon: const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.expand_more_rounded, color: _muted),
        ),
        items: hospitals.map((h) {
          String display = h.name;
          if (h.distanceInKm != null) {
            display = "$display · ${h.distanceInKm!.toStringAsFixed(1)}km away";
          }
          return DropdownMenuItem(
            value: h.name,
            child: Text(
              display,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          );
        }).toList(),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1D3A), Color(0xFF1A3560), Color(0xFF1E4A7A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.55, 1.0],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LIVE STATUS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.circle, color: _success, size: 8),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('$waitingCount', 'Waiting'),
                  _statItem('~$estimatedTime', 'Mins'),
                  _statItem('#$currentServing', 'Serving'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 🔥 SMART SUGGESTION MESSAGE
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: _primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Less waiting after 11:30 AM',
                  style: TextStyle(fontSize: 12.5, color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
                ),
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
        // 🔥 DOCTOR AVAILABILITY CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _primary.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.access_time_rounded, color: _primary, size: 22),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Doctor Available',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _ink),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '9 AM – 1 PM, 6 PM – 9 PM',
                    style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
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

  // 🔥 BOOKING FLOW — With real API call to MongoDB
  Future<void> _handleBookingFlow() async {
    setState(() => isBooking = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing Appointment...')),
    );

    try {
      // Look up the exact IDs required by the Node.js backend
      final hId = _allHospitalList.firstWhere((h) => h.name == hospital).id;
      final dId = _doctorList.firstWhere((d) => d.name == doctor).id;

      final appointment = await AppointmentService.bookAppointment(
        doctorId: dId,
        hospitalId: hId,
        department: department!,
        type: (_isScheduled && _selectedSlot != null) ? 'normal' : 'normal',
      );

      if (!mounted) return;
        
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TokenScreen(
            appointmentId: appointment.id,
            doctor: doctor!,
            hospital: hospital!,
            department: department!,
            token: appointment.tokenNumber,
            scheduledTime: appointment.date,
          ),
        ),
      );
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
