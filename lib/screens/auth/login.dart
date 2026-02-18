import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (user != null) {
        try {
          await userService.createOrUpdateUser(
            uid: user.uid,
            email: user.email ?? _emailController.text.trim(),
            displayName: user.displayName,
          );
        } catch (_) {}
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on Exception catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('chatapp'), elevation: 0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isDesktop = width >= 1100;
          final bool isTablet = width >= 700 && width < 1100;
          final double pageHorizontalPadding = isDesktop
              ? 56
              : (isTablet ? 32 : 16);
          final double formMaxWidth = isDesktop
              ? 460
              : (isTablet ? 520 : double.infinity);
          final double cardPadding = isDesktop ? 36 : (isTablet ? 30 : 22);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor.withOpacity(0.08), colorScheme.surface],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: pageHorizontalPadding,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 30),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          
                                          const SizedBox(height: 12),
                                          
                                        ],
                                      ),
                                    ),
                                  ),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: formMaxWidth,
                                    ),
                                    child: _buildLoginCard(
                                      context: context,
                                      cardPadding: cardPadding,
                                      isTabletOrDesktop: true,
                                    ),
                                  ),
                                ],
                              )
                            : ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: formMaxWidth,
                                ),
                                child: _buildLoginCard(
                                  context: context,
                                  cardPadding: cardPadding,
                                  isTabletOrDesktop: isTablet,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginCard({
    required BuildContext context,
    required double cardPadding,
    required bool isTabletOrDesktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    return Card(
      elevation: 10,
      shadowColor: primaryColor.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isTabletOrDesktop ? 82 : 72,
                height: isTabletOrDesktop ? 82 : 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.12),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: isTabletOrDesktop ? 38 : 34,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome back',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to continue',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email address',
                  hintText: 'you@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!_isValidEmail(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Password is required';
                  }
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/signup'),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
