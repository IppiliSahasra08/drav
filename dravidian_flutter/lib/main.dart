// ---------------------------------------------------------------------------
// main.dart — App entry point.
// Robust startup: dotenv + optional Supabase init, global error widget,
// and a safe fallback UI when services fail so web does not show a white screen.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/category_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/result_screen.dart';
import 'theme.dart';
import 'screens/signup_screen.dart';
import 'screens/adult_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var supabaseInitialized = true;

  // Load .env file safely — continue with offline mode if unavailable
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('.env loaded');
  } catch (e) {
    supabaseInitialized = false;
    debugPrint('dotenv.load failed: $e');
  }

  // Initialise Supabase only if env values are present
  try {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    debugPrint('SUPABASE_URL present: ${url != null && url.isNotEmpty}');
    debugPrint('SUPABASE_ANON_KEY present: ${key != null && key.isNotEmpty}');
    if (url != null && key != null && url.isNotEmpty && key.isNotEmpty) {
      // Mask the anon key in logs for safety (show first/last 4 chars)
      final maskedKey = key.length > 8 ? '${key.substring(0,4)}...${key.substring(key.length-4)}' : '***';
      debugPrint('Initializing Supabase with URL: $url and ANON key: $maskedKey');
      await Supabase.initialize(url: url, anonKey: key);
      debugPrint('Supabase initialized');
    } else {
      supabaseInitialized = false;
      debugPrint('Supabase env keys missing — running without Supabase');
    }
  } catch (e, st) {
    supabaseInitialized = false;
    debugPrint('Supabase.initialize failed: $e');
    debugPrint(st.toString());
  }

  // Attach a global error widget for easier debugging during dev
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'App error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(details.exceptionAsString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(DravidianLearnApp(supabaseInitialized: supabaseInitialized));
}

class DravidianLearnApp extends StatelessWidget {
  final bool supabaseInitialized;
  const DravidianLearnApp({super.key, this.supabaseInitialized = true});

  @override
  Widget build(BuildContext context) {
    // When Supabase isn't initialized we avoid calling into the client API.
    String initialRoute = '/login';
    if (supabaseInitialized) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        initialRoute = session != null ? '/home' : '/login';
      } catch (e) {
        debugPrint('Warning: could not read Supabase session: $e');
        initialRoute = '/login';
      }
    }

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
      // No custom builder — keep the widget tree standard to avoid layout issues.
      // Supabase initialization state is logged to console; do not block rendering.
      routes: {
        '/login':           (_) => const LoginScreen(),
        '/signup':          (_) => const SignUpScreen(),
        '/home':            (_) => const HomeScreen(),       // child dashboard
        '/adult-dashboard': (_) => const AdultDashboardScreen(),
        '/lesson':          (_) => const LessonScreen(),
        '/category':        (_) => const CategoryScreen(),
        '/quiz':            (_) => const QuizScreen(),
        '/result':          (_) => const ResultScreen(),
      },
    );
  }
}
