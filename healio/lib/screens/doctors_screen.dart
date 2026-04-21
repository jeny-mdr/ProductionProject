import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'doctor_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});
  @override
  State<DoctorsScreen> createState() =>
      _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  List<dynamic> _doctors = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    final token = context.read<AuthProvider>().token;
    try {
      final res = await http.get(
        Uri.parse(kDoctorsUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _doctors = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server error ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Cannot reach server';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _doctors.where((d) {
      final name = (d['name'] ??
          d['username'] ?? '')
          .toString().toLowerCase();
      final spec = (d['specialization'] ?? '')
          .toString().toLowerCase();
      return name.contains(_search) ||
          spec.contains(_search);
    }).toList();

    return Scaffold(
      backgroundColor: HealioColors.bg,
      appBar: AppBar(
        title: const Text('Find Doctors'),
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white),
            onPressed: _fetch,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: HealioColors.bgCard,
            padding: const EdgeInsets.fromLTRB(
                16, 12, 16, 12),
            child: TextField(
              onChanged: (v) => setState(
                      () => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText:
                'Search by name or specialization…',
                prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: HealioColors.primary),
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(
                    color: HealioColors.primary))
                : _error != null
                ? _ErrorState(_error!, _fetch)
                : filtered.isEmpty
                ? Center(
                child: Text(
                  'No doctors found',
                  style: GoogleFonts.poppins(
                      color:
                      HealioColors.textMid),
                ))
                : RefreshIndicator(
              color: HealioColors.primary,
              onRefresh: _fetch,
              child: ListView.builder(
                padding:
                const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (_, i) =>
                    _DoctorCard(
                        doctor: filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final name = doctor['username'] ?? 'Unknown';
    final spec = doctor['specialization'] ?? '';
    final fee  = doctor['consultation_fee'];
    final exp  = doctor['experience_years'];

    // TEMP DEBUG - remove after testing
    debugPrint('Doctor: $name, pic: ${doctor['profile_picture']}');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorProfileScreen(
              doctor: doctor),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HealioColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: HealioColors.border),
          boxShadow: [
            BoxShadow(
              color: HealioColors.primary
                  .withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: HealioColors.primaryLight,
            child: doctor['profile_picture'] != null &&
                doctor['profile_picture'].toString().isNotEmpty
                ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: doctor['profile_picture'].toString(),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Text(
                  name[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: HealioColors.primary,
                  ),
                ),
              ),
            )
                : Text(
              name[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: HealioColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text('Dr. ${name[0].toUpperCase()}${name.substring(1)}',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: HealioColors.textDark,
                    )),
                if (spec.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(spec,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: HealioColors.textMid,
                      )),
                ],
                if (fee != null) ...[
                  const SizedBox(height: 4),
                  Text('Rs. $fee / session',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: HealioColors.primary,
                      )),
                ],
                if (exp != null) ...[
                  const SizedBox(height: 2),
                  Text('$exp years experience',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: HealioColors.textLight,
                      )),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.circle,
                      size: 8,
                      color: HealioColors.online),
                  const SizedBox(width: 4),
                  Text('Verified',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: HealioColors.textLight,
                      )),
                ]),
              ],
            ),
          ),

          const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: HealioColors.textLight),
        ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorState(this.msg, this.onRetry);

  @override
  Widget build(BuildContext context) =>
      Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 56,
              color: HealioColors.textLight),
          const SizedBox(height: 12),
          Text(msg,
              style: GoogleFonts.poppins(
                  color: HealioColors.textMid)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 44)),
            child: const Text('Retry'),
          ),
        ],
      ));
}