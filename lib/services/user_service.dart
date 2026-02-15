
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
	final FirebaseFirestore _firestore = FirebaseFirestore.instance;
	final FirebaseAuth _auth = FirebaseAuth.instance;

	/// Create or update user in Firestore
	Future<void> createOrUpdateUser({
		required String uid,
		required String email,
		String? displayName,
		String? photoUrl,
	}) async {
		try {
			final docRef = _firestore.collection('users').doc(uid);
			final existing = await docRef.get();

			// Store lowercase variants to make client search reliable
			final data = <String, dynamic>{
				'email': email,
				'emailLower': email.toLowerCase(),
				'displayName': displayName,
				'displayNameLower': displayName?.toLowerCase(),
				'photoUrl': photoUrl,
			};

			// Only set createdAt when the document is first created
			if (!existing.exists) {
				data['createdAt'] = FieldValue.serverTimestamp();
			}

			await docRef.set(data, SetOptions(merge: true));
		} catch (e) {
			print('Error creating/updating user: $e');
			rethrow;
		}
	}

	/// Update user's FCM token
	Future<void> updateFCMToken(String uid, String fcmToken) async {
		try {
			// Use set with merge to create the document if it doesn't exist yet
			await _firestore.collection('users').doc(uid).set({'fcmToken': fcmToken}, SetOptions(merge: true));
		} catch (e) {
			print('Error updating FCM token: $e');
			rethrow;
		}
	}

	/// Stream all users except the current user
	Stream<List<UserModel>> streamAllUsers() {
		final currentUser = _auth.currentUser;
		if (currentUser == null) {
			// Return immediate empty list stream until authenticated
			return Stream.value(<UserModel>[]);
		}

		final uid = currentUser.uid;

		// Query all users and filter out the current user locally by UID.
		// This avoids Firestore inequality queries which can be problematic
		// in some security/indexing setups.
		return _firestore.collection('users').snapshots().map((snapshot) {
			final others = snapshot.docs.where((d) => d.id != uid).toList();
			return others.map((d) => UserModel.fromFirestore(d)).toList();
		});
	}

	/// Search users by display name or email
	Future<List<UserModel>> searchUsers(String query) async {
		try {
			final lower = query.toLowerCase();

			// Search using precomputed lowercase fields and wide string range
			final end = '$lower\uf8ff';
			final nameSnap = await _firestore
					.collection('users')
					.where('displayNameLower', isGreaterThanOrEqualTo: lower, isLessThanOrEqualTo: end)
					.get();

			final emailSnap = await _firestore
					.collection('users')
					.where('emailLower', isGreaterThanOrEqualTo: lower, isLessThanOrEqualTo: end)
					.get();

			final map = <String, UserModel>{};
			for (var d in nameSnap.docs) {
				map[d.id] = UserModel.fromFirestore(d);
			}
			for (var d in emailSnap.docs) {
				map[d.id] = UserModel.fromFirestore(d);
			}

			return map.values.toList();
		} catch (e) {
			print('Error searching users: $e');
			rethrow;
		}
	}

	/// Get a specific user
	Future<UserModel?> getUser(String uid) async {
		try {
			final doc = await _firestore.collection('users').doc(uid).get();
			if (!doc.exists) return null;
			return UserModel.fromFirestore(doc);
		} catch (e) {
			print('Error getting user: $e');
			return null;
		}
	}
}

final userService = UserService();

