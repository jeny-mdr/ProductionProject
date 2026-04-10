import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

// Fixed specialization list matching Django
const List<String> kSpecializations = [
  'General Physician',
  'Cardiologist',
  'Neurologist',
  'Dermatologist',
  'Pediatrician',
  'Orthopedist',
  'Gynecologist',
  'Pulmonologist',
  'Gastroenterologist',
  'Endocrinologist',
  'Ophthalmologist',
  'Psychiatrist',
  'Urologist',
  'Oncologist',
  'ENT Specialist',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _hospCtrl  = TextEditingController();
  final _feeCtrl   = TextEditingController();
  final _qualCtrl  = TextEditingController();
  final _bioCtrl   = TextEditingController();
  final _expCtrl   = TextEditingController();
  final _ageCtrl   = TextEditingController();

  String  _role        = 'patient';
  String? _spec        = 'General Physician';
  String  _gender      = 'male';
  bool    _obscure     = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _hospCtrl.dispose();
    _feeCtrl.dispose();
    _qualCtrl.dispose();
    _bioCtrl.dispose();
    _expCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    if (_userCtrl.text.trim().isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'username': _userCtrl.text.trim(),
      'password': _passCtrl.text,
      'role':     _role,
    };

    if (_emailCtrl.text.trim().isNotEmpty) {
      payload['email'] = _emailCtrl.text.trim();
    }

    if (_role == 'patient') {
      if (_ageCtrl.text.isNotEmpty) {
        payload['age'] = int.tryParse(_ageCtrl.text) ?? 0;
      }
      payload['gender']      = _gender;
      payload['patient_bio'] = _bioCtrl.text.trim();
    }

    if (_role == 'doctor') {
      payload['specialization']   = _spec;
      payload['hospital']         = _hospCtrl.text.trim();
      payload['consultation_fee'] =
          int.tryParse(_feeCtrl.text) ?? 0;
      payload['qualifications']   = _qualCtrl.text.trim();
      payload['doctor_bio']       = _bioCtrl.text.trim();
      if (_expCtrl.text.isNotEmpty) {
        payload['experience_years'] =
            int.tryParse(_expCtrl.text) ?? 0;
      }
    }

    final ok = await auth.register(payload);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _role == 'doctor'
                ? 'Account created! Await admin verification.'
                : 'Account created! Please sign in.',
          ),
          backgroundColor: HealioColors.success,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: HealioColors.primary,
      body: Column(
        children: [
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 20),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Create Account',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
              ]),
            ),
          ),

          // White card
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: HealioColors.bgCard,
                borderRadius: BorderRadius.only(
                  topLeft:  Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                  28, 28, 28, 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // Role picker
                    _Label('I am a'),
                    const SizedBox(height: 10),
                    Row(children: [
                      _RoleChip(
                        label: 'Patient',
                        icon: Icons.person_rounded,
                        selected: _role == 'patient',
                        onTap: () => setState(
                                () => _role = 'patient'),
                      ),
                      const SizedBox(width: 12),
                      _RoleChip(
                        label: 'Doctor',
                        icon: Icons.local_hospital_rounded,
                        selected: _role == 'doctor',
                        onTap: () => setState(
                                () => _role = 'doctor'),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Username
                    _Label('Username'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _userCtrl,
                      decoration: InputDecoration(
                        hintText: 'your_username',
                        prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: HealioColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Email
                    _Label(_role == 'doctor'
                        ? 'Email (required)'
                        : 'Email (optional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType:
                      TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'email@example.com',
                        prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: HealioColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password
                    _Label('Password'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: HealioColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: HealioColors.textLight,
                          ),
                          onPressed: () => setState(
                                  () => _obscure = !_obscure),
                        ),
                      ),
                    ),

                    // ── Patient fields ──────────────
                    if (_role == 'patient') ...[
                      const SizedBox(height: 14),
                      _Label('Age (optional)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '25',
                          prefixIcon: const Icon(
                              Icons.cake_outlined,
                              color: HealioColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Label('Gender'),
                      const SizedBox(height: 8),
                      _DropdownField(
                        value: _gender,
                        items: const [
                          'male', 'female', 'other'
                        ],
                        labels: const [
                          'Male', 'Female', 'Other'
                        ],
                        icon: Icons.people_outline_rounded,
                        onChanged: (v) =>
                            setState(() => _gender = v!),
                      ),
                      const SizedBox(height: 14),
                      _Label('Bio (optional)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bioCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                          'Tell us a bit about yourself…',
                          prefixIcon: const Icon(
                              Icons.info_outline_rounded,
                              color: HealioColors.primary),
                        ),
                      ),
                    ],

                    // ── Doctor fields ───────────────
                    if (_role == 'doctor') ...[
                      const SizedBox(height: 14),
                      _Label('Specialization'),
                      const SizedBox(height: 8),
                      _DropdownField(
                        value: _spec ?? 'General Physician',
                        items: kSpecializations,
                        labels: kSpecializations,
                        icon: Icons.science_outlined,
                        onChanged: (v) =>
                            setState(() => _spec = v),
                      ),
                      const SizedBox(height: 14),
                      _Label('Hospital / Clinic'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _hospCtrl,
                        decoration: InputDecoration(
                          hintText: 'Hospital name',
                          prefixIcon: const Icon(
                              Icons.local_hospital_outlined,
                              color: HealioColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Label('Qualifications'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _qualCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. MBBS, MD, PhD',
                          prefixIcon: const Icon(
                              Icons.school_outlined,
                              color: HealioColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Label('Years of Experience'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _expCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '5',
                          prefixIcon: const Icon(
                              Icons.work_outline_rounded,
                              color: HealioColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Label('Consultation Fee (Rs.)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _feeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '500',
                          prefixIcon: const Icon(
                              Icons.attach_money_rounded,
                              color: HealioColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Label('Bio / Description'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bioCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                          'Tell patients about yourself, your expertise…',
                          prefixIcon: const Icon(
                              Icons.info_outline_rounded,
                              color: HealioColors.primary),
                        ),
                      ),
                    ],

                    if (auth.error != null) ...[
                      const SizedBox(height: 14),
                      ErrorBanner(auth.error!),
                    ],

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : _register,
                      child: auth.isLoading
                          ? const BtnSpinner()
                          : const Text('Create Account'),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: HealioColors.textMid,
                            )),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pop(context),
                          child: Text('Sign In',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: HealioColors.primary,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: HealioColors.textDark,
      ));
}

class _DropdownField extends StatelessWidget {
  final String        value;
  final List<String>  items;
  final List<String>  labels;
  final IconData      icon;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.labels,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: HealioColors.bgInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HealioColors.border),
      ),
      child: Row(children: [
        Icon(icon, color: HealioColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: HealioColors.textDark,
              ),
              items: List.generate(
                items.length,
                    (i) => DropdownMenuItem(
                  value: items[i],
                  child: Text(labels[i]),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      ]),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String    label;
  final IconData  icon;
  final bool      selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? HealioColors.primary
              : HealioColors.bgInput,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? HealioColors.primary
                : HealioColors.border,
            width: 2,
          ),
        ),
        child: Column(children: [
          Icon(icon,
              color: selected
                  ? Colors.white
                  : HealioColors.textMid,
              size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : HealioColors.textMid,
              )),
        ]),
      ),
    ),
  );
}