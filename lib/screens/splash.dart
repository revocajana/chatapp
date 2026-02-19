import 'package:flutter/material.dart';
import '../widgets/loading_indicator.dart';

class SplashScreen extends StatefulWidget {
	const SplashScreen({super.key});

	@override
	State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
	@override
	void initState() {
		super.initState();
		_navigateNext();
	}

	Future<void> _navigateNext() async {
		await Future.delayed(const Duration(seconds: 2));
		if (!mounted) return;
		Navigator.pushReplacementNamed(context, '/auth');
	}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return Scaffold(
			body: SafeArea(
				child: Center(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							Icon(Icons.chat_bubble_rounded, size: 96, color: theme.colorScheme.primary),
							const SizedBox(height: 16),
							Text('ChatApp', style: theme.textTheme.headlineSmall),
							const SizedBox(height: 12),
							const LoadingIndicator(size: 36),
						],
					),
				),
			),
		);
	}
}
