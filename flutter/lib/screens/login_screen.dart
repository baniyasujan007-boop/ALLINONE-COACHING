import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'admin_dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final AppState appState = context.read<AppState>();
    final bool ok = await appState.login(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      final UserRole role =
          AuthService.instance.currentSession?.user.role ?? UserRole.student;
      final Widget destination = role == UserRole.admin
          ? const AdminDashboardScreen()
          : const HomeScreen();
      final String roleText = role == UserRole.admin ? 'Admin' : 'Student';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logged in as $roleText')));
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(appState.authError ?? 'Login failed')),
    );
  }

  Future<void> _loginWithGoogle() async {
    final AppState appState = context.read<AppState>();
    final bool ok = await appState.loginWithGoogle();
    if (!mounted) {
      return;
    }
    if (ok) {
      final UserRole role =
          AuthService.instance.currentSession?.user.role ?? UserRole.student;
      final Widget destination = role == UserRole.admin
          ? const AdminDashboardScreen()
          : const HomeScreen();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed in with Google')));
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(appState.authError ?? 'Google sign-in failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedGradientBackground(
        dark: dark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 8),
                const Center(child: AppLogo(size: 72)),
                const SizedBox(height: 12),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to All in One',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coaching that keeps your learning in one place',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                SizedBox(
                  height: 80,
                  child: Lottie.network(
                    'https://assets2.lottiefiles.com/packages/lf20_jcikwtux.json',
                    repeat: true,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const Icon(
                            Icons.auto_awesome_rounded,
                            size: 36,
                          );
                        },
                  ),
                ),
                const SizedBox(height: 30),
                GlassCard(
                  radius: 24,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: (String? value) {
                            if (value == null || !value.contains('@')) {
                              return 'Enter valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (String? value) {
                            if (value == null || value.length < 8) {
                              return 'Password must be 8+ chars';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        Consumer<AppState>(
                          builder: (BuildContext context, AppState state, _) {
                            return GradientButton(
                              label: state.authLoading
                                  ? 'Signing in...'
                                  : 'Login',
                              onPressed: state.authLoading ? () {} : _login,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          onPressed: context.watch<AppState>().authLoading
                              ? null
                              : _loginWithGoogle,
                          icon: const Icon(
                            Icons.g_mobiledata_rounded,
                            size: 28,
                          ),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text('New here?'),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SignupScreen(),
                        ),
                      ),
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
