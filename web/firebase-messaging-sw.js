importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyA7d81WB54HBRevnkQfzCWNA1Q5AaG1Kbw",
  authDomain: "pmos-care.firebaseapp.com",
  projectId: "pmos-care",
  storageBucket: "pmos-care.firebasestorage.app",
  messagingSenderId: "630482464919",
  appId: "1:630482464919:web:5d04cd2a3e7f5302cd39d2",
  measurementId: "G-PSMW10ZP8K"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title || "PMOS Care Notification";
  const notificationOptions = {
    body: payload.notification.body || "",
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
