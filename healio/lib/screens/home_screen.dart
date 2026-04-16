import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnread();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUnread();
  }

  Future<void> _fetchUnread() async {
    final token =
        context.read<AuthProvider>().token;
    try {
      final res = await http.get(
        Uri.parse(kChatRoomsUrl),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );
      if (res.statusCode == 200) {
        final rooms = List<dynamic>.from(
            jsonDecode(res.body));
        int total = 0;
        for (final r in rooms) {
          total +=
          (r['unread_count'] as int? ?? 0);
        }
        setState(() => _unreadCount = total);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name =
        user?['username'] ?? 'Friend';
    final role =
        user?['role'] ?? 'patient';

    return Scaffold(
      backgroundColor: HealioColors.bg,
      body: Column(
        children: [
          // Green header
          Container(
            color: HealioColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(
                    22, 16, 22, 24),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              'Hello, $name 👋',
                              style:
                              GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight:
                                FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role == 'doctor'
                                  ? 'Doctor Dashboard'
                                  : 'How are you feeling today?',
                              style:
                              GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white
                                    .withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _showLogout(context),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor:
                          Colors.white
                              .withOpacity(0.25),
                          child: Text(
                            name[0].toUpperCase(),
                            style:
                            GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Search bar
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(
                              context, '/search'),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.2),
                          borderRadius:
                          BorderRadius.circular(
                              12),
                        ),
                        child: Row(children: [
                          const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 20),
                          const SizedBox(width: 10),
                          Text(
                            role == 'doctor'
                                ? 'Search patients or appointments…'
                                : 'Search doctors or symptoms…',
                            style:
                            GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white
                                  .withOpacity(0.8),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text('Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: HealioColors.textDark,
                      )),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                    children: [
                      if (role == 'doctor') ...[
                        _ActionCard(
                          icon: Icons
                              .people_alt_rounded,
                          label: 'My\nPatients',
                          color:
                          HealioColors.primary,
                          iconBg: HealioColors
                              .primaryLight,
                          onTap: () =>
                              Navigator.pushNamed(
                                  context, '/chats'),
                        ),
                        _ActionCard(
                          icon: Icons
                              .calendar_month_rounded,
                          label: 'My\nAppointments',
                          color: const Color(
                              0xFF7C83E8),
                          iconBg: const Color(
                              0xFFEEEFFC),
                          onTap: () =>
                              Navigator.pushNamed(
                                  context,
                                  '/appointments'),
                        ),
                        _ActionCard(
                          icon: Icons
                              .chat_bubble_rounded,
                          label: 'My\nChats',
                          color: const Color(
                              0xFF4BAEC4),
                          iconBg: const Color(
                              0xFFE0F4F8),
                          onTap: () =>
                              Navigator.pushNamed(
                                  context, '/chats'),
                        ),
                        _ActionCard(
                          icon: Icons
                              .account_circle_rounded,
                          label: 'My\nProfile',
                          color: HealioColors.accent,
                          iconBg:
                          HealioColors.accentLight,
                          onTap: () =>
                              Navigator.pushNamed(
                                  context, '/profile'),
                        ),
                      ] else ...[
                        _ActionCard(
                          icon: Icons
                              .psychology_rounded,
                          label: 'AI Symptom\nChecker',
                          color: const Color(
                              0xFF7C83E8),
                          iconBg: const Color(
                              0xFFEEEFFC),
                          onTap: () =>
                              Navigator.pushNamed(
                                  context, '/ai'),
                        ),
                        _ActionCard(
                          icon: Icons.people_rounded,
                          label: 'Find\nDoctors',
                          color:
                          HealioColors.primary,
                          iconBg: HealioColors
                              .primaryLight,
                          onTap: () =>
                              Navigator.pushNamed(
                                  context, '/doctors'),
                        ),
                        _ActionCard(
                          icon: Icons
                              .calendar_month_rounded,
                          label: 'My\nAppointments',
                          color: const Color(
                              0xFF7C83E8),
                          iconBg: const Color(
                              0xFFEEEFFC),
                          onTap: () =>
                              Navigator.pushNamed(
                                  context,
                                  '/appointments'),
                        ),
                        _ActionCard(
                          icon: Icons
                              .local_hospital_rounded,
                          label: 'Nearby\nHospitals',
                          color:
                          HealioColors.primary,
                          iconBg: HealioColors
                              .primaryLight,
                          onTap: () =>
                              Navigator.pushNamed(
                                  context,
                                  '/hospitals'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Blockchain banner
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          HealioColors.primary,
                          Color(0xFF3D8A6E),
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.2),
                          borderRadius:
                          BorderRadius.circular(
                              12),
                        ),
                        child: const Icon(
                            Icons.shield_rounded,
                            color: Colors.white,
                            size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              'Blockchain Secured',
                              style:
                              GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight:
                                FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your medical records are encrypted and tamper-proof.',
                              style:
                              GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white
                                    .withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom nav
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: HealioColors.bgCard,
        selectedItemColor: HealioColors.primary,
        unselectedItemColor: HealioColors.textLight,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600),
        unselectedLabelStyle:
        GoogleFonts.poppins(fontSize: 11),
        currentIndex: 0,
        onTap: (i) {
          if (role == 'doctor') {
            if (i == 1)
              Navigator.pushNamed(
                  context, '/appointments');
            if (i == 2)
              Navigator.pushNamed(
                  context, '/chats');
            if (i == 3)
              Navigator.pushNamed(
                  context, '/profile');
          } else {
            if (i == 1)
              Navigator.pushNamed(
                  context, '/specialists');
            if (i == 2)
              Navigator.pushNamed(
                  context, '/chats');
            if (i == 3)
              Navigator.pushNamed(
                  context, '/profile');
          }
        },
        items: role == 'doctor'
            ? [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons
                  .calendar_month_rounded),
              label: 'Appointments'),
          BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons
                      .chat_bubble_rounded),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding:
                        const EdgeInsets
                            .all(3),
                        decoration:
                        const BoxDecoration(
                          color:
                          HealioColors.error,
                          shape:
                          BoxShape.circle,
                        ),
                        constraints:
                        const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadCount > 9
                              ? '9+'
                              : '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight:
                            FontWeight.bold,
                          ),
                          textAlign:
                          TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Chats'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ]
            : [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons
                  .medical_services_rounded),
              label: 'Specialists'),
          BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons
                      .chat_bubble_rounded),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding:
                        const EdgeInsets
                            .all(3),
                        decoration:
                        const BoxDecoration(
                          color:
                          HealioColors.error,
                          shape:
                          BoxShape.circle,
                        ),
                        constraints:
                        const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadCount > 9
                              ? '9+'
                              : '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight:
                            FontWeight.bold,
                          ),
                          textAlign:
                          TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Chats'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }

  void _showLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to sign out?',
            style:
            GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: HealioColors.textMid)),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(
                  context, '/login');
            },
            child: Text('Sign Out',
                style: GoogleFonts.poppins(
                  color: HealioColors.error,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconBg;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius:
                BorderRadius.circular(12),
              ),
              child:
              Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HealioColors.textDark,
                  height: 1.3,
                )),
          ],
        ),
      ),
    );
  }
}