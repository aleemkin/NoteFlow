import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [
    react(),
    {
      name: 'classic-script-transform',
      transformIndexHtml(html) {
        return html
          .replace(/<script[^>]*src="[^"]*bundle\.js"[^>]*><\/script>/, '')
          .replace(
            '<div id="root"></div>',
            '<div id="root"></div>\n    <script src="./assets/bundle.js"></script>'
          );
      },
    },
  ],
  base: './',
  define: {
    'process.env': {},
  },
  build: {
    outDir: '../assets/excalidraw',
    emptyOutDir: false,
    sourcemap: false,
    rollupOptions: {
      output: {
        format: 'iife',
        name: 'ExcalidrawBundle',
        inlineDynamicImports: true,
        entryFileNames: 'assets/bundle.js',
        assetFileNames: 'assets/[name].[ext]',
      },
    },
  },
});
