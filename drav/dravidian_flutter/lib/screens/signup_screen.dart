import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _confirmController    = TextEditingController();
  final _nameController       = TextEditingController();
  String _role = 'child'; // default
  bool _loading = false;
  String? _error;

  Future<void> _signUp() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      setState(() {
        _error = 'Please fill in all fields.';
        _loading = false;
      });
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _error = 'Passwords do not match.';
        _loading = false;
      });
      return;
    }

    try {
      // Get backend URL from environment
      final backendUrl = (dotenv.env['BACKEND_URL'] ?? dotenv.env['API_URL'] ?? '').trim();
      if (backendUrl.isEmpty) {
        throw Exception('BACKEND_URL is not configured in .env');
      }

      // Prepare registration payload with default onboarding values
      // These will be updated by the onboarding screen
      final payload = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'display_name': _nameController.text.trim(),
        'role': _role,
        'learning_language': 'telugu', // default
        'learning_goal': 'learn_basics', // default
        'learning_style': 'child_learner', // default
        'app_preferences': {},
        'accessibility_preferences': {
          'larger_text': false,
          'audio_first': false,
          'reduced_animations': false,
          'high_contrast': false,
        },
      };

      // Call backend registration endpoint
      final response = await http.post(
        Uri.parse('$backendUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Registration failed. Please try again.');
      }

      if (!mounted) return;

      // 3. Route based on role
      if (_role == 'adult') {
        Navigator.pushNamedAndRemoveUntil(context, '/adult-dashboard', (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (_) => false);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create Account',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primary)),
              const SizedBox(height: 32),

              // Role selector
              const Text('I am a...', style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(children: [
                _RoleChip(label: 'Child / Learner', value: 'child', selected: _role == 'child',
                  onTap: () => setState(() => _role = 'child')),
                const SizedBox(width: 12),
                _RoleChip(label: 'Adult / Parent', value: 'adult', selected: _role == 'adult',
                  onTap: () => setState(() => _role = 'adult')),
              ]),
              const SizedBox(height: 24),

              TextField(controller: _nameController, decoration: AppTheme.inputDecoration('Username')),
              const SizedBox(height: 16),
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress,
                decoration: AppTheme.inputDecoration('Email')),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true,
                decoration: AppTheme.inputDecoration('Password')),
              const SizedBox(height: 16),
              TextField(controller: _confirmController, obscureText: true,
                decoration: AppTheme.inputDecoration('Confirm Password')),
              const SizedBox(height: 8),

              if (_error != null)
                Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 14),
                    textAlign: TextAlign.center)),

              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : _signUp,
                style: AppTheme.primaryButton,
                child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create account', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            border: Border.all(color: selected ? AppTheme.primary : AppTheme.textSecondary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}