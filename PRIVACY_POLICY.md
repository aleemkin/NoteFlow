# Privacy Policy for Noteflow

**Effective Date:** September 22, 2026  
**Last Updated:** September 22, 2026  

Noteflow ("we", "our", or "the app") is committed to protecting your privacy. This Privacy Policy explains our principles and practices regarding the handling of your personal data when using the Noteflow mobile and desktop applications.

---

## 1. Local-First & Offline Architecture
Noteflow is engineered as a **local-first, offline-first** application. 
- All notes, markdown documents, canvas drawings, tag configurations, and attachments are stored exclusively on your local device within the vault directories you select or create.
- We do **not** transmit your notes or vault contents to any external servers, cloud databases, or remote endpoints.

---

## 2. Zero Data Collection & Analytics
- **No Personal Information:** Noteflow does not require you to create an account, register an email address, or provide any identifying personal information.
- **No Telemetry or Tracking:** Noteflow contains **zero** third-party tracking SDKs, behavioral analytics (such as Google Analytics or Firebase Crashlytics), advertising trackers, or fingerprinting tools.
- **No Data Selling:** We do not collect, monetize, share, or sell any information about you, your device, or your notes.

---

## 3. Device Permissions & Purpose
Noteflow requests only permissions strictly necessary for core functionality:

1. **Storage Access (`MANAGE_EXTERNAL_STORAGE` / `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`):**
   - *Purpose:* Enables Noteflow to operate as a document management application where you choose local folders (such as Documents or external storage) to store and organize your markdown files and drawings.
   - *Behavior:* Storage is accessed strictly when you open, edit, create, or delete notes and attachments within the vaults you explicitly choose.
2. **Internet Access (`INTERNET`):**
   - *Purpose:* Noteflow operates 100% offline. The canvas and markdown editors load completely from local device storage without opening local ports or making network requests. Internet access is declared solely to allow opening standard external web links (e.g. `https://...`) that you intentionally tap inside your markdown notes using the system browser.

---

## 4. Third-Party Software & Copyright Notices

Noteflow incorporates open-source components under permissive licenses:

### Excalidraw
Visual drawing features in Noteflow use Excalidraw, licensed under the MIT License:
```
Copyright (c) Excalidraw contributors.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the condition that the above copyright notice
and this permission notice shall be included in all copies or substantial
portions of the Software.
```

### Flutter & Dart Ecosystem
The application framework is built using Flutter, maintained by Google LLC and open-source contributors under the BSD 3-Clause License.

---

## 5. Data Retention & Deletion
Because all your data is stored locally on your device:
- You retain complete ownership and custody of your data at all times.
- Deleting a note, folder, or vault permanently removes it from your device file system.
- Uninstalling Noteflow does not delete vaults stored in your device's standard Document folders.

---

## 6. Children’s Privacy
Noteflow does not knowingly collect or solicit any personal information from children under the age of 13. The app functions entirely locally without user registration.

---

## 7. Contact Information
If you have questions regarding this Privacy Policy or Noteflow's security practices, please contact the developer via GitHub repository issues or developer contact email provided in the store listing.
