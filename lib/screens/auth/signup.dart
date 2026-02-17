import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

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
	final TextEditingController _confirmPasswordController = TextEditingController();

	final FocusNode _usernameFocus = FocusNode();
	final FocusNode _emailFocus = FocusNode();
	final FocusNode _passwordFocus = FocusNode();
	final FocusNode _confirmPasswordFocus = FocusNode();
	bool _loading = false;
	bool _showPassword = false;

	/// Validates email format using regex pattern
	bool _isValidEmail(String email) {
		final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
		return emailRegex.hasMatch(email);
	}

	/// Validates password strength:
	/// - Minimum 8 characters
	/// - At least 1 uppercase letter
	/// - At least 1 lowercase letter
	/// - At least 1 digit
	/// - At least 1 special character
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

	@override
	void initState() {
		super.initState();
		// Revalidate confirm password when the password changes
		_passwordController.addListener(() {
			if (_formKey.currentState != null) _formKey.currentState!.validate();
		});
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
				if (!mounted) return;
				Navigator.pushReplacementNamed(context, '/home');
			}
		} on Exception catch (e) {
			if (mounted) {
				String errorMessage = e.toString();
				// Extract the message from "Exception: message" format
				if (errorMessage.startsWith('Exception: ')) {
					errorMessage = errorMessage.replaceFirst('Exception: ', '');
				}
				ScaffoldMessenger.of(context).showSnackBar(SnackBar(
					content: Text(errorMessage),
					backgroundColor: Colors.red,
					duration: const Duration(seconds: 5),
				));
			}
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Sign Up')),
			body: Center(
				child: SingleChildScrollView(
					child: Padding(
						padding: const EdgeInsets.all(16.0),
						child: ConstrainedBox(
							constraints: const BoxConstraints(maxWidth: 500),
							child: Card(
								elevation: 6,
								shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
								child: Padding(
									padding: const EdgeInsets.all(20),
									child: Form(
										key: _formKey,
										child: Column(
											mainAxisSize: MainAxisSize.min,
											crossAxisAlignment: CrossAxisAlignment.stretch,
											children: [
												Center(
													child: Text(
														'Create account',
														style: Theme.of(context).textTheme.headline6,
													),
												),
												const SizedBox(height: 12),
							TextFormField(
								controller: _usernameController,
								focusNode: _usernameFocus,
								textInputAction: TextInputAction.next,
								autofillHints: const [AutofillHints.username],
								enabled: !_loading,
								decoration: const InputDecoration(labelText: 'Username'),
								validator: (v) {
									if (v == null || v.trim().isEmpty) return 'Enter username';
									if (v.trim().length < 3) return 'Username must be at least 3 characters';
									return null;
								},
								onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _emailController,
								focusNode: _emailFocus,
								textInputAction: TextInputAction.next,
								autofillHints: const [AutofillHints.email],
								enabled: !_loading,
								decoration: const InputDecoration(labelText: 'Email'),
								keyboardType: TextInputType.emailAddress,
								validator: (v) {
									if (v == null || v.trim().isEmpty) return 'Enter email';
									if (!_isValidEmail(v.trim())) return 'Enter a valid email (e.g., user@example.com)';
									return null;
								},
								onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _passwordController,
								focusNode: _passwordFocus,
								textInputAction: TextInputAction.next,
								autofillHints: const [AutofillHints.newPassword],
								enabled: !_loading,
								decoration: InputDecoration(
									labelText: 'Password',
									suffixIcon: IconButton(
										icon: Icon(
											_showPassword ? Icons.visibility : Icons.visibility_off,
										),
										onPressed: () {
											setState(() => _showPassword = !_showPassword);
										},
									),
								),
								obscureText: !_showPassword,
								validator: _validatePassword,
								onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmPasswordFocus),
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _confirmPasswordController,
								focusNode: _confirmPasswordFocus,
								textInputAction: TextInputAction.done,
								autofillHints: const [AutofillHints.newPassword],
								enabled: !_loading,
								decoration: InputDecoration(
									labelText: 'Confirm Password',
									suffixIcon: IconButton(
										icon: Icon(
											_showPassword ? Icons.visibility : Icons.visibility_off,
										),
										onPressed: () {
											setState(() => _showPassword = !_showPassword);
										},
									),
								),
								obscureText: !_showPassword,
								validator: (v) {
									if (v == null || v.trim().isEmpty) return 'Confirm password is required';
									if (v != _passwordController.text) return 'Passwords do not match';
									return null;
								},
								onFieldSubmitted: (_) => _submit(),
							),
							const SizedBox(height: 20),
							_loading
								? const Center(child: CircularProgressIndicator())
								: SizedBox(
									width: double.infinity,
									child: ElevatedButton(
										onPressed: _submit,
										style: ElevatedButton.styleFrom(
											padding: const EdgeInsets.symmetric(vertical: 14),
											shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
										),
										child: const Text('Create account'),
									),
								),
							const SizedBox(height: 12),
							Center(
								child: TextButton(
									onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
									child: const Text('Already have an account? Log in'),
								),
							),
						],
					),
				),
			),
		);
	}
}

