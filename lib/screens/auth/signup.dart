import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool _loading = false;
  bool _showPassword = false;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  String? _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least 1 uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least 1 lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least 1 digit';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least 1 special character (!@#\$%^&*)';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (_formKey.currentState != null) _formKey.currentState!.validate();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );
      if (user != null) {
        try {
          await notificationService.initializeNotifications(user.uid);
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
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('chatapp')),
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
                colors: [
                  primaryColor.withValues(alpha: 0.08),
                  colorScheme.surface,
                ],
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
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 48),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Start your secure workspace',
                                            style: theme
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Create your account to chat and collaborate with your team.',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: formMaxWidth,
                                    ),
                                    child: _buildSignupCard(
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
                                child: _buildSignupCard(
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

  Widget _buildSignupCard({
    required BuildContext context,
    required double cardPadding,
    required bool isTabletOrDesktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    return Card(
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
                  color: primaryColor.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  size: isTabletOrDesktop ? 38 : 34,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create account',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign up to get started',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                focusNode: _usernameFocus,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                enabled: !_loading,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Your username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Username is required';
                  }
                  if (v.trim().length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_emailFocus),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                enabled: !_loading,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
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
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_loading,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Create a strong password',
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
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_confirmPasswordFocus),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_loading,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  hintText: 'Re-enter your password',
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
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Confirm password is required';
                  }
                  if (v != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Sign In'),
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
