// Import the Firebase scripts that are needed
importScripts('https://www.gstatic.com/firebasejs/9.15.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.15.0/firebase-messaging-compat.js');

// Initialize the Firebase app by passing in the configuration details
firebase.initializeApp({
  apiKey: 'AIzaSyDBeTN2TBXsMwBGgtQYvPUNfPdBipY-7lU',
    appId: '1:184006771200:web:ca72324156e896c4b70ee5',
    messagingSenderId: '184006771200',
    projectId: 'freelance-connect-app',
    authDomain: 'freelance-connect-app.firebaseapp.com',
    storageBucket: 'freelance-connect-app.appspot.com',
    measurementId: 'G-PHVKWJG1WG',
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  // Customize the notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png'
  };

  // Show the notification
  self.registration.showNotification(notificationTitle, notificationOptions);
});
