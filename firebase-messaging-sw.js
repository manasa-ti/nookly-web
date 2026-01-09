// Firebase Cloud Messaging Service Worker
// This file prevents 404 errors when Firebase Messaging is accessed on web
// Firebase Messaging functionality is disabled on web in this app

// Empty service worker - Firebase Messaging is not used on web
// The app handles notifications differently on web (if needed)

self.addEventListener('install', (event) => {
  // Skip waiting to activate immediately
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  // Take control of all clients immediately
  event.waitUntil(self.clients.claim());
});

// No Firebase Messaging initialization - service worker exists only to prevent 404

