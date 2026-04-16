import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'utils/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/doctors_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/doctor_profile_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/specialists_screen.dart';
import 'screens/hospitals_screen.dart';
import 'screens/search_screen.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HealioApp());
}

class HealioApp extends StatelessWidget {
  const HealioApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Healio',
        debugShowCheckedModeBanner: false,
        theme: healioTheme(),
        initialRoute: '/splash',
        routes: {
          '/splash':   (_) => const SplashScreen(),
          '/login':    (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home':     (_) => const HomeScreen(),
          '/doctors':  (_) => const DoctorsScreen(),
          '/ai':       (_) => const AiScreen(),
          '/chats':    (_) => const ChatListScreen(),
          '/profile':  (_) => const ProfileScreen(),
          '/doctor_profile': (_) => const DoctorProfileScreen(doctor: {}),
          '/appointments': (_) => const AppointmentsScreen(),
          '/specialists': (_) => const SpecialistsScreen(),
          '/hospitals': (_) => const HospitalsScreen(),
          '/search': (_) => const SearchScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/chat') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ChatScreen(
                otherUserId:   args['otherUserId']   as String,
                otherUsername: args['otherUsername'] as String,
                otherName:     args['otherName']     as String,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}