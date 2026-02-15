import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
	final FirebaseAuth _auth = FirebaseAuth.instance;

	Future<User?> signUp({required String email, required String password, String? username}) async {
		try {
			print('Attempting signup with email: $email, username: $username');
			final credential = await _auth.createUserWithEmailAndPassword(
				email: email,
				password: password,
			);
			print('User created successfully: ${credential.user?.uid}');
			
			final user = credential.user;
			if (user != null && username != null && username.isNotEmpty) {
				print('Updating display name to: $username');
				await user.updateDisplayName(username);
				await user.reload();
				print('Display name updated');
				return _auth.currentUser;
			}
			return user;
		} catch (e) {
			print('SignUp error: $e');
			rethrow;
		}
	}

	Future<User?> signIn({required String email, required String password}) async {
		final credential = await _auth.signInWithEmailAndPassword(
			email: email,
			password: password,
		);
		return credential.user;
	}

	Future<void> signOut() async {
		await _auth.signOut();
	}

	User? get currentUser => _auth.currentUser;
}

final authService = AuthService();

