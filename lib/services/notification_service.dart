import 'package:firebase_messaging/firebase_messaging.dart';
import 'user_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final UserService _userService = UserService();

  /// Request notification permissions and get FCM token
  Future<String?> initializeNotifications(String userId) async {
    try {
      // Request user notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('Notification permission denied by user');
        return null;
      }

      // Get the FCM token
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token != null) {
        // Save token to Firestore
        await _userService.updateFCMToken(userId, token);
        print('FCM Token saved to Firestore');
      }

      // Listen for token refresh and update Firestore when it changes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        _userService.updateFCMToken(userId, newToken);
      });

      return token;
    } catch (e) {
      print('Error initializing notifications: $e');
      return null;
    }
  }
}

final notificationService = NotificationService();
