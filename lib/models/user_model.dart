import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
	final String uid;
	final String email;
	final String? displayName;
	final String? photoUrl;
	final DateTime createdAt;
	final String? fcmToken;

	UserModel({
		required this.uid,
		required this.email,
		this.displayName,
		this.photoUrl,
		required this.createdAt,
		this.fcmToken,
	});

	factory UserModel.fromFirestore(DocumentSnapshot doc) {
		final data = doc.data() as Map<String, dynamic>? ?? {};
		return UserModel(
			uid: doc.id,
			email: data['email'] ?? '',
			displayName: data['displayName'] as String?,
			photoUrl: data['photoUrl'] as String?,
			createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
			fcmToken: data['fcmToken'] as String?,
		);
	}

	Map<String, dynamic> toMap() {
		return {
			'email': email,
			'displayName': displayName,
			'photoUrl': photoUrl,
			'createdAt': Timestamp.fromDate(createdAt),
			'fcmToken': fcmToken,
		};
	}
}

