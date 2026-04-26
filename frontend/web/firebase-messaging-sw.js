// This is a minimal Firebase Messaging Service Worker
// It allows the Firebase Web SDK to initialize even if you are using app-driven alerts.

importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: "AIzaSyDy...", // Will be filled by SDK or can be left generic
    projectId: "smart-waste-collection-6a2f0",
    messagingSenderId: "338...",
    appId: "1:338..."
});

const messaging = firebase.messaging();
