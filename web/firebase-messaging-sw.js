// This service worker handles Firebase Cloud Messaging push notifications on the web.
// It must be at the root of the web directory.

importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Initialize Firebase in the service worker
try {
  firebase.initializeApp({
    apiKey: "YOUR_API_KEY", // These will be overridden by the web app's config
    projectId: "YOUR_PROJECT_ID",
  });
  
  const messaging = firebase.messaging();
  
  // Handle background messages
  messaging.onBackgroundMessage(function(payload) {
    console.log('Received background message: ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
      body: payload.notification.body,
      icon: '/favicon.png'
    };
    return self.registration.showNotification(notificationTitle, notificationOptions);
  });
} catch (e) {
  console.error('Firebase initialization error in service worker:', e);
}
