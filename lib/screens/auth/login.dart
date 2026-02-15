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

	@override
	void dispose() {
		_emailController.dispose();
		_passwordController.dispose();
		super.dispose();
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
				// Ensure user exists in Firestore before showing users list
				try {
					await userService.createOrUpdateUser(
						uid: user.uid,
						email: user.email ?? _emailController.text.trim(),
						displayName: user.displayName,
					);
				} catch (_) {
					// ignore errors here; still navigate to home
				}
				if (!mounted) return;
				Navigator.pushReplacementNamed(context, '/home');
			}
		} on Exception catch (e) {
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Login')),
			body: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Form(
					key: _formKey,
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
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
											child: const Text('Login'),
										),
							const SizedBox(height: 12),
							TextButton(
								onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
								child: const Text('Don\'t have an account? Sign up'),
							),
						],
					),
				),
			),
		);
	}
}

