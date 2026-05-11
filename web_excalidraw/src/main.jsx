import React from 'react';
import ReactDOM from 'react-dom/client';

// Global error listener to report unexpected errors back to Flutter
window.addEventListener('error', function(event) {
  if (window.flutter_channel && typeof window.flutter_channel.postMessage === 'function') {
    try {
      window.flutter_channel.postMessage(JSON.stringify({
        type: 'ERROR',
        message: event.message || String(event),
        filename: event.filename || '',
        lineno: event.lineno || 0,
      }));
    } catch (_) {}
  }
});

// Robust URL and asset path resolution for Android WebView file:///android_asset/
(function() {
  var href = window.location.href || '';
  var base;
  if (href.startsWith('file://') || href.startsWith('http://') || href.startsWith('https://')) {
    base = href.substring(0, href.lastIndexOf('/') + 1);
  } else {
    base = 'file:///android_asset/flutter_assets/assets/excalidraw/';
  }
  window.EXCALIDRAW_ASSET_PATH = base;

  var OrigURL = window.URL;
  if (OrigURL) {
    var SafeURL = function(url, baseArg) {
      if (url && typeof url === 'string' && (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('file://') || url.startsWith('data:'))) {
        return new OrigURL(url);
      }
      var validBase = base;
      if (baseArg && typeof baseArg === 'string' && baseArg !== 'null' && baseArg !== '[object Object]' && (baseArg.startsWith('http://') || baseArg.startsWith('https://') || baseArg.startsWith('file://'))) {
        validBase = baseArg;
      }
      try {
        return new OrigURL(url, validBase);
      } catch (e) {
        try {
          return new OrigURL(url, 'https://unpkg.com/@excalidraw/excalidraw/dist/prod/');
        } catch (e2) {
          return { href: String(url), pathname: String(url), toString: function() { return String(url); } };
        }
      }
    };
    SafeURL.prototype = OrigURL.prototype;
    Object.setPrototypeOf(SafeURL, OrigURL);
    window.URL = SafeURL;
  }
})();

import '@excalidraw/excalidraw/index.css';
import './index.css';
import App from './App.jsx';

// Global bridge for Flutter communication before and during React hydration
window.__nview_pendingScene = null;
window.__nview_filePath = window.__nview_filePath || '';
window.loadScene = function(json, targetPath) {
  if (window.__nview_loadSceneImpl) {
    window.__nview_loadSceneImpl(json, targetPath);
  } else {
    window.__nview_pendingScene = { json, targetPath };
  }
};
window.setFilePath = function(p) {
  window.__nview_filePath = p;
  if (window.__nview_setFilePathImpl) {
    window.__nview_setFilePathImpl(p);
  }
};

function mountApp() {
  var rootEl = document.getElementById('root');
  if (!rootEl) {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', mountApp);
    } else {
      setTimeout(mountApp, 20);
    }
    return;
  }
  ReactDOM.createRoot(rootEl).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', mountApp);
} else {
  mountApp();
}
