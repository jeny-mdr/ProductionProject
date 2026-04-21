import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState
    extends State<DoctorProfileScreen> {
  // Appointment booking
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _reasonCtrl = TextEditingController();
  bool _booking = false;
  bool _booked  = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(
          const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
          const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: HealioColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(
          hour: 10, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: HealioColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select date and time'),
          backgroundColor: HealioColors.error,
        ),
      );
      return;
    }

    setState(() => _booking = true);
    final auth  = context.read<AuthProvider>();
    final token = auth.token ?? '';

    final dateStr =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

    try {
      final res = await http.post(
        Uri.parse(kBookAppointmentUrl),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'doctor_id': widget.doctor['id'],
          'date':      dateStr,
          'time':      timeStr,
          'reason':    _reasonCtrl.text.trim(),
        }),
      );

      if (res.statusCode == 201) {
        setState(() {
          _booking = false;
          _booked  = true;
        });
        _showBookingSuccess();
      } else {
        final err = jsonDecode(res.body);
        setState(() => _booking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                err['error'] ?? 'Booking failed'),
            backgroundColor: HealioColors.error,
          ),
        );
      }
    } catch (_) {
      setState(() => _booking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error'),
          backgroundColor: HealioColors.error,
        ),
      );
    }
  }

  void _showBookingSuccess() {
    final doctor   = widget.doctor;
    final name     = doctor['username'] ?? '';
    final fee      = doctor['consultation_fee'] ?? 0;
    final qrUrl    = doctor['payment_qr'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context)
              .padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: HealioColors.bgCard,
          borderRadius: BorderRadius.only(
            topLeft:  Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: HealioColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Success icon
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                color: HealioColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                  Icons.check_circle_rounded,
                  color: HealioColors.primary,
                  size: 40),
            ),
            const SizedBox(height: 16),
            Text('Appointment Booked!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: HealioColors.textDark,
                )),
            const SizedBox(height: 6),
            Text(
              'Dr. $name — $_dateStr at $_timeStr',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: HealioColors.textMid,
              ),
            ),
            const SizedBox(height: 24),

            // Payment section
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HealioColors.bg,
                    borderRadius:
                    BorderRadius.circular(16),
                    border: Border.all(
                        color: HealioColors.border),
                  ),
                  child: Column(children: [
                    Row(children: [
                      const Icon(
                          Icons.payment_rounded,
                          color: HealioColors.primary,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Pay Consultation Fee',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: HealioColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Rs. $fee',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: HealioColors.primary,
                        ),
                      ),
                    ]),
                    if (qrUrl != null &&
                        qrUrl.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Scan QR to pay',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: HealioColors.textMid,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: qrUrl,
                          height: 180,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) =>
                          const Icon(
                              Icons.qr_code_rounded,
                              size: 80,
                              color: HealioColors
                                  .textLight),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Text(
                        'Pay at the clinic on your appointment day.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: HealioColors.textMid,
                        ),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    child: Text('Done',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String get _dateStr => _selectedDate == null
      ? 'Not selected'
      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';

  String get _timeStr => _selectedTime == null
      ? 'Not selected'
      : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final doctor  = widget.doctor;
    final name    = doctor['username'] ?? 'Unknown';
    final spec    = doctor['specialization'] ?? '';
    final hosp    = doctor['hospital'] ?? '';
    final fee     = doctor['consultation_fee'] ?? 0;
    final bio     = doctor['bio'] ?? '';
    final qual    = doctor['qualifications'] ?? '';
    final exp     = doctor['experience_years'];
    final picUrl  = doctor['profile_picture']
    as String?;
    final doctorId = doctor['id']?.toString() ?? '0';
    final auth    = context.read<AuthProvider>();
    final isDoc   = auth.isDoctor;

    return Scaffold(
      backgroundColor: HealioColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: HealioColors.primary,
            leading: IconButton(
              icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white),
              onPressed: () =>
                  Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: HealioColors.primary,
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white
                          .withOpacity(0.25),
                      backgroundImage:
                      picUrl != null &&
                          picUrl.isNotEmpty
                          ? CachedNetworkImageProvider(
                          picUrl)
                          : null,
                      child: picUrl == null ||
                          picUrl.isEmpty
                          ? Text(
                        name[0].toUpperCase(),
                        style:
                        GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight:
                          FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dr. $name',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      spec,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white
                            .withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(children: [
                    _StatCard(
                      icon: Icons.work_outline_rounded,
                      label: 'Experience',
                      value: exp != null
                          ? '${exp}y'
                          : 'N/A',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons
                          .attach_money_rounded,
                      label: 'Fee',
                      value: 'Rs.$fee',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.verified_rounded,
                      label: 'Status',
                      value: 'Verified',
                      valueColor:
                      HealioColors.success,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Info card
                  _SectionCard(children: [
                    if (hosp.isNotEmpty)
                      _DetailRow(
                          Icons
                              .local_hospital_outlined,
                          'Hospital',
                          hosp),
                    if (qual.isNotEmpty)
                      _DetailRow(
                          Icons.school_outlined,
                          'Qualifications',
                          qual),
                    if ((doctor['email'] ?? '')
                        .isNotEmpty)
                      _DetailRow(
                          Icons.email_outlined,
                          'Email',
                          doctor['email']),
                  ]),

                  // Bio
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('About',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: HealioColors.textDark,
                        )),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: HealioColors.bgCard,
                        borderRadius:
                        BorderRadius.circular(16),
                        border: Border.all(
                            color:
                            HealioColors.border),
                      ),
                      child: Text(bio,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color:
                            HealioColors.textMid,
                            height: 1.6,
                          )),
                    ),
                  ],

                  // Book appointment (patient only)
                  if (!isDoc) ...[
                    const SizedBox(height: 24),
                    Text('Book Appointment',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: HealioColors.textDark,
                        )),
                    const SizedBox(height: 12),

                    // Date + Time
                    Row(children: [
                      Expanded(
                        child: _PickerButton(
                          icon: Icons
                              .calendar_today_rounded,
                          label: _dateStr,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PickerButton(
                          icon: Icons
                              .access_time_rounded,
                          label: _timeStr,
                          onTap: _pickTime,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // Reason
                    TextField(
                      controller: _reasonCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                        'Reason for visit (optional)…',
                        prefixIcon: const Icon(
                            Icons.note_outlined,
                            color:
                            HealioColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Book button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _booking
                            ? null
                            : _bookAppointment,
                        child: _booking
                            ? const BtnSpinner()
                            : Text(
                          'Book Appointment',
                          style:
                          GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom buttons
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 12,
          bottom: MediaQuery.of(context)
              .padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: HealioColors.bgCard,
          border: const Border(
            top: BorderSide(
                color: HealioColors.border),
          ),
        ),
        child: Row(children: [
          // Chat button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(
                    context, '/chat',
                    arguments: {
                      'otherUserId':   doctorId,
                      'otherUsername': name,
                      'otherName':     name,
                      'otherPicUrl':   picUrl,
                    },
                  ),
              icon: const Icon(
                  Icons.chat_bubble_rounded,
                  size: 18),
              label: Text('Chat',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  )),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                HealioColors.primary,
                side: const BorderSide(
                    color: HealioColors.primary),
                minimumSize:
                const Size(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (!isDoc) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Scroll to booking section
                },
                icon: const Icon(
                    Icons.calendar_month_rounded,
                    size: 18),
                label: Text('Book',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    )),
                style: ElevatedButton.styleFrom(
                  minimumSize:
                  const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Helper widgets ───────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = HealioColors.textDark,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
          vertical: 14),
      decoration: BoxDecoration(
        color: HealioColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: HealioColors.border),
      ),
      child: Column(children: [
        Icon(icon,
            color: HealioColors.primary,
            size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            )),
        Text(label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: HealioColors.textLight,
            )),
      ]),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: HealioColors.bgCard,
      borderRadius: BorderRadius.circular(16),
      border:
      Border.all(color: HealioColors.border),
    ),
    child: Column(children: children),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _DetailRow(this.icon, this.label,
      this.value);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14),
    decoration: const BoxDecoration(
      border: Border(
          bottom: BorderSide(
              color: HealioColors.border)),
    ),
    child: Row(children: [
      Icon(icon,
          color: HealioColors.primary,
          size: 18),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: HealioColors.textLight,
                )),
            Text(value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HealioColors.textDark,
                )),
          ],
        ),
      ),
    ]),
  );
}

class _PickerButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: HealioColors.bgInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: HealioColors.border),
          ),
          child: Row(children: [
            Icon(icon,
                color: HealioColors.primary,
                size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: HealioColors.textDark,
                  )),
            ),
          ]),
        ),
      );
}