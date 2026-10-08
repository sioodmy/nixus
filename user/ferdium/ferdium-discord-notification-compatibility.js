const runtimes = [];
let observedChunkPush;
let captureCount = 0;

const captureRuntimes = () => {
  const chunks = window.webpackChunkdiscord_app;
  if (!Array.isArray(chunks) || chunks.push === observedChunkPush) return;

  observedChunkPush = chunks.push;
  captureCount += 1;
  // Discord chains private Rspack runtimes. Match exports, not module IDs.
  chunks.push([
    [`ferdium-notification-compatibility-${Date.now()}-${captureCount}`],
    {},
    require => {
      if (!runtimes.includes(require)) runtimes.push(require);
    },
  ]);
};

const findNotificationSettingsStore = () => {
  captureRuntimes();
  const stores = [];

  for (const runtimeRequire of runtimes) {
    for (const module of Object.values(runtimeRequire.c || {})) {
      const exports = module?.exports;
      const candidates = [
        exports,
        ...(exports && typeof exports === 'object'
          ? Object.values(exports)
          : []),
      ];

      for (const candidate of candidates) {
        if (
          candidate?.constructor?.displayName === 'NotificationSettingsStore' &&
          typeof candidate.getDesktopType === 'function' &&
          typeof candidate.getUserAgnosticState === 'function' &&
          !stores.includes(candidate)
        ) {
          stores.push(candidate);
        }
      }
    }
  }

  return stores.length === 1 ? stores[0] : null;
};

const enableNotifications = () => {
  const store = findNotificationSettingsStore();
  if (!store) return false;

  // Discord defaults to NEVER without DiscordNative and returns before Ferdium's Notification shim.
  const state = store.getUserAgnosticState();
  if (store.getDesktopType() === 'NEVER' && state?.desktopType === 'NEVER') {
    state.desktopType = 'ALL';
  }
  return true;
};

if (!enableNotifications()) {
  const startedAt = Date.now();
  const interval = setInterval(() => {
    if (enableNotifications() || Date.now() - startedAt >= 30_000) {
      clearInterval(interval);
    }
  }, 500);
}
