// ---------------------------------------------------------------------------
// main.dart — App entry point.
// What's the same: Supabase init, auth-gated routing, same 3 screens.
// What's different: Flutter uses MaterialApp named routes instead of
// expo-router's file-based routing. Auth guard is handled by checking
// Supabase session here rather than in a _layout.tsx file.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lesson_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file — equivalent to process.env.EXPO_PUBLIC_* in RN
  await dotenv.load(fileName: '.env');

  // Initialise Supabase — equivalent to createClient() in lib/supabase.ts
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const DravidianLearnApp());
}

class DravidianLearnApp extends StatelessWidget {
  const DravidianLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Decide initial route based on whether there's an active session
    final session = Supabase.instance.client.auth.currentSession;
    final initialRoute = session != null ? '/home' : '/login';

    return MaterialApp(
      title: 'Dravidian Learn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: AppTheme.primary,
        useMaterial3: true,
        scaffoldBackgroundColor: AppTheme.background,
        fontFamily: 'Roboto',
      ),
      initialRoute: initialRoute,
      // Named routes — replaces expo-router's file-based routing
      routes: {
        '/login':  (_) => const LoginScreen(),
        '/home':   (_) => const HomeScreen(),
        '/lesson': (_) => const LessonScreen(),
      },
    );
  }
}
