# CareLink - Telemedicine Platform

A modern telemedicine application built with Flutter and Supabase.

## 🚀 How to Run on Web

To start the project on the web emulator (Chrome/Edge), follow these steps:

### 1. Prerequisites
- Ensure [Flutter SDK](https://docs.flutter.dev/get-started/install) is installed and configured.
- Ensure you have a valid `.env` file in the root directory with your Supabase credentials.

### 2. Setup Dependencies
Run the following command in your terminal to fetch all required packages:
```bash
flutter pub get
```

### 3. Start the Web App
Run the following command to launch the app in your default web browser (usually Chrome):
```bash
flutter run -d chrome
```

Alternatively, if you want to use Microsoft Edge:
```bash
flutter run -d edge
```

### 4. Running with Renderer (Performance)
For better performance and font rendering on web, you can use the Skia renderer:
```bash
flutter run -d chrome --web-renderer canvaskit
```

## 🛠 Features
- **AI Symptom Analyzer**: Powered by Gemini API.
- **Doctor Dashboard**: Manage consultations and availability.
- **Patient Booking**: Find and book appointments with specialists.
- **Secure Auth**: Built-in email/password authentication.

## 📁 Project Structure
- `lib/core`: App-wide constants, themes, and services.
- `lib/features/auth`: Authentication screens and logic.
- `lib/features/doctor`: Dashboard and profile management for doctors.
- `lib/features/patient`: Booking and profile management for patients.
