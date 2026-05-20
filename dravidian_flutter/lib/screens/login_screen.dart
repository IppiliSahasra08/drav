// ---------------------------------------------------------------------------
// LoginScreen — Updated for separate Adult / User-Child login pathways.
// Performs password sign-in, verifies profile role, and routes to the
// appropriate dashboard while rejecting mismatched role selections.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'adult_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String _selectedRole = 'child';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!AuthService().isSupabaseReady) {
        if (mounted) {
          setState(() => _error =
              'Supabase not initialized. Fill SUPABASE_URL and SUPABASE_ANON_KEY in .env');
        }
        return;
      }

      final client = Supabase.instance.client;
      final response = await client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        throw Exception('Sign in failed. Please check your credentials.');
      }

      final user = response.user!;
      final profileResponse = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final dbRole = profileResponse['role'] as String? ?? 'child';

      if (_selectedRole != dbRole) {
        await client.auth.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Incorrect role profile selected.'),
            backgroundColor: AppTheme.error,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (!mounted) return;

      if (dbRole == 'adult') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdultDashboardScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Dravidian\nLearn',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tamil & Telugu for everyone',
                  style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Login as:',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                ToggleButtons(
                  isSelected: [
                    _selectedRole == 'child',
                    _selectedRole == 'adult',
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedRole = index == 0 ? 'child' : 'adult';
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: Colors.white,
                  fillColor: AppTheme.primary,
                  color: AppTheme.textSecondary,
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 130),
                  children: const [
                    Text('User / Child'),
                    Text('Adult'),
                  ],
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: AppTheme.inputDecoration('Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: AppTheme.inputDecoration('Password'),
                  onSubmitted: (_) => _signIn(),
                ),
                const SizedBox(height: 8),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _loading ? null : _signIn,
                  style: AppTheme.primaryButton,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: const Text("Don't have an account? Sign up"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
