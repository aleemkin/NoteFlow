import React, { useState, useEffect, useRef, useCallback } from 'react';
import { Excalidraw, getCommonBounds, exportToBlob, exportToSvg, restoreElements } from '@excalidraw/excalidraw';

// Check if Canvas 2D context natively supports the filter property (e.g. Chromium / Android WebView)
const supportsCanvasFilter = () => {
  try {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    return !!(ctx && 'filter' in ctx);
  } catch (_) {
    return false;
  }
};

// Export PNG blob with dark mode support across all engines (including WebKitGTK on Linux & Safari)
const exportDarkPngBlob = async ({ elements, appState, files, exportPadding = 16 }) => {
  const mergedAppState = {
    ...appState,
    theme: 'dark',
    exportWithDarkMode: true,
    exportBackground: true,
    viewBackgroundColor: appState.viewBackgroundColor || '#ffffff',
  };

  // If native canvas filter is supported (Android/Chromium), use standard exportToBlob
  if (supportsCanvasFilter()) {
    return exportToBlob({
      elements,
      appState: mergedAppState,
      files: files || {},
      exportPadding,
      mimeType: 'image/png',
      quality: 1,
    });
  }

  // Fallback for WebKitGTK / Safari which lacks CanvasRenderingContext2D.filter:
  // exportToSvg natively attaches filter="invert(93%) hue-rotate(180deg)",
  // which WebKit's SVG rasterizer renders with complete fidelity.
  const svg = await exportToSvg({
    elements,
    appState: mergedAppState,
    files: files || {},
    exportPadding,
  });

  const width = parseFloat(svg.getAttribute('width')) || 300;
  const height = parseFloat(svg.getAttribute('height')) || 200;
  const svgString = new XMLSerializer().serializeToString(svg);
  const svgBlob = new Blob([svgString], { type: 'image/svg+xml;charset=utf-8' });
  const url = URL.createObjectURL(svgBlob);

  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      try {
        URL.revokeObjectURL(url);
        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0);
        canvas.toBlob((blob) => {
          if (blob) {
            resolve(blob);
          } else {
            reject(new Error('Canvas toBlob returned null'));
          }
        }, 'image/png', 1);
      } catch (err) {
        reject(err);
      }
    };
    img.onerror = (err) => {
      URL.revokeObjectURL(url);
      reject(err);
    };
    img.src = url;
  });
};

export default function App() {
  const [excalidrawAPI, setExcalidrawAPI] = useState(null);
  const [initialData, setInitialData] = useState(null);
  const isLoadedRef = useRef(false);
  const saveTimeoutRef = useRef(null);
  const pendingSceneRef = useRef(null);

  // Parse URL query parameters or window variables
  const urlParams = new URLSearchParams(window.location.search);
  const initialFilePath = urlParams.get('path') || window.__nview_filePath || '';
  const [filePath, setFilePath] = useState(initialFilePath);
  const filePathRef = useRef(initialFilePath);
  filePathRef.current = filePath;
  const isReadOnly = urlParams.get('readonly') === 'true' || urlParams.get('mode') === 'view';
  const lockHorizontal = urlParams.get('lockHorizontal') === 'true';

  // Helper to send messages to Flutter WebView channel if present
  const notifyFlutter = useCallback((payload) => {
    if (window.flutter_channel && typeof window.flutter_channel.postMessage === 'function') {
      try {
        window.flutter_channel.postMessage(JSON.stringify(payload));
      } catch (e) {
        console.error('Error sending message to Flutter:', e);
      }
    }
  }, []);

  // Compute bounding box and content height
  const calculateContentBounds = useCallback((elements) => {
    const visibleElements = (elements || []).filter((el) => !el.isDeleted);
    if (visibleElements.length === 0) {
      return { minX: 0, minY: 0, maxX: 0, maxY: 0, width: 0, height: 260 };
    }
    const [minX, minY, maxX, maxY] = getCommonBounds(visibleElements);
    const width = Math.max(0, maxX - minX);
    const height = Math.max(160, maxY - minY + 60); // 60px padding
    return { minX, minY, maxX, maxY, width, height };
  }, []);

  // Export and save PNG preview of current scene
  const exportAndSavePreview = useCallback((elements, appState, files) => {
    const targetPath = filePathRef.current || filePath;
    if (!targetPath) return;
    const visibleElements = (elements || []).filter((el) => !el.isDeleted);
    if (visibleElements.length === 0) {
      // Do not export a blank 32x32 PNG preview for an empty scene
      return;
    }
    try {
      exportDarkPngBlob({
        elements,
        appState,
        files: files || {},
        exportPadding: 16,
      })
        .then((blob) => {
          const reader = new FileReader();
          reader.onloadend = () => {
            if (reader.result && typeof reader.result === 'string') {
              const base64 = reader.result.split(',')[1] || reader.result;
              notifyFlutter({
                type: 'SAVE_PREVIEW',
                filePath: targetPath,
                base64,
              });
            }
          };
          reader.readAsDataURL(blob);
        })
        .catch((e) => console.error('PNG export error:', e));
    } catch (e) {
      console.error('exportDarkPngBlob exception:', e);
    }
  }, [filePath, notifyFlutter]);

  // Flush save immediately to Flutter
  const saveSceneNow = useCallback(() => {
    const targetPath = filePathRef.current || filePath;
    if (!targetPath || !excalidrawAPI || !isLoadedRef.current) return;
    const elements = excalidrawAPI.getSceneElements();
    const appState = excalidrawAPI.getAppState();
    const files = excalidrawAPI.getFiles();

    const payload = JSON.stringify({
      type: 'excalidraw',
      version: 2,
      source: 'noteflow',
      elements,
      appState: {
        viewBackgroundColor: appState.viewBackgroundColor || '#ffffff',
        currentItemStrokeColor: appState.currentItemStrokeColor || '#1e1e1e',
        currentItemBackgroundColor: appState.currentItemBackgroundColor || 'transparent',
        gridSize: appState.gridSize,
        scrollX: appState.scrollX,
        scrollY: appState.scrollY,
        zoom: appState.zoom,
      },
      files: files || {},
    });

    notifyFlutter({
      type: 'SAVE_DRAWING',
      filePath: targetPath,
      json: payload,
    });

    exportAndSavePreview(elements, appState, files);
  }, [filePath, excalidrawAPI, notifyFlutter, exportAndSavePreview]);

  // Load scene from JSON string
  const loadSceneFromJson = useCallback((jsonString, shouldScroll = false) => {
    if (!jsonString) return;
    try {
      // Cancel any pending auto-save so we don't save stale/initial scene over newly loaded scene
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current);
        saveTimeoutRef.current = null;
      }

      let parsed = typeof jsonString === 'string' ? JSON.parse(jsonString) : jsonString;
      if (typeof parsed === 'string') {
        try {
          parsed = JSON.parse(parsed);
        } catch (_) { }
      }
      if (!parsed || typeof parsed !== 'object') {
        parsed = { elements: [], appState: { viewBackgroundColor: '#ffffff' } };
      }
      const rawElements = parsed.elements || [];
      const elements = restoreElements(rawElements, null);
      const bounds = calculateContentBounds(elements);

      notifyFlutter({
        type: 'HEIGHT_CHANGE',
        contentHeight: bounds.height,
        bounds,
      });

      const appState = {
        theme: 'dark',
        viewBackgroundColor: parsed.appState?.viewBackgroundColor || '#ffffff',
        currentItemStrokeColor: parsed.appState?.currentItemStrokeColor || '#1e1e1e',
        currentItemBackgroundColor: parsed.appState?.currentItemBackgroundColor || 'transparent',
        gridSize: parsed.appState?.gridSize || null,
        scrollX: parsed.appState?.scrollX ?? 0,
        scrollY: parsed.appState?.scrollY ?? 0,
        zoom: parsed.appState?.zoom || { value: 1 },
      };

      if (excalidrawAPI) {
        excalidrawAPI.updateScene({
          elements,
          appState,
          files: parsed.files || {},
          commitToHistory: false,
        });
        if (shouldScroll || isReadOnly) {
          setTimeout(() => {
            try {
              const visibleElements = (elements || []).filter((el) => !el.isDeleted);
              if (visibleElements.length > 0) {
                excalidrawAPI.scrollToContent(visibleElements, {
                  fitToContent: true,
                  fitToViewport: false,
                  viewportZoomFactor: 0.95,
                  maxZoom: 1,
                });
              } else {
                excalidrawAPI.updateScene({
                  appState: {
                    zoom: { value: 1 },
                    scrollX: 0,
                    scrollY: 0,
                  },
                });
              }
            } catch (_) { }
          }, 80);
        }
        // Also ensure preview is generated if editing
        if (!isReadOnly) {
          setTimeout(() => {
            exportAndSavePreview(elements, appState, parsed.files || {});
          }, 300);
        }
      } else {
        pendingSceneRef.current = { elements, appState, files: parsed.files || {} };
        setInitialData({
          elements,
          appState,
          files: parsed.files || {},
        });
      }
      isLoadedRef.current = true;
    } catch (err) {
      console.error('Failed to parse scene JSON:', err);
    }
  }, [calculateContentBounds, excalidrawAPI, isReadOnly, notifyFlutter, exportAndSavePreview]);

  // Request initial scene load from Flutter
  useEffect(() => {
    const targetPath = filePathRef.current || filePath || window.__nview_filePath || '';
    notifyFlutter({
      type: 'REQUEST_LOAD',
      filePath: targetPath,
    });
    // Fallback: If Flutter doesn't inject scene within 1500ms, start with empty scene in dark mode
    const fallbackTimer = setTimeout(() => {
      if (!isLoadedRef.current) {
        loadSceneFromJson(JSON.stringify({ elements: [], appState: { viewBackgroundColor: '#ffffff' } }));
      }
    }, 1500);
    return () => clearTimeout(fallbackTimer);
  }, [filePath, notifyFlutter, loadSceneFromJson]);

  // Keyboard shortcut Ctrl+S / Cmd+S to save and expose saveSceneNow & loadScene to window for Flutter
  useEffect(() => {
    window.__nview_setFilePathImpl = (p) => {
      setFilePath(p);
      filePathRef.current = p;
    };
    window.__nview_loadSceneImpl = (json, targetPath) => {
      if (targetPath) {
        setFilePath(targetPath);
        filePathRef.current = targetPath;
      }
      loadSceneFromJson(json, true);
    };
    window.loadScene = window.__nview_loadSceneImpl;
    window.setFilePath = window.__nview_setFilePathImpl;
    window.saveSceneNow = saveSceneNow;

    // Drain any scene that Flutter passed before React hydrated
    if (window.__nview_pendingScene) {
      const pending = window.__nview_pendingScene;
      window.__nview_pendingScene = null;
      window.__nview_loadSceneImpl(pending.json, pending.targetPath);
    }

    const handleKeyDown = (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 's') {
        e.preventDefault();
        saveSceneNow();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.saveSceneNow = null;
      window.__nview_loadSceneImpl = null;
      window.__nview_setFilePathImpl = null;
    };
  }, [saveSceneNow, loadSceneFromJson]);

  // Handle scene changes (auto-save with 1.5s debounce when editing)
  const handleChange = useCallback((elements, appState, files) => {
    // Crucial: never trigger auto-save or propagate scene changes until the scene has finished loading!
    if (!isLoadedRef.current) return;

    if (lockHorizontal && appState.scrollX !== 0 && excalidrawAPI) {
      excalidrawAPI.updateScene({
        appState: { ...appState, scrollX: 0 },
      });
    }

    const bounds = calculateContentBounds(elements);
    notifyFlutter({
      type: 'SCENE_CHANGE',
      contentHeight: bounds.height,
      bounds,
    });

    const activePath = filePathRef.current || filePath;
    if (!isReadOnly && activePath) {
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current);
      }
      saveTimeoutRef.current = setTimeout(() => {
        saveSceneNow();
      }, 1500);
    }
  }, [calculateContentBounds, excalidrawAPI, filePath, isReadOnly, lockHorizontal, notifyFlutter, saveSceneNow]);

  return (
    <div className={`excalidraw-wrapper ${isReadOnly ? 'excalidraw-readonly' : ''}`}>
      <Excalidraw
        excalidrawAPI={(api) => {
          setExcalidrawAPI(api);
          notifyFlutter({ type: 'READY' });
          if (pendingSceneRef.current) {
            const pending = pendingSceneRef.current;
            pendingSceneRef.current = null;
            api.updateScene({
              elements: pending.elements,
              appState: pending.appState,
              files: pending.files,
              commitToHistory: false,
            });
            const bounds = calculateContentBounds(pending.elements);
            notifyFlutter({ type: 'HEIGHT_CHANGE', contentHeight: bounds.height, bounds });
            if (!isReadOnly) {
              setTimeout(() => {
                exportAndSavePreview(pending.elements, pending.appState, pending.files);
              }, 400);
            }
          }
          setTimeout(() => {
            try {
              const els = (api.getSceneElements() || []).filter((el) => !el.isDeleted);
              if (els.length > 0) {
                api.scrollToContent(els, {
                  fitToContent: true,
                  fitToViewport: false,
                  viewportZoomFactor: 0.9,
                  maxZoom: 1,
                });
                const bounds = calculateContentBounds(els);
                notifyFlutter({ type: 'HEIGHT_CHANGE', contentHeight: bounds.height, bounds });
              } else {
                api.updateScene({
                  appState: {
                    zoom: { value: 1 },
                    scrollX: 0,
                    scrollY: 0,
                  },
                });
              }
            } catch (_) { }
          }, 200);
        }}
        initialData={initialData || {
          appState: {
            theme: 'dark',
            viewBackgroundColor: '#ffffff',
            currentItemStrokeColor: '#1e1e1e',
            currentItemBackgroundColor: 'transparent',
            currentItemFontFamily: 1,
            zoom: { value: 1 },
            scrollX: 0,
            scrollY: 0,
          },
        }}
        onChange={handleChange}
        theme="dark"
        UIOptions={{
          canvasActions: {
            loadScene: false,
            saveToActiveFile: false,
            saveAsImage: false,
            theme: false,
          },
          welcomeScreen: false,
        }}
      />
    </div>
  );
}
