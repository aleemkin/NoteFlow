import fs from 'node:fs';
import path from 'node:path';

const src = path.resolve('node_modules/@excalidraw/excalidraw/dist/prod/fonts');
const dest = path.resolve('../assets/excalidraw/fonts');

if (fs.existsSync(src)) {
  fs.cpSync(src, dest, { recursive: true });
  console.log('✓ Copied Excalidraw fonts to assets/excalidraw/fonts');
} else {
  console.warn('Warning: Excalidraw fonts directory not found at', src);
}
