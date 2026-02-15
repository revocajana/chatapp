import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LogoutButton extends StatelessWidget {
  final String? tooltip;
  const LogoutButton({super.key, this.tooltip});

  Future<void> _logout(BuildContext context) async {
    try {
      await authService.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip ?? 'Logout',
      icon: const Icon(Icons.logout),
      onPressed: () => _logout(context),
    );
  }
}
