import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AuthService {
	final FirebaseAuth _auth = FirebaseAuth.instance;
	final UserService _userService = UserService();

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
				
				// Create Firestore document for the user
				print('Creating Firestore user document');
				await _userService.createOrUpdateUser(
					uid: user.uid,
					email: email,
					displayName: username,
					photoUrl: user.photoURL,
				);
				print('Firestore user document created successfully');
				
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

