---
description: How to connect Stockify to your real Firebase Project
---
# Connect to Firebase 

Currently, the app is running in **Simulation Mode** using a dummy configuration. To save data to your real Firebase project, follow these steps:

## Prerequisites
1.  **Node.js**: Ensure you have Node.js installed.
2.  **Firebase Account**: Go to [console.firebase.google.com](https://console.firebase.google.com/) and create a project (e.g., "stockify-app").

## Step 1: Install Firebase Tools
Open your terminal (in this VS Code window) and run:
```powershell
npm install -g firebase-tools
```

## Step 2: Login to Firebase
Run this command and follow the browser prompt to log in:
```powershell
firebase login
```

## Step 3: Activate FlutterFire CLI
This tool automates the connection:
```powershell
dart pub global activate flutterfire_cli
```

## Step 4: Configure the App
This command links your code to your cloud project:
```powershell
flutterfire configure
```
1.  Select your **Project** (e.g., `stockify-app`) using arrow keys.
2.  Select **Platforms**: Ensure `android`, `ios`, and `web` (or just `windows` if supported/listed, though Firestore on Windows usually reuses web/android configs via C++ SDK).
    *   *Note: For Windows desktop apps, FlutterFire uses the C++ SDK which is auto-configured.*

## Step 5: Verify
Once `flutterfire configure` finishes, it will overwrite `lib/firebase_options.dart`.
1.  **Restart the App** (Stop and Run again).
2.  The app will now connect to your REAL database!
