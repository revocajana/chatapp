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
				print('Signup error: $e');
				ScaffoldMessenger.of(context).showSnackBar(SnackBar(
					content: Text('Error: ${e.toString()}'),
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
								validator: (v) => (v == null || v.isEmpty) ? 'Enter email' : null,
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _passwordController,
								decoration: const InputDecoration(labelText: 'Password'),
								obscureText: true,
								validator: (v) => (v == null || v.length < 6) ? 'Password min 6 chars' : null,
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
								child: const Text('Already have an account? Log in'),
							),
						],
					),
				),
			),
		);
	}
}

