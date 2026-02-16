import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AuthService {
	final FirebaseAuth _auth = FirebaseAuth.instance;
	final UserService _userService = UserService();

	/// Convert Firebase error codes to user-friendly messages
	String _getErrorMessage(FirebaseAuthException e) {
		switch (e.code) {
			case 'user-not-found':
				return 'No account found with this email. Please sign up first.';
			case 'wrong-password':
				return 'Incorrect password. Please try again.';
			case 'invalid-email':
				return 'Invalid email address. Please check and try again.';
			case 'user-disabled':
				return 'This account has been disabled. Contact support for help.';
			case 'too-many-requests':
				return 'Too many login attempts. Please try again later.';
			case 'operation-not-allowed':
				return 'Email/password sign in is not enabled. Please contact support.';
			case 'invalid-credential':
				return 'Invalid email or password. Please try again.';
			case 'email-already-in-use':
				return 'An account with this email already exists.';
			case 'weak-password':
				return 'Password is too weak. Use at least 6 characters.';
			case 'network-request-failed':
				return 'Network error. Please check your internet connection.';
			default:
				return 'An error occurred. Please try again.';
		}
	}

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
		} on FirebaseAuthException catch (e) {
			print('SignUp error: $e');
			throw Exception(_getErrorMessage(e));
		} catch (e) {
			print('SignUp error: $e');
			throw Exception('An unexpected error occurred. Please try again.');
		}
	}

	Future<User?> signIn({required String email, required String password}) async {
		try {
			final credential = await _auth.signInWithEmailAndPassword(
				email: email,
				password: password,
			);
			return credential.user;
		} on FirebaseAuthException catch (e) {
			throw Exception(_getErrorMessage(e));
		}
	}

	Future<void> signOut() async {
		await _auth.signOut();
	}

	User? get currentUser => _auth.currentUser;
}

final authService = AuthService();

