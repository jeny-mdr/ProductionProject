import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editMode = false;

  // Edit controllers
  final _bioCtrl  = TextEditingController();
  final _ageCtrl  = TextEditingController();
  final _hospCtrl = TextEditingController();
  final _feeCtrl  = TextEditingController();
  final _qualCtrl = TextEditingController();
  final _expCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  File?  _pickedImage;
  File?  _pickedQr;
  bool   _saving = false;

  @override
  void dispose() {
    _bioCtrl.dispose();
    _ageCtrl.dispose();
    _hospCtrl.dispose();
    _feeCtrl.dispose();
    _qualCtrl.dispose();
    _expCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _startEdit(Map<String, dynamic> user, String role) {
    _bioCtrl.text  = user['bio'] ?? '';
    _qualCtrl.text = user['qualifications'] ?? '';
    _expCtrl.text  = user['experience_years']?.toString() ?? '';
    _ageCtrl.text  = user['age']?.toString() ?? '';
    _hospCtrl.text = user['hospital'] ?? '';
    _feeCtrl.text  = user['consultation_fee']?.toString() ?? '';
    _emailCtrl.text = user['email'] ?? '';
    setState(() => _editMode = true);
  }

  Future<void> _verifyBlockchain() async {
    final auth  = context.read<AuthProvider>();
    final token = auth.token ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(
              color: HealioColors.primary),
          SizedBox(width: 16),
          Text('Verifying blockchain...'),
        ]),
      ),
    );

    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/api/blockchain/verify/mine/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) Navigator.pop(context);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final valid  = data['valid'] as bool;
        final total  = data['total_blocks'] ?? 0;

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  valid
                      ? Icons.verified_rounded
                      : Icons.warning_rounded,
                  color: valid
                      ? HealioColors.success
                      : HealioColors.error,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  valid
                      ? 'Blockchain Verified!'
                      : 'Tampering Detected!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: valid
                        ? HealioColors.success
                        : HealioColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  valid
                      ? 'Your records are verified\nand tamper-proof.'
                      : data['message'] ?? 'Records may have been tampered with.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: HealioColors.textMid,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK',
                    style: GoogleFonts.poppins(
                      color: HealioColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickImage(bool isQr) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        if (isQr) {
          _pickedQr = File(picked.path);
        } else {
          _pickedImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _saveProfile(
      String token, String role) async {
    setState(() => _saving = true);
    try {
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse(kProfileUrl),
      );
      request.headers['Authorization'] =
      'Bearer $token';

      // Add text fields
      if (role == 'patient') {
        if (_ageCtrl.text.isNotEmpty) {
          request.fields['age'] = _ageCtrl.text;
        }
        request.fields['bio'] = _bioCtrl.text;
      } else {
        request.fields['bio']          = _bioCtrl.text;
        request.fields['qualifications'] = _qualCtrl.text;
        request.fields['hospital']     = _hospCtrl.text;
        if (_feeCtrl.text.isNotEmpty) {
          request.fields['consultation_fee'] =
              _feeCtrl.text;
        }
        if (_expCtrl.text.isNotEmpty) {
          request.fields['experience_years'] =
              _expCtrl.text;
        }
        if (_emailCtrl.text.isNotEmpty) {
          request.fields['email'] = _emailCtrl.text;
        }
      }

      // Add profile picture
      if (_pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            _pickedImage!.path,
          ),
        );
      }

      // Add QR code (doctor only)
      if (_pickedQr != null && role == 'doctor') {
        request.files.add(
          await http.MultipartFile.fromPath(
            'payment_qr',
            _pickedQr!.path,
          ),
        );
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        // Refresh profile data
        if (mounted) {
          await context
              .read<AuthProvider>()
              .fetchProfile();
          setState(() {
            _editMode    = false;
            _saving      = false;
            _pickedImage = null;
            _pickedQr    = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: HealioColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              content: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Profile updated!',
                    style: GoogleFonts.poppins(
                        color: Colors.white)),
              ]),
            ),
          );
        }
      } else {
        setState(() => _saving = false);
      }
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final user  = auth.user ?? {};
    final name  = user['username'] ?? 'User';
    final role  = user['role'] ?? 'patient';
    final token = auth.token ?? '';

    final profilePicUrl =
    user['profile_picture'] as String?;
    final paymentQrUrl =
    user['payment_qr'] as String?;

    return Scaffold(
      backgroundColor: HealioColors.bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────
          Container(
            color: HealioColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    22, 16, 22, 28),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white),
                    onPressed: () =>
                        Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text('My Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                  ),
                  if (!_editMode)
                    TextButton(
                      onPressed: () =>
                          _startEdit(user, role),
                      child: Text('Edit',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ),
                  if (_editMode)
                    TextButton(
                      onPressed: () => setState(
                              () => _editMode = false),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white
                                .withOpacity(0.8),
                          )),
                    ),
                  TextButton(
                    onPressed: () {
                      auth.logout();
                      Navigator.pushReplacementNamed(
                          context, '/login');
                    },
                    child: Text('Sign Out',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white
                              .withOpacity(0.9),
                        )),
                  ),
                ]),
              ),
            ),
          ),

          // ── Body ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Avatar section
                  Container(
                    color: HealioColors.primary,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: HealioColors.bg,
                        borderRadius: BorderRadius.only(
                          topLeft:  Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      padding: const EdgeInsets.only(
                          top: 28),
                      child: Column(children: [
                        // Profile picture
                        GestureDetector(
                          onTap: _editMode
                              ? () => _pickImage(false)
                              : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor:
                                HealioColors.primaryLight,
                                backgroundImage:
                                _pickedImage != null
                                    ? FileImage(_pickedImage!)
                                    : null,
                                child: _pickedImage == null
                                    ? (profilePicUrl != null &&
                                    profilePicUrl
                                        .isNotEmpty
                                    ? ClipOval(
                                  child:
                                  CachedNetworkImage(
                                    imageUrl:
                                    profilePicUrl,
                                    width: 92,
                                    height: 92,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _avatarText(name),
                                  ),
                                )
                                    : _avatarText(name))
                                    : null,
                              ),
                              if (_editMode)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color:
                                      HealioColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white,
                                          width: 2),
                                    ),
                                    child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 14),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          role == 'doctor'
                              ? 'Dr. $name'
                              : name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: HealioColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4),
                          decoration: BoxDecoration(
                            color: HealioColors.primaryLight,
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: HealioColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ]),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // ── View mode ──────────────
                        if (!_editMode) ...[
                          _InfoCard(
                            children: [
                              if ((user['email'] ?? '')
                                  .isNotEmpty)
                                _InfoRow(
                                    Icons.email_outlined,
                                    'Email',
                                    user['email']),
                              if (role == 'doctor') ...[
                                _InfoRow(
                                    Icons.science_outlined,
                                    'Specialization',
                                    user['specialization'] ??
                                        ''),
                                _InfoRow(
                                    Icons
                                        .local_hospital_outlined,
                                    'Hospital',
                                    user['hospital'] ?? ''),
                                _InfoRow(
                                    Icons
                                        .attach_money_rounded,
                                    'Consultation Fee',
                                    'Rs. ${user['consultation_fee'] ?? 0}'),
                                if ((user['experience_years'] ??
                                    0) >
                                    0)
                                  _InfoRow(
                                      Icons.work_outline_rounded,
                                      'Experience',
                                      '${user['experience_years']} years'),
                                if ((user['qualifications'] ??
                                    '')
                                    .isNotEmpty)
                                  _InfoRow(
                                      Icons.school_outlined,
                                      'Qualifications',
                                      user['qualifications']),
                                if ((user['bio'] ?? '')
                                    .isNotEmpty)
                                  _InfoRow(
                                      Icons
                                          .info_outline_rounded,
                                      'Bio',
                                      user['bio']),
                                _InfoRow(
                                    Icons.verified_rounded,
                                    'Status',
                                    user['is_verified'] == true
                                        ? 'Verified ✓'
                                        : 'Pending Verification'),
                              ] else ...[
                                if (user['age'] != null)
                                  _InfoRow(
                                      Icons.cake_outlined,
                                      'Age',
                                      '${user['age']} years'),
                                if ((user['gender'] ?? '')
                                    .isNotEmpty)
                                  _InfoRow(
                                      Icons
                                          .people_outline_rounded,
                                      'Gender',
                                      user['gender']
                                          .toString()
                                          .capitalizeFirst()),
                                if ((user['bio'] ?? '')
                                    .isNotEmpty)
                                  _InfoRow(
                                      Icons
                                          .info_outline_rounded,
                                      'Bio',
                                      user['bio']),
                              ],
                            ],
                          ),

                          // Payment QR — doctor view
                          if (role == 'doctor') ...[
                            const SizedBox(height: 20),
                            Text('Payment QR Code',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: HealioColors.textDark,
                                )),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding:
                              const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: HealioColors.bgCard,
                                borderRadius:
                                BorderRadius.circular(16),
                                border: Border.all(
                                    color: HealioColors.border),
                              ),
                              child: paymentQrUrl != null &&
                                  paymentQrUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl: paymentQrUrl,
                                height: 180,
                                fit: BoxFit.contain,
                              )
                                  : Column(children: [
                                const Icon(
                                    Icons.qr_code_rounded,
                                    size: 60,
                                    color: HealioColors
                                        .textLight),
                                const SizedBox(height: 8),
                                Text(
                                  'No QR code uploaded yet.\nTap Edit to add your payment QR.',
                                  textAlign:
                                  TextAlign.center,
                                  style:
                                  GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: HealioColors
                                        .textLight,
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ],

                        // ── Edit mode ──────────────
                        if (_editMode) ...[
                          Text('Edit Profile',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: HealioColors.textDark,
                              )),
                          const SizedBox(height: 16),

                          if (role == 'patient') ...[
                            _EditField(
                              label: 'Age',
                              ctrl: _ageCtrl,
                              icon: Icons.cake_outlined,
                              keyboardType:
                              TextInputType.number,
                            ),
                            const SizedBox(height: 14),
                            _EditField(
                              label: 'Bio',
                              ctrl: _bioCtrl,
                              icon: Icons.info_outline_rounded,
                              maxLines: 3,
                            ),
                            _EditField(
                              label: 'Email',
                              ctrl: _emailCtrl,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                          ],

                          if (role == 'doctor') ...[
                            _EditField(
                              label: 'Hospital / Clinic',
                              ctrl: _hospCtrl,
                              icon: Icons
                                  .local_hospital_outlined,
                            ),
                            const SizedBox(height: 14),
                            _EditField(
                              label: 'Consultation Fee (Rs.)',
                              ctrl: _feeCtrl,
                              icon:
                              Icons.attach_money_rounded,
                              keyboardType:
                              TextInputType.number,
                            ),
                            const SizedBox(height: 14),
                            _EditField(
                              label: 'Qualifications',
                              ctrl: _qualCtrl,
                              icon: Icons.school_outlined,
                            ),
                            const SizedBox(height: 14),
                            _EditField(
                              label: 'Years of Experience',
                              ctrl: _expCtrl,
                              icon:
                              Icons.work_outline_rounded,
                              keyboardType:
                              TextInputType.number,
                            ),
                            const SizedBox(height: 14),
                            _EditField(
                              label: 'Bio / Description',
                              ctrl: _bioCtrl,
                              icon: Icons.info_outline_rounded,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 20),

                            // QR upload
                            Text('Payment QR Code',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: HealioColors.textDark,
                                )),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _pickImage(true),
                              child: Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: HealioColors.bgInput,
                                  borderRadius:
                                  BorderRadius.circular(
                                      14),
                                  border: Border.all(
                                    color:
                                    HealioColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: _pickedQr != null
                                    ? ClipRRect(
                                  borderRadius:
                                  BorderRadius
                                      .circular(12),
                                  child: Image.file(
                                    _pickedQr!,
                                    fit: BoxFit.contain,
                                  ),
                                )
                                    : Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                                  children: [
                                    const Icon(
                                        Icons
                                            .qr_code_rounded,
                                        size: 40,
                                        color: HealioColors
                                            .primary),
                                    const SizedBox(
                                        height: 8),
                                    Text(
                                      'Tap to upload QR code',
                                      style: GoogleFonts
                                          .poppins(
                                        fontSize: 13,
                                        color: HealioColors
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _saving
                                  ? null
                                  : () => _saveProfile(
                                  token, role),
                              child: _saving
                                  ? const BtnSpinner()
                                  : Text(
                                'Save Changes',
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

                        // Verify blockchain button
                        if (!_editMode) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _verifyBlockchain,
                              icon: const Icon(
                                  Icons.verified_rounded,
                                  size: 18),
                              label: Text(
                                'Verify Blockchain Records',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                HealioColors.primaryDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],

                       // ── Prescriptions (patient) ─
                        if (!_editMode &&
                            role == 'patient') ...[
                          const SizedBox(height: 24),
                          _PrescriptionsSection(token: token),
                        ],

                        // ── Prescriptions (patient) ─
                        if (!_editMode &&
                            role == 'patient') ...[
                          const SizedBox(height: 24),
                          _PrescriptionsSection(
                              token: token),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarText(String name) => Text(
    name[0].toUpperCase(),
    style: GoogleFonts.poppins(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: HealioColors.primary,
    ),
  );
}

// ── Reusable widgets ─────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: HealioColors.bgCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HealioColors.border),
      boxShadow: [
        BoxShadow(
          color: HealioColors.primary.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final dynamic  value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14),
    decoration: const BoxDecoration(
      border: Border(
          bottom:
          BorderSide(color: HealioColors.border)),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: HealioColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: HealioColors.primary, size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: HealioColors.textLight,
                  fontWeight: FontWeight.w500,
                )),
            const SizedBox(height: 2),
            Text(value?.toString() ?? '',
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

class _EditField extends StatelessWidget {
  final String         label;
  final TextEditingController ctrl;
  final IconData       icon;
  final int            maxLines;
  final TextInputType  keyboardType;

  const _EditField({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.maxLines    = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: HealioColors.textDark,
          )),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon,
              color: HealioColors.primary),
        ),
      ),
    ],
  );
}

// ── Prescriptions section ────────────────────────────
class _PrescriptionsSection extends StatefulWidget {
  final String token;
  const _PrescriptionsSection({required this.token});

  @override
  State<_PrescriptionsSection> createState() =>
      _PrescriptionsSectionState();
}

class _PrescriptionsSectionState
    extends State<_PrescriptionsSection> {
  List<dynamic> _records = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse(kMyPrescriptionsUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}'
        },
      );
      if (res.statusCode == 200) {
        setState(() {
          _records = jsonDecode(res.body);
          _loading = false;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.medical_services_rounded,
              color: HealioColors.primary, size: 18),
          const SizedBox(width: 8),
          Text('My Prescriptions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: HealioColors.textDark,
              )),
        ]),
        const SizedBox(height: 12),
        if (_loading)
          const Center(
              child: CircularProgressIndicator(
                  color: HealioColors.primary))
        else if (_records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HealioColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border:
              Border.all(color: HealioColors.border),
            ),
            child: Text(
              'No prescriptions yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: HealioColors.textLight),
            ),
          )
        else
          ...(_records.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HealioColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: HealioColors.primary
                      .withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: HealioColors.primary
                      .withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.verified_rounded,
                      color: HealioColors.primary,
                      size: 16),
                  const SizedBox(width: 6),
                  Text('Blockchain Verified',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: HealioColors.primary,
                      )),
                  const Spacer(),
                  Text(
                        () {
                      final dt = DateTime.parse(
                          r['created_at'])
                          .toLocal();
                      return '${dt.day}/${dt.month}/${dt.year}';
                    }(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: HealioColors.textLight,
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Text('Dr. ${r['doctor_name']}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: HealioColors.textDark,
                    )),
                const SizedBox(height: 6),
                Text(r['data'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: HealioColors.textMid,
                      height: 1.4,
                    )),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: HealioColors.bg,
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text('Block Hash',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color:
                            HealioColors.textLight,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        r['block_hash'],
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: HealioColors.textMid,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ))),
      ],
    );
  }
}

// ── String extension ─────────────────────────────────
extension StringExtension on String {
  String capitalizeFirst() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}