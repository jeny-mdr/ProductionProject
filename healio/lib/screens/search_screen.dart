import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'doctor_profile_screen.dart';
import 'ai_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() =>
      _SearchScreenState();
}

class _SearchScreenState
    extends State<SearchScreen> {
  final _ctrl        = TextEditingController();
  List<dynamic> _doctors   = [];
  List<String>  _symptoms  = [];
  List<String>  _filteredSymptoms = [];
  bool          _loading   = false;
  bool          _searched  = false;
  List<String>  _allSymptoms = [];

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadSymptoms() async {
    final token =
        context.read<AuthProvider>().token;
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/api/ai/symptoms/'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _allSymptoms =
          List<String>.from(data['symptoms']);
        });
      }
    } catch (_) {}
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _doctors          = [];
        _filteredSymptoms = [];
        _searched         = false;
      });
      return;
    }

    setState(() {
      _loading  = true;
      _searched = true;
    });

    final token =
        context.read<AuthProvider>().token;
    final q = query.toLowerCase();

    // Filter symptoms
    final matchedSymptoms = _allSymptoms
        .where((s) => s
        .replaceAll('_', ' ')
        .contains(q))
        .take(5)
        .toList();

    // Search doctors
    try {
      final res = await http.get(
        Uri.parse(kDoctorsUrl),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );
      if (res.statusCode == 200) {
        final all =
        List<dynamic>.from(
            jsonDecode(res.body));
        final matched = all.where((d) {
          final name = (d['username'] ?? '')
              .toString()
              .toLowerCase();
          final spec =
          (d['specialization'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(q) ||
              spec.contains(q);
        }).toList();

        setState(() {
          _doctors          = matched;
          _filteredSymptoms = matchedSymptoms;
          _loading          = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealioColors.bg,
      appBar: AppBar(
        backgroundColor: HealioColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white),
          onPressed: () =>
              Navigator.pop(context),
        ),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _search,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText:
            'Search doctors or symptoms…',
            hintStyle: GoogleFonts.poppins(
              color:
              Colors.white.withOpacity(0.7),
              fontSize: 15,
            ),
            border: InputBorder.none,
            filled: false,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
              icon: const Icon(
                  Icons.clear_rounded,
                  color: Colors.white),
              onPressed: () {
                _ctrl.clear();
                _search('');
              },
            )
                : null,
          ),
        ),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(
              color: HealioColors.primary))
          : !_searched
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
                Icons.search_rounded,
                size: 72,
                color: HealioColors
                    .primaryMid),
            const SizedBox(height: 16),
            Text(
              'Search for doctors\nor symptoms',
              textAlign:
              TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color:
                HealioColors.textMid,
              ),
            ),
          ],
        ),
      )
          : _doctors.isEmpty &&
          _filteredSymptoms.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            const Icon(
                Icons
                    .search_off_rounded,
                size: 72,
                color: HealioColors
                    .textLight),
            const SizedBox(
                height: 16),
            Text(
              'No results found',
              style:
              GoogleFonts.poppins(
                fontSize: 16,
                color: HealioColors
                    .textMid,
              ),
            ),
          ],
        ),
      )
          : ListView(
        padding:
        const EdgeInsets.all(16),
        children: [
          // Doctors section
          if (_doctors.isNotEmpty) ...[
            Row(children: [
              const Icon(
                  Icons.people_rounded,
                  color: HealioColors
                      .primary,
                  size: 18),
              const SizedBox(width: 8),
              Text('Doctors',
                  style: GoogleFonts
                      .poppins(
                    fontSize: 15,
                    fontWeight:
                    FontWeight
                        .w700,
                    color: HealioColors
                        .primary,
                  )),
            ]),
            const SizedBox(height: 10),
            ..._doctors.map((d) {
              final name =
                  d['username'] ??
                      'Unknown';
              final spec =
                  d['specialization'] ??
                      '';
              final fee =
              d['consultation_fee'];
              return GestureDetector(
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DoctorProfileScreen(
                                doctor: d),
                      ),
                    ),
                child: Container(
                  margin: const EdgeInsets
                      .only(bottom: 10),
                  padding:
                  const EdgeInsets
                      .all(14),
                  decoration:
                  BoxDecoration(
                    color: HealioColors
                        .bgCard,
                    borderRadius:
                    BorderRadius
                        .circular(
                        14),
                    border: Border.all(
                        color:
                        HealioColors
                            .border),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                      HealioColors
                          .primaryLight,
                      child: Text(
                        name[0]
                            .toUpperCase(),
                        style: GoogleFonts
                            .poppins(
                          fontSize: 18,
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
                        width: 12),
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
                              fontSize:
                              14,
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
                          if (fee !=
                              null)
                            Text(
                                'Rs. $fee',
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
                        ],
                      ),
                    ),
                    const Icon(
                        Icons
                            .arrow_forward_ios_rounded,
                        size: 16,
                        color: HealioColors
                            .textLight),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          // Symptoms section
          if (_filteredSymptoms
              .isNotEmpty) ...[
            Row(children: [
              const Icon(
                  Icons
                      .biotech_rounded,
                  color: HealioColors
                      .accent,
                  size: 18),
              const SizedBox(width: 8),
              Text('Symptoms',
                  style: GoogleFonts
                      .poppins(
                    fontSize: 15,
                    fontWeight:
                    FontWeight
                        .w700,
                    color: HealioColors
                        .accent,
                  )),
            ]),
            const SizedBox(height: 10),
            ..._filteredSymptoms
                .map((s) =>
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                        const AiScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets
                        .only(
                        bottom: 8),
                    padding: const EdgeInsets
                        .symmetric(
                        horizontal:
                        14,
                        vertical:
                        12),
                    decoration:
                    BoxDecoration(
                      color: HealioColors
                          .bgCard,
                      borderRadius:
                      BorderRadius
                          .circular(
                          12),
                      border: Border.all(
                          color: HealioColors
                              .border),
                    ),
                    child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration:
                            BoxDecoration(
                              color: HealioColors
                                  .accentLight,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                  10),
                            ),
                            child: const Icon(
                                Icons
                                    .psychology_rounded,
                                color: HealioColors
                                    .accent,
                                size:
                                18),
                          ),
                          const SizedBox(
                              width: 12),
                          Expanded(
                            child: Text(
                              s.replaceAll(
                                  '_',
                                  ' '),
                              style: GoogleFonts
                                  .poppins(
                                fontSize:
                                14,
                                color: HealioColors
                                    .textDark,
                              ),
                            ),
                          ),
                          const Icon(
                              Icons
                                  .arrow_forward_ios_rounded,
                              size: 14,
                              color: HealioColors
                                  .textLight),
                        ]),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}