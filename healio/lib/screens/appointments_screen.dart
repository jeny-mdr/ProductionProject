import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() =>
      _AppointmentsScreenState();
}

class _AppointmentsScreenState
    extends State<AppointmentsScreen> {
  List<dynamic> _appointments = [];
  bool          _loading      = true;
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
      final res = await http.get(
        Uri.parse(kMyAppointmentsUrl),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );
      if (res.statusCode == 200) {
        setState(() {
          _appointments = jsonDecode(res.body);
          _loading      = false;
        });
      } else {
        setState(() {
          _error   = 'Server error ${res.statusCode}';
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

  Future<void> _updateStatus(
      int id, String status) async {
    final token =
        context.read<AuthProvider>().token;
    try {
      final res = await http.patch(
        Uri.parse(kUpdateAppointmentUrl(id)),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );
      if (res.statusCode == 200) {
        _fetch();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(
            content: Text(
                'Appointment $status!'),
            backgroundColor:
            HealioColors.success,
            behavior:
            SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                    12)),
          ));
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final role  = auth.user?['role'] ?? 'patient';
    final isDoc = role == 'doctor';

    return Scaffold(
      backgroundColor: HealioColors.bg,
      appBar: AppBar(
        title: const Text('Appointments'),
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
        actions: [
          IconButton(
            icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white),
            onPressed: _fetch,
          ),
        ],
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(
              color: HealioColors.primary))
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: HealioColors
                    .textLight),
            const SizedBox(height: 12),
            Text(_error!,
                style: GoogleFonts.poppins(
                    color: HealioColors
                        .textMid)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetch,
              child:
              const Text('Retry'),
            ),
          ],
        ),
      )
          : _appointments.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Icon(
              Icons
                  .calendar_month_rounded,
              size: 72,
              color: HealioColors
                  .primaryMid,
            ),
            const SizedBox(
                height: 16),
            Text(
              'No appointments yet',
              style:
              GoogleFonts.poppins(
                fontSize: 16,
                fontWeight:
                FontWeight.w600,
                color: HealioColors
                    .textMid,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isDoc
                  ? 'Patients will book appointments with you'
                  : 'Book an appointment with a doctor',
              style:
              GoogleFonts.poppins(
                fontSize: 13,
                color: HealioColors
                    .textLight,
              ),
              textAlign:
              TextAlign.center,
            ),
          ],
        ),
      )
          : RefreshIndicator(
        color: HealioColors.primary,
        onRefresh: _fetch,
        child: ListView.builder(
          padding:
          const EdgeInsets.all(
              16),
          itemCount:
          _appointments.length,
          itemBuilder: (_, i) =>
              _AppointmentCard(
                appointment:
                _appointments[i],
                isDoctor: isDoc,
                onUpdateStatus:
                _updateStatus,
              ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final bool                 isDoctor;
  final Function(int, String) onUpdateStatus;

  const _AppointmentCard({
    required this.appointment,
    required this.isDoctor,
    required this.onUpdateStatus,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return HealioColors.success;
      case 'cancelled':
        return HealioColors.error;
      case 'completed':
        return HealioColors.primary;
      default:
        return HealioColors.accent;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id          = appointment['id'] as int;
    final status      = appointment['status']
    as String? ??
        'pending';
    final date        =
        appointment['date'] as String? ?? '';
    final time        =
        appointment['time'] as String? ?? '';
    final reason      =
        appointment['reason'] as String? ?? '';
    final docName     =
        appointment['doctor_name'] as String? ??
            '';
    final patName     =
        appointment['patient_name']
        as String? ??
            '';
    final spec        =
        appointment['doctor_specialization']
        as String? ??
            '';
    final hosp        =
        appointment['doctor_hospital']
        as String? ??
            '';

    // Format date
    String dateLabel = date;
    try {
      final dt = DateTime.parse(date);
      dateLabel =
      '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {}

    // Format time
    String timeLabel = time;
    try {
      final parts = time.split(':');
      timeLabel =
      '${parts[0]}:${parts[1]}';
    } catch (_) {}

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: HealioColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border:
        Border.all(color: HealioColors.border),
        boxShadow: [
          BoxShadow(
            color: HealioColors.primary
                .withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(children: [
              Icon(_statusIcon(status),
                  color: statusColor, size: 18),
              const SizedBox(width: 8),
              Text(
                status.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              // Date + time
              Row(children: [
                const Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: HealioColors.textLight),
                const SizedBox(width: 4),
                Text(dateLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: HealioColors.textMid,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(width: 10),
                const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: HealioColors.textLight),
                const SizedBox(width: 4),
                Text(timeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: HealioColors.textMid,
                      fontWeight: FontWeight.w500,
                    )),
              ]),
            ]),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // Person name
                Row(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                    HealioColors.primaryLight,
                    child: Text(
                      isDoctor
                          ? (patName.isNotEmpty
                          ? patName[0]
                          .toUpperCase()
                          : 'P')
                          : (docName.isNotEmpty
                          ? docName[0]
                          .toUpperCase()
                          : 'D'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: HealioColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDoctor
                              ? patName
                              : 'Dr. ${docName[0].toUpperCase()}${docName.substring(1)}',
                          style:
                          GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            HealioColors.textDark,
                          ),
                        ),
                        if (!isDoctor &&
                            spec.isNotEmpty)
                          Text(spec,
                              style:
                              GoogleFonts.poppins(
                                fontSize: 12,
                                color: HealioColors
                                    .textMid,
                              )),
                        if (!isDoctor &&
                            hosp.isNotEmpty)
                          Text(hosp,
                              style:
                              GoogleFonts.poppins(
                                fontSize: 11,
                                color: HealioColors
                                    .textLight,
                              )),
                      ],
                    ),
                  ),
                ]),

                // Reason
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HealioColors.bg,
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(
                          Icons.note_outlined,
                          size: 14,
                          color:
                          HealioColors.textLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(reason,
                            style:
                            GoogleFonts.poppins(
                              fontSize: 12,
                              color:
                              HealioColors.textMid,
                            )),
                      ),
                    ]),
                  ),
                ],

                // Doctor action buttons
                if (isDoctor &&
                    status == 'pending') ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            onUpdateStatus(
                                id, 'cancelled'),
                        style: OutlinedButton
                            .styleFrom(
                          foregroundColor:
                          HealioColors.error,
                          side: const BorderSide(
                              color:
                              HealioColors.error),
                          minimumSize:
                          const Size(0, 42),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                10),
                          ),
                        ),
                        child: Text('Decline',
                            style:
                            GoogleFonts.poppins(
                              fontWeight:
                              FontWeight.w600,
                              fontSize: 13,
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            onUpdateStatus(
                                id, 'confirmed'),
                        style: ElevatedButton
                            .styleFrom(
                          minimumSize:
                          const Size(0, 42),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                10),
                          ),
                        ),
                        child: Text('Confirm',
                            style:
                            GoogleFonts.poppins(
                              fontWeight:
                              FontWeight.w600,
                              fontSize: 13,
                            )),
                      ),
                    ),
                  ]),
                ],

                if (isDoctor &&
                    status == 'confirmed') ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          onUpdateStatus(
                              id, 'completed'),
                      style:
                      ElevatedButton.styleFrom(
                        minimumSize:
                        const Size(0, 42),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              10),
                        ),
                      ),
                      child: Text(
                          'Mark as Completed',
                          style: GoogleFonts.poppins(
                            fontWeight:
                            FontWeight.w600,
                            fontSize: 13,
                          )),
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
}