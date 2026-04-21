import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'doctor_profile_screen.dart';

// Specialization data with icons and colors
const List<Map<String, dynamic>> kSpecialistData = [
  {'name': 'General Physician',  'icon': Icons.medical_services_rounded,     'color': 0xFF5BAD8F},
  {'name': 'Cardiologist',       'icon': Icons.favorite_rounded,              'color': 0xFFE57373},
  {'name': 'Neurologist',        'icon': Icons.psychology_rounded,            'color': 0xFF00897B},
  {'name': 'Dermatologist',      'icon': Icons.face_rounded,                  'color': 0xFFF4A26D},
  {'name': 'Pediatrician',       'icon': Icons.child_care_rounded,            'color': 0xFF4BAEC4},
  {'name': 'Orthopedist',        'icon': Icons.accessibility_new_rounded,     'color': 0xFF8BC34A},
  {'name': 'Gynecologist',       'icon': Icons.child_friendly_rounded,        'color': 0xFFEC407A},
  {'name': 'Pulmonologist',      'icon': Icons.masks_rounded,                 'color': 0xFF26C6DA},
  {'name': 'Gastroenterologist', 'icon': Icons.lunch_dining_rounded,          'color': 0xFFFF7043},
  {'name': 'Endocrinologist',    'icon': Icons.water_drop_rounded,            'color': 0xFF9C27B0},
  {'name': 'Ophthalmologist',    'icon': Icons.visibility_rounded,            'color': 0xFF1E88E5},
  {'name': 'Psychiatrist',       'icon': Icons.psychology_alt_rounded,        'color': 0xFF7C83E8},
  {'name': 'Urologist',          'icon': Icons.water_drop_rounded,            'color': 0xFF039BE5},
  {'name': 'Oncologist',         'icon': Icons.coronavirus_rounded,           'color': 0xFF880E4F},
  {'name': 'ENT Specialist',     'icon': Icons.hearing_rounded,               'color': 0xFF546E7A},
];

class SpecialistsScreen extends StatelessWidget {
  const SpecialistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealioColors.bg,
      appBar: AppBar(
        backgroundColor: HealioColors.primary,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Specialists',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
            Text('Find doctors by specialization',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                )),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.1,
        ),
        itemCount: kSpecialistData.length,
        itemBuilder: (_, i) =>
            _SpecialistCard(data: kSpecialistData[i]),
      ),
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SpecialistCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = Color(data['color'] as int);
    final name  = data['name'] as String;
    final icon  = data['icon'] as IconData;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _FilteredDoctorsScreen(
                  specialization: name),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: HealioColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border:
          Border.all(color: HealioColors.border),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius:
                BorderRadius.circular(16),
              ),
              child: Icon(icon,
                  color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HealioColors.textDark,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Filtered doctors by specialization
class _FilteredDoctorsScreen extends StatefulWidget {
  final String specialization;
  const _FilteredDoctorsScreen(
      {required this.specialization});

  @override
  State<_FilteredDoctorsScreen> createState() =>
      _FilteredDoctorsScreenState();
}

class _FilteredDoctorsScreenState
    extends State<_FilteredDoctorsScreen> {
  List<dynamic> _doctors = [];
  bool          _loading = true;
  String?       _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error   = null;
    });
    final token =
        context.read<AuthProvider>().token;
    try {
      final url =
          '$kDoctorsUrl?specialization=${Uri.encodeComponent(widget.specialization)}';
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );
      if (res.statusCode == 200) {
        setState(() {
          _doctors = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error   =
          'Server error ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error   = 'Cannot reach server';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealioColors.bg,
      appBar: AppBar(
        title: Text(widget.specialization),
        backgroundColor: HealioColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white),
          onPressed: () =>
              Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(
              color: HealioColors.primary))
          : _error != null
          ? Center(
          child: Text(_error!,
              style: GoogleFonts.poppins(
                  color:
                  HealioColors.textMid)))
          : _doctors.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_search_rounded,
              size: 72,
              color: HealioColors
                  .primaryMid,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${widget.specialization}s available',
              style:
              GoogleFonts.poppins(
                fontSize: 15,
                fontWeight:
                FontWeight.w600,
                color: HealioColors
                    .textMid,
              ),
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Check back later or browse all doctors',
              style:
              GoogleFonts.poppins(
                fontSize: 13,
                color: HealioColors
                    .textLight,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding:
        const EdgeInsets.all(16),
        itemCount: _doctors.length,
        itemBuilder: (_, i) {
          final doctor = _doctors[i]
          as Map<String, dynamic>;
          final name = doctor[
          'username'] ??
              'Unknown';
          final spec = doctor[
          'specialization'] ??
              '';
          final fee = doctor[
          'consultation_fee'];
          final exp = doctor[
          'experience_years'];

          return GestureDetector(
            onTap: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DoctorProfileScreen(
                            doctor:
                            doctor),
                  ),
                ),
            child: Container(
              margin: const EdgeInsets
                  .only(bottom: 12),
              padding:
              const EdgeInsets
                  .all(16),
              decoration:
              BoxDecoration(
                color: HealioColors
                    .bgCard,
                borderRadius:
                BorderRadius
                    .circular(18),
                border: Border.all(
                    color: HealioColors
                        .border),
                boxShadow: [
                  BoxShadow(
                    color: HealioColors
                        .primary
                        .withOpacity(
                        0.06),
                    blurRadius: 10,
                    offset:
                    const Offset(
                        0, 3),
                  ),
                ],
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                  HealioColors
                      .primaryLight,
                  child: Text(
                    name[0]
                        .toUpperCase(),
                    style: GoogleFonts
                        .poppins(
                      fontSize: 20,
                      fontWeight:
                      FontWeight
                          .w700,
                      color:
                      HealioColors
                          .primary,
                    ),
                  ),
                ),
                const SizedBox(
                    width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        'Dr. ${name[0].toUpperCase()}${name.substring(1)}',
                        style: GoogleFonts
                            .poppins(
                          fontSize: 15,
                          fontWeight:
                          FontWeight
                              .w700,
                          color: HealioColors
                              .textDark,
                        ),
                      ),
                      Text(spec,
                          style: GoogleFonts
                              .poppins(
                            fontSize:
                            12,
                            color: HealioColors
                                .textMid,
                          )),
                      if (fee != null)
                        Text(
                            'Rs. $fee / session',
                            style: GoogleFonts
                                .poppins(
                              fontSize:
                              12,
                              fontWeight:
                              FontWeight
                                  .w600,
                              color: HealioColors
                                  .primary,
                            )),
                      if (exp != null)
                        Text(
                            '$exp years exp',
                            style: GoogleFonts
                                .poppins(
                              fontSize:
                              11,
                              color: HealioColors
                                  .textLight,
                            )),
                    ],
                  ),
                ),
                const Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 16,
                  color: HealioColors
                      .textLight,
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}