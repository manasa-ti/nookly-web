// Web Push service worker.
// Stage 5: Handle background push notifications and notification taps.

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

function normalizePayload(raw) {
  if (!raw || typeof raw !== 'object') {
    return {};
  }

  const notification = raw.notification || {};
  const data = raw.data || {};

  const title = notification.title || data.title || 'New notification';
  const body = notification.body || data.body || '';
  const icon = notification.icon || data.icon || '/icons/Icon-192.png';
  const image = notification.image || data.image;
  const badge = notification.badge || data.badge || '/icons/Icon-maskable-192.png';
  const clickAction = data.click_action || raw.fcmOptions?.link || '/';

  return {
    title,
    options: {
      body,
      icon,
      image,
      badge,
      data: {
        click_action: clickAction,
        payload: raw,
      },
    },
  };
}

self.addEventListener('push', (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (error) {
    payload = {};
  }

  const normalized = normalizePayload(payload);
  event.waitUntil(
    self.registration.showNotification(normalized.title, normalized.options),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const targetUrl = event.notification?.data?.click_action || '/';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clients) => {
      for (const client of clients) {
        if ('focus' in client) {
          client.postMessage({
            type: 'web_push_notification_click',
            payload: event.notification?.data?.payload || {},
          });
          return client.focus();
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetUrl);
      }
      return Promise.resolve();
    }),
  );
});


