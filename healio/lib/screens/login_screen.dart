import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
        _userCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: HealioColors.primary,
      body: Column(
        children: [
          // Top green section with logo
          Expanded(
            flex: 2,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HealioLogo(size: 72),
                    const SizedBox(height: 16),
                    Text(
                      'Healio',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Smart care, wherever you are',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white
                            .withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // White rounded card bottom
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: HealioColors.bgCard,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                  28, 32, 28, 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back 👋',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: HealioColors.textDark,
                        )),
                    const SizedBox(height: 4),
                    Text('Sign in to your account',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: HealioColors.textMid,
                        )),
                    const SizedBox(height: 28),

                    // Username
                    Text('Username',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: HealioColors.textDark,
                        )),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _userCtrl,
                      decoration: InputDecoration(
                        hintText: 'your_username',
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: HealioColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Text('Password',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: HealioColors.textDark,
                        )),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: HealioColors.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons
                                .visibility_off_outlined,
                            color: HealioColors.textLight,
                          ),
                          onPressed: () => setState(
                                  () => _obscure = !_obscure),
                        ),
                      ),
                    ),

                    if (auth.error != null) ...[
                      const SizedBox(height: 14),
                      ErrorBanner(auth.error!),
                    ],

                    const SizedBox(height: 24),

                    // Sign in button
                    ElevatedButton(
                      onPressed:
                      auth.isLoading ? null : _login,
                      child: auth.isLoading
                          ? const BtnSpinner()
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 16),

                    // Register link
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: HealioColors.textMid,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            auth.clearError();
                            Navigator.pushNamed(
                                context, '/register');
                          },
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: HealioColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
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