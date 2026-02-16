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
	bool _loading = false;
	bool _showPassword = false;

	/// Validates email format using regex pattern
	bool _isValidEmail(String email) {
		final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$');
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
			appBar: AppBar(title: const Text('Registration Form')),
			body: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Form(
					key: _formKey,
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							TextFormField(
								controller: _usernameController,
								decoration: const InputDecoration(labelText: 'Username'),
								validator: (v) => (v == null || v.isEmpty) ? 'Enter username' : null,
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _emailController,
								decoration: const InputDecoration(labelText: 'Email'),
								keyboardType: TextInputType.emailAddress,
								validator: (v) {
									if (v == null || v.isEmpty) return 'Enter email';
									if (!_isValidEmail(v.trim())) return 'Enter a valid email (e.g., user@example.com)';
									return null;
								},
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _passwordController,
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
							),
							const SizedBox(height: 20),
							_loading
								? const CircularProgressIndicator()
								: ElevatedButton(
									onPressed: _submit,
									child: const Text('Create account'),
								),
							const SizedBox(height: 12),
							TextButton(
								onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
								child: const Text('I have an account? Log in'),
							),
						],
					),
				),
			),
		);
	}
}

