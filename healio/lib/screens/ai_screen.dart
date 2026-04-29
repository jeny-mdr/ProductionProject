import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _searchCtrl = TextEditingController();

  List<String> _allSymptoms    = [];
  List<String> _filtered       = [];
  final List<String> _selected = [];

  bool   _loadingSymptoms = true;
  bool   _loading         = false;
  bool   _showList        = false;
  bool   _gettingLocation = false;

  double _userLat        = 27.7172;
  double _userLng        = 85.3240;
  String _budget         = '1000';
  String _locationStatus = 'Tap to detect your location';

  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSymptoms();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSymptoms() async {
    final token = context.read<AuthProvider>().token;
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/api/ai/symptoms/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _allSymptoms     = List<String>.from(data['symptoms']);
          _filtered        = _allSymptoms;
          _loadingSymptoms = false;
        });
      } else {
        setState(() => _loadingSymptoms = false);
      }
    } catch (e) {
      setState(() => _loadingSymptoms = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _allSymptoms.where((s) => s.contains(q)).toList();
      _showList = q.isNotEmpty;
    });
  }

  void _addSymptom(String s) {
    final clean = s.trim().toLowerCase()
        .replaceAll(' ', '_');
    if (clean.isNotEmpty &&
        !_selected.contains(clean)) {
      setState(() {
        _selected.add(clean);
        _searchCtrl.clear();
        _showList    = false;
        _suggestions = [];
      });
      _getSuggestions();
    }
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Location permission denied. Enable in settings.';
          _gettingLocation = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _locationStatus =
        'Location detected ✓  (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
        _gettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Could not get location. Using Kathmandu default.';
        _gettingLocation = false;
      });
    }
  }

  List<String> _suggestions = [];

  Future<void> _getSuggestions() async {
    if (_selected.isEmpty) return;
    final token = context.read<AuthProvider>().token;
    try {
      final res = await http.post(
        Uri.parse(kSuggestUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'symptoms': _selected}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _suggestions = List<String>.from(
              data['suggestions'])
              .where((s) => !_selected.contains(s))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _analyse() async {
    if (_selected.length < 3) {
      setState(() => _error = 'Please select at least 3 symptoms');
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    final token = context.read<AuthProvider>().token;
    try {
      final res = await http.post(
        Uri.parse(kRecommendUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'symptoms': _selected,
          'lat':      _userLat,
          'lng':      _userLng,
          'budget':   double.tryParse(_budget) ?? 1000,
        }),
      );
      if (res.statusCode == 200) {
        setState(() { _result = jsonDecode(res.body); _loading = false; });
      } else {
        final err = jsonDecode(res.body);
        setState(() { _error = err['error'] ?? 'Server error ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Cannot reach server'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealioColors.bg,
      appBar: AppBar(
        title: const Text('AI Symptom Checker'),
        backgroundColor: HealioColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showList = false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C83E8), HealioColors.primary]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.psychology_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI-Powered Diagnosis',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 3),
                      Text('Search and select your symptoms for accurate results.',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.85))),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 24),

              // Symptom search
              Text('Search Symptoms',
                  style: GoogleFonts.poppins(fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: HealioColors.textDark)),
              const SizedBox(height: 8),

              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onTap: () => setState(
                            () => _showList = _searchCtrl.text.isNotEmpty),
                    decoration: InputDecoration(
                      hintText: _loadingSymptoms
                          ? 'Loading symptoms…'
                          : 'Type e.g. fever, headache…',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: HealioColors.primary),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: HealioColors.textLight),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _showList = false);
                          })
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _addSymptom(_searchCtrl.text),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(64, 52),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Add',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ]),

              // Dropdown list
              if (_showList && _filtered.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HealioColors.border),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length > 8 ? 8 : _filtered.length,
                    itemBuilder: (_, i) {
                      final s = _filtered[i];
                      final already = _selected.contains(s);
                      return ListTile(
                        dense: true,
                        title: Text(s.replaceAll('_', ' '),
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: already
                                    ? HealioColors.textLight
                                    : HealioColors.textDark)),
                        trailing: already
                            ? const Icon(Icons.check_rounded,
                            color: HealioColors.primary, size: 16)
                            : null,
                        onTap: already ? null : () => _addSymptom(s),
                      );
                    },
                  ),
                ),

              // Selected chips
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Selected (${_selected.length}):',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: HealioColors.textMid)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: _selected.map((s) => Chip(
                    label: Text(s.replaceAll('_', ' '),
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: HealioColors.primary)),
                    backgroundColor: HealioColors.primaryLight,
                    deleteIconColor: HealioColors.primary,
                    onDeleted: () => setState(
                            () => _selected.remove(s)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(
                            color: HealioColors.primaryMid)),
                  )).toList(),
                ),

                // Suggestions INSIDE selected block
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    const Icon(Icons.lightbulb_rounded,
                        color: HealioColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text('Did you also experience?',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: HealioColors.accent,
                        )),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: _suggestions.map((s) =>
                        GestureDetector(
                          onTap: () => _addSymptom(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: HealioColors.accentLight,
                              borderRadius:
                              BorderRadius.circular(20),
                              border: Border.all(
                                  color: HealioColors.accent
                                      .withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded,
                                    size: 14,
                                    color: HealioColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  s.replaceAll('_', ' '),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: HealioColors.accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ).toList(),
                  ),
                ],
              ],
              const SizedBox(height: 20),

              // Location
              Text('Location',
                  style: GoogleFonts.poppins(fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: HealioColors.textDark)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _gettingLocation ? null : _getLocation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: HealioColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HealioColors.primaryMid),
                  ),
                  child: Row(children: [
                    _gettingLocation
                        ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: HealioColors.primary, strokeWidth: 2.5))
                        : const Icon(Icons.my_location_rounded,
                        color: HealioColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_locationStatus,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: HealioColors.primary,
                              fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Budget
              Text('Budget',
                  style: GoogleFonts.poppins(fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: HealioColors.textDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: HealioColors.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HealioColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _budget,
                    isExpanded: true,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: HealioColors.textDark),
                    items: const [
                      DropdownMenuItem(value: '200',    child: Text('Under Rs.200')),
                      DropdownMenuItem(value: '300',   child: Text('Under Rs.300')),
                      DropdownMenuItem(value: '500',   child: Text('Under Rs.500')),
                      DropdownMenuItem(value: '1000',  child: Text('Under Rs.1000')),
                      DropdownMenuItem(value: '99999', child: Text('Any budget')),
                    ],
                    onChanged: (v) => setState(() => _budget = v!),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null) ...[
                ErrorBanner(_error!),
                const SizedBox(height: 16),
              ],

              ElevatedButton.icon(
                onPressed: _loading ? null : _analyse,
                icon: _loading
                    ? const BtnSpinner()
                    : const Icon(Icons.search_rounded),
                label: Text(
                  _loading ? 'Analysing…' : 'Analyse Symptoms',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),

              if (_result != null) ...[
                const SizedBox(height: 28),
                _Results(result: _result!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final Map<String, dynamic> result;
  const _Results({required this.result});

  @override
  Widget build(BuildContext context) {
    final isUncertain = result['predicted_disease'] == 'Uncertain';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(Icons.biotech_rounded, 'Predicted Condition',
            isUncertain ? HealioColors.accent : const Color(0xFF7C83E8)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUncertain
                ? HealioColors.accentLight : const Color(0xFFEEEFFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isUncertain
                    ? HealioColors.accent.withOpacity(0.3)
                    : const Color(0xFF7C83E8).withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result['predicted_disease'].toString(),
                  style: GoogleFonts.poppins(fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isUncertain
                          ? HealioColors.accent : const Color(0xFF4A50CC))),
              if (result['confidence'] != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: HealioColors.textLight),
                  const SizedBox(width: 4),
                  Text('Confidence: ${result['confidence']}%',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: HealioColors.textLight)),
                ]),
              ],

// Top 3 predictions
              if ((result['top_predictions'] as List?)?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text('Other Possibilities:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HealioColors.textMid,
                    )),
                const SizedBox(height: 6),
                ...(result['top_predictions'] as List)
                    .where((p) => p['disease'] != result['predicted_disease'])
                    .take(2)
                    .map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.arrow_right_rounded,
                        size: 16, color: HealioColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      '${p['disease']} (${p['confidence']}%)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: HealioColors.textMid,
                      ),
                    ),
                  ]),
                ))
                    .toList(),
              ],
              if (result['description'] != null) ...[
                const SizedBox(height: 8),
                Text(result['description'].toString(),
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: HealioColors.textMid, height: 1.5)),
              ],
              if (result['message'] != null) ...[
                const SizedBox(height: 8),
                Text(result['message'].toString(),
                    style: GoogleFonts.poppins(fontSize: 12,
                        color: HealioColors.accent,
                        fontWeight: FontWeight.w500)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        if ((result['precautions'] as List?)?.isNotEmpty == true) ...[
          _SectionHead(Icons.health_and_safety_rounded,
              'Precautions', HealioColors.primary),
          const SizedBox(height: 10),
          ...(result['precautions'] as List).map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 6, height: 6,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: const BoxDecoration(
                          color: HealioColors.primary, shape: BoxShape.circle)),
                  Expanded(child: Text(p.toString(),
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: HealioColors.textMid))),
                ]),
          )),
          const SizedBox(height: 16),
        ],

        _ListSection(
          icon: Icons.people_rounded, label: 'Recommended Doctors',
          color: HealioColors.primary,
          items: result['recommended_doctors'] as List? ?? [],
          builder: (d) => _InfoTile(
            title: 'Dr. ${((d['name'] ?? d['username'] ?? 'Unknown') as String).split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ')}',
            subtitle: d['specialization'] ?? '',
            icon: Icons.person_rounded,
            color: HealioColors.primary, iconBg: HealioColors.primaryLight,
            trailing: d['consultation_fee'] != null
                ? 'Rs.${d['consultation_fee']}' : null,
          ),
        ),

        _ListSection(
          icon: Icons.local_hospital_rounded, label: 'Nearby Hospitals',
          color: HealioColors.accent,
          items: result['nearby_hospitals'] as List? ?? [],
          builder: (h) => _InfoTile(
            title: h['name'] ?? 'Unknown', subtitle: h['address'] ?? '',
            icon: Icons.local_hospital_rounded,
            color: HealioColors.accent, iconBg: HealioColors.accentLight,
            trailing: h['distance_km'] != null
                ? '${h['distance_km']} km' : null,
            mapLink: h['map_link'],
          ),
        ),

        _ListSection(
          icon: Icons.medication_rounded, label: 'Nearby Pharmacies',
          color: const Color(0xFF4BAEC4),
          items: result['nearby_pharmacies'] as List? ?? [],
          builder: (p) => _InfoTile(
            title: p['name'] ?? 'Unknown', subtitle: p['address'] ?? '',
            icon: Icons.medication_rounded,
            color: const Color(0xFF4BAEC4),
            iconBg: const Color(0xFFE0F4F8),
            trailing: p['distance_km'] != null
                ? '${p['distance_km']} km' : null,
            mapLink: p['map_link'],
          ),
        ),
      ],
    );
  }
}

class _SectionHead extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _SectionHead(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 20), const SizedBox(width: 8),
    Text(label, style: GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w700, color: color)),
  ]);
}

class _ListSection extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  final List items; final Widget Function(dynamic) builder;
  const _ListSection({required this.icon, required this.label,
    required this.color, required this.items, required this.builder});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionHead(icon, label, color),
      const SizedBox(height: 10),
      ...items.map(builder),
      const SizedBox(height: 20),
    ]);
  }
}

class _InfoTile extends StatelessWidget {
  final String title, subtitle; final IconData icon;
  final Color color, iconBg; final String? trailing; final String? mapLink;
  const _InfoTile({required this.title, required this.subtitle,
    required this.icon, required this.color, required this.iconBg,
    this.trailing, this.mapLink});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: HealioColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HealioColors.border)),
    child: Row(children: [
      Container(width: 38, height: 38,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 14,
                fontWeight: FontWeight.w600, color: HealioColors.textDark)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.poppins(
                  fontSize: 12, color: HealioColors.textMid)),
            ],
          ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (trailing != null) Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Text(trailing!, style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ),
        if (mapLink != null) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(mapLink!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: HealioColors.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.map_rounded,
                    size: 12, color: HealioColors.primary),
                const SizedBox(width: 3),
                Text('Maps', style: GoogleFonts.poppins(
                    fontSize: 11, color: HealioColors.primary,
                    fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ]),
    ]),
  );
}