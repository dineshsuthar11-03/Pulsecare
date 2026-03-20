# PulseCare – Telemedicine Platform

PulseCare is a full-stack telemedicine platform built with **Flutter** (mobile & web client) and a **Node.js/Express** backend integrated with **Supabase**, **PostgreSQL**, and **Groq AI**. It provides AI-assisted symptom analysis, medicine search, secure authentication, role-based dashboards for doctors and patients, and video-consultation flows.

This README is written to help any team member (developer, QA, or PM) understand **what the project does**, **how it is structured**, and **how to run and extend it**.

---

## 1. High-Level Overview

- **Client**: Flutter app (Android, iOS, Web, Desktop) located under `lib/`. Uses `supabase_flutter` for auth & data, `google_generative_ai` for some AI integrations, and local JSON/SQLite for offline data.
- **Backend API**: Node.js/Express server in `backend/` exposing REST endpoints for auth, users, symptoms, AI analysis, medicines, and consultations.
- **Database**: Supabase (hosted PostgreSQL) with tables like `users`, `consultations`, etc. Connection details are handled via environment variables.
- **AI Symptom Analysis**: Implemented in `backend/services/aiService.js` using Groq’s Chat Completions API (LLaMA 3.1 model) to analyze user symptoms.
- **Email & Video Consultation**: Email notifications and Jitsi-based meeting links are handled in `backend/controllers/consultationController.js`.

Typical flow:
1. User installs/opens the Flutter app.
2. User signs up/logs in via Supabase-backed auth.
3. According to their role (patient/doctor/admin), they are redirected to the corresponding dashboard.
4. Patients can use the AI Symptom Checker, search medicines, and book consultations.
5. Backend handles AI analysis, medicine search (CSV-based), and consultation notifications (emails with Jitsi links).

---

## 2. Tech Stack

**Frontend (Flutter)**
- Flutter SDK (Dart 3.x)
- Packages (see `pubspec.yaml`):
	- `supabase_flutter` – auth & DB access
	- `google_generative_ai` – Gemini-based AI usage within the app (future/phase usage)
	- `provider` – state management
	- `http` – REST calls to the Node backend
	- `shared_preferences`, `sqflite`, `path_provider` – local storage & caching
	- `flutter_markdown`, `shimmer`, `intl` – UI/UX utilities
	- `flutter_dotenv` – env management for Flutter
	- `url_launcher`, `permission_handler`, `webview_flutter` – opening external URLs (Jitsi), handling permissions, and embedded web views

**Backend (Node.js / Express)**
- `express`, `cors` – HTTP server & CORS handling
- `@supabase/supabase-js` – direct Supabase/PostgreSQL operations
- `pg` – low-level PostgreSQL pool (used for some DB connectivity)
- `axios` – external HTTP calls (Groq AI)
- `agora-access-token` – Agora/Jitsi/video-call related integrations (token generation)
- `csv-parse` – reading local CSVs for Indian medicine data
- `bcrypt`, `jsonwebtoken` – password hashing and JWT auth
- `resend` – sending email notifications (consultations, OTPs, etc.)
- `dotenv` – environment variable management

**Infrastructure & Services**
- Supabase project for auth, DB, and storage
- Groq AI API (via `GROQ_API_KEY`)
- Resend Email API for transactional emails (OTPs and consultation notifications)

---

## 3. Repository Structure

Key folders and files:

- `lib/` – Flutter app source
	- `lib/main.dart` – app entry point, Supabase initialization, and auth routing (AuthWrapper).
	- `lib/core/`
		- `theme/` – app theming and `AppTheme` definitions.
		- `constants/` – app-wide constants like `AppStrings`.
		- `services/` – shared services (e.g., API clients, auth helpers).
	- `lib/features/`
		- `auth/` – login, signup, OTP verification, password reset, and role selection screens.
		- `home/` – home/dashboard for patients.
		- `doctor/` – doctor dashboard and related screens.
		- `patient/` – patient-specific flows (consultation list, profile, etc.).
		- `symptom_checker/` – rapid/AI-based symptom checker flows.
		- `medicine_guide/` – medicine search and detail views.

- `backend/` – Node.js/Express backend
	- `index.js` – Express app setup, middleware, global error handlers, and route mounting.
	- `package.json` – scripts and dependency declarations.
	- `config/db.js` – PostgreSQL pool configuration using `DATABASE_URL` from Supabase.
	- `controllers/` – request-handling logic per domain:
		- `authController.js` – signup/login, OTP, password reset.
		- `userController.js` – user profile and role-related operations.
		- `symptomController.js` – legacy AI symptom analyzer endpoint, now using Groq.
		- `aiController.js` – dedicated Groq-based AI symptom analysis endpoint.
		- `medicineController.js` – medicine search & alternative suggestions.
		- `consultationController.js` – email notifications for scheduled consultations.
	- `routes/` – Express routers:
		- `authRoutes.js` – `/api/auth/*` endpoints.
		- `userRoutes.js` – `/api/users/*` endpoints.
		- `symptomRoutes.js` – `/api/symptoms/*` legacy AI route.
		- `aiRoutes.js` – `/api/ai/analyze` route.
		- `medicineRoutes.js` – `/api/medicines/*` endpoints.
		- `consultationRoutes.js` – `/api/consultations/*` endpoints.
	- `services/` – non-HTTP business logic:
		- `aiService.js` – Groq AI integration for symptom analysis.
		- `medicineService.js` – CSV-backed medicine search logic.
		- `agoraService.js` – tokens/utility for video calls.
	- CSV/JSON datasets:
		- `indian_medicine_data.csv` / `.json` – reference data for medicine lookup.
		- `updated_indian_medicine_data.csv` – improved data version.

- Root-level files
	- `pubspec.yaml` – Flutter dependencies & assets.
	- `analysis_options.yaml` – Dart/Flutter lints.
	- `supabase_schema.sql` – database schema for Supabase (migrations/DDL).
	- `Symptoms.json` – symptom metadata used by the Flutter symptom checker.
	- `firebase.json` – Firebase hosting or related configuration (if used).

---

## 4. Environment Variables

Both the Flutter app and backend rely on environment variables.

### 4.1 Flutter (.env)

The Flutter app loads a `.env` asset defined in `pubspec.yaml`:

```env
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
BACKEND_BASE_URL=http://localhost:3000
GEMINI_API_KEY=...
```

In `lib/main.dart`, there are baked-in fallback Supabase URL & anon key for production web builds. For development, you can keep using the `.env` file; ensure it is added under `flutter/assets` in `pubspec.yaml` (already configured).

### 4.2 Backend (.env)

Create `backend/.env` with values like:

```env
PORT=3000

DATABASE_URL=postgresql://user:password@host:port/dbname

SUPABASE_URL=...                      # Your Supabase project URL
SUPABASE_SERVICE_ROLE_KEY=...         # Service role key for server-side access

JWT_SECRET=some_long_random_string

GROQ_API_KEY=...                      # For Groq AI symptom analysis

EMAIL_PROVIDER=smtp                   # smtp or resend

RESEND_API_KEY=re_...
EMAIL_FROM=PulseCare <onboarding@resend.dev>

SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_sender@gmail.com
SMTP_PASS=your_gmail_app_password

JITSI_APP_KEY=vpaas-magic-cookie-...
SCHEDULING_UTC_OFFSET_MINUTES=330
```

Email provider behavior:

- If `EMAIL_PROVIDER=smtp`, backend sends OTP/notification emails using SMTP credentials.
- If `EMAIL_PROVIDER=resend`, backend sends emails via Resend API.
- If `EMAIL_PROVIDER` is not set, backend auto-picks SMTP when SMTP creds exist; otherwise it uses Resend.

> Do **not** commit `.env` files. They should be kept local or in secret managers.

---

## 5. Running the Flutter App

### 5.1 Prerequisites

- Flutter SDK installed and configured (stable channel preferred).
- Dart 3.x compatible.
- Valid `.env` file in the project root (for Supabase & backend URL).

### 5.2 Install Dependencies

From the project root (`CareLink-main/`):

```bash
flutter pub get
```

### 5.3 Run on Web (Chrome/Edge)

```bash
flutter run -d chrome
```

or

```bash
flutter run -d edge
```

For better performance on web (Skia renderer):

```bash
flutter run -d chrome --web-renderer canvaskit
```

### 5.4 Run on Android Emulator / Device

```bash
flutter run -d <device_id>
```

Make sure Android SDK and an emulator or physical device are configured.

---

## 6. Running the Backend API

### 6.1 Prerequisites

- Node.js (LTS) and npm installed.
- `backend/.env` configured (see Environment Variables section).

### 6.2 Install Dependencies

From `backend/` directory:

```bash
npm install
```

### 6.3 Start the Server

Development (with auto-reload using nodemon):

```bash
npm run dev
```

Production-style run:

```bash
npm start
```

The server will start on `http://localhost:3000` (or the `PORT` you configure in `.env`). Health check:

- `GET /` → returns `PulseCare API is running...`

Render deployment note:

- Render sets `PORT` automatically; keep `const PORT = process.env.PORT || 3000` as-is.
- Add backend environment variables in Render dashboard (`SUPABASE_*`, `JWT_SECRET`, `GROQ_API_KEY`, `EMAIL_PROVIDER`, `EMAIL_FROM`, `JITSI_APP_KEY`, plus either `RESEND_API_KEY` or `SMTP_*`).
- Set `SCHEDULING_UTC_OFFSET_MINUTES` to match your primary booking timezone (IST is `330`).

---

## 7. Backend API – Main Endpoints

Below is a conceptual summary of the key backend endpoints used by the app. For exact request/response bodies, refer to the respective controller and route files.

### 7.1 Auth (`/api/auth`)

Defined in `backend/routes/authRoutes.js` and `backend/controllers/authController.js`.

- `GET /api/auth` – simple health check for auth routes.
- `POST /api/auth/signup` – register a new user (patient/doctor), likely storing user data in Supabase and local DB.
- `POST /api/auth/login` – authenticate user, issuing a JWT or session.
- `POST /api/auth/forgot-password` – initiate password reset, usually by sending an OTP/email.
- `POST /api/auth/verify-signup-otp` – verify OTP during signup.
- `POST /api/auth/resend-signup-otp` – resend verification OTP.
- `POST /api/auth/reset-password-with-otp` – reset password using OTP.

### 7.2 Users (`/api/users`)

Defined in `backend/routes/userRoutes.js` and `backend/controllers/userController.js`.

- Contains operations related to user profiles, roles (doctor/patient/admin), and possibly listing doctors/patients.

### 7.3 Symptoms & AI (`/api/symptoms`, `/api/ai`)

**Legacy Symptom Analyzer** – `backend/controllers/symptomController.js`:

- `POST /api/symptoms/analyze`
	- Request body: `{ symptoms, gender, age, language }` where `symptoms` can be string or array.
	- Response: AI-generated analysis (uses `analyzeSymptoms` from `aiService.js` with Groq under the hood) and metadata about the request.

**Dedicated AI Endpoint** – `backend/controllers/aiController.js` & `routes/aiRoutes.js`:

- `POST /api/ai/analyze`
	- Request body: `{ symptoms: string | string[] }`.
	- Validates input and passes a single text string to `analyzeSymptoms`.
	- Response: `{ success: true, analysis: <string> }`.

**Groq AI Logic** – `backend/services/aiService.js`:

- Uses `axios` to call Groq:
	- Endpoint: `https://api.groq.com/openai/v1/chat/completions`
	- Model: `llama-3.1-8b-instant`
	- System prompt ensures:
		- Cautious medical advice
		- No definitive diagnosis
		- Always recommends consulting a real doctor
	- Output: bullet list of possible conditions, risk level, recommended action, disclaimer.

### 7.4 Medicine Guide (`/api/medicines`)

Defined in `backend/routes/medicineRoutes.js` and `backend/controllers/medicineController.js`.

- `GET /api/medicines` – health check for medicine routes.
- `GET /api/medicines/search?q=...&limit=...`
	- Uses `medicineService.searchMedicines(q, safeLimit)` to search local CSV/JSON Indian medicine datasets.
- `GET /api/medicines/alternatives?activeIngredient=...&excludeId=...&limit=...`
	- Uses `medicineService.getAlternatives(...)` to find alternative medicines with same active ingredient.

### 7.5 Consultations (`/api/consultations`)

Defined in `backend/routes/consultationRoutes.js` and `backend/controllers/consultationController.js`.

- `GET /api/consultations?userId=<uuid>`
	- Returns consultations for the given user (patient or doctor), enriched with doctor and patient profile info.

- `POST /api/consultations`
	- Body: `{ patientId, doctorId, scheduledAt, fee, symptoms? }`.
	- Validates doctor availability and slot conflicts before creating the booking.
	- Creates consultation + room code, then sends schedule emails to patient and doctor.

- `PATCH /api/consultations/:id`
	- Updates consultation fields (`status`, `notes`, `prescription`) from doctor workflows.

- `GET /api/consultations/doctor/:doctorId/availability`
	- Returns normalized availability (`days`, `start_time`, `end_time`, `slot_minutes`) for the doctor.

- `GET /api/consultations/doctor/:doctorId/slots?date=YYYY-MM-DD`
	- Returns bookable slots after filtering doctor availability + existing scheduled/ongoing consultations.

- `POST /api/consultations/notify`
	- Legacy/manual notification endpoint kept for compatibility.

---

## 8. Flutter App – Key Flows

### 8.1 App Startup & Auth Routing

`lib/main.dart`:

1. Initializes Flutter bindings.
2. Initializes Supabase using either `.env` or fallback credentials.
3. Wraps `MaterialApp` with a `StreamBuilder` listening to `Supabase.instance.client.auth.onAuthStateChange`.
4. Based on the auth state:
	 - If no session → show `RoleSelectionScreen` (user chooses patient/doctor and proceeds to auth flow).
	 - If session exists → navigate to `AuthWrapper`.

`AuthWrapper`:
- Fetches current user from Supabase.
- Tries to determine user role:
	1. First from `user.userMetadata['role']`.
	2. If missing, queries `users` table (`select role where id = user.id`).
- Based on role:
	- `doctor` → `DoctorDashboardScreen`.
	- `admin` → currently mapped to `HomeScreen` (placeholder).
	- anything else → `HomeScreen` (patient view).

### 8.2 Auth Screens

Located under `lib/features/auth/`:

- `login_screen.dart` – user login.
- `signup_screen.dart` – signup with role selection and basic details.
- `otp_verification_screen.dart` – verifying signup or password reset OTP.
- `reset_password_screen.dart` – resetting password using verified OTP.
- `role_selection_screen.dart` – choose between Patient, Doctor, (Admin) roles.

The Flutter app communicates with Supabase directly for core auth, and with the backend for OTP flows/emails where needed.

### 8.3 Symptom Checker

Located under `lib/features/symptom_checker/` and uses:

- `Symptoms.json` – static symptom definitions, categories, and metadata.
- Backend AI endpoints (`/api/symptoms/analyze` or `/api/ai/analyze`) for detailed analysis.

User flow:
1. User selects symptoms from guided screens (e.g., `symptom_selection_screen.dart`).
2. The app compiles the list into text or array.
3. Sends to backend AI endpoint.
4. Displays risk level, possible conditions, and recommended action with a clear disclaimer.

### 8.4 Medicine Guide

Located under `lib/features/medicine_guide/`:

- `medicine_search_screen.dart` – UI to search medicines.
- `medicine_detail_screen.dart` – detail view showing dosage, precautions, and alternatives.

The app calls backend endpoints:

- `/api/medicines/search`
- `/api/medicines/alternatives`

These endpoints use local Indian medicine datasets in CSV/JSON to respond quickly without hitting external APIs.

### 8.5 Consultations & Video Calls

On the client side (doctor & patient features):

- Patients can book video consultations with doctors.
- Backend’s `/api/consultations/notify` endpoint sends schedule emails including Jitsi URL/room code.
- Frontend uses `url_launcher` (and optionally `webview_flutter`) to open or embed Jitsi meeting URLs.

---

## 9. Database (Supabase) Overview

The Supabase schema is defined by `supabase_schema.sql` and migration files under `supabase/migrations/`.

Key concepts:

- `users` table
	- Stores user metadata such as role (`patient`, `doctor`, `admin`), email, full name, and other profile fields.
	- Backend uses server-side Supabase client (`SUPABASE_SERVICE_ROLE_KEY`) in `consultationController.js` to fetch patient & doctor info securely.

- `consultations` table
	- Stores scheduled consultations, timestamps, participants, and status.
	- Used in combination with `roomCode` to derive video-call links.

> For any schema changes, update the SQL files and regenerate migrations.

---

## 10. Error Handling & Logging

### Backend

- Global process-level handlers in `backend/index.js`:
	- `process.on('uncaughtException', ...)` – logs critical uncaught errors.
	- `process.on('unhandledRejection', ...)` – logs unhandled promise rejections.
- Express error middleware:
	- Logs stack traces and returns `500` with a generic error message.
- Request logger middleware:
	- Logs each incoming request: timestamp, HTTP method, path.
- `db.js`:
	- Logs successful DB connection.
	- Logs connection pool errors but does **not** crash the server, since most DB interactions happen via Supabase SDK.

### Frontend

- Uses `debugPrint` in relevant places (e.g., during Supabase initialization) for developer-friendly logs in debug builds.

---

## 11. How to Extend the Project

### Adding a New Backend Feature

1. **Create a service** (business logic) under `backend/services/` if needed.
2. **Create a controller** in `backend/controllers/` to handle HTTP-specific work (validation, status codes).
3. **Create a route** in `backend/routes/` that maps URL paths to controller functions.
4. **Mount the route** in `backend/index.js` using `app.use('/api/yourPrefix', yourRoutes);`.
5. **Update Flutter app** to call this new endpoint using `http` or a shared API client in `lib/core/services/`.

### Adding a New Flutter Feature

1. Create a new feature folder under `lib/features/your_feature/`.
2. Add screens, models, and providers as needed.
3. Wire navigation from existing screens (e.g., from `HomeScreen`).
4. If backend support is required, implement a client wrapper in `lib/core/services/` to centralize HTTP calls.

---

## 12. Common Pitfalls & Tips

- **Environment variables**: Most runtime errors come from missing or incorrect `.env` values (especially `GROQ_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, and `DATABASE_URL`). Double-check them.
- **CORS issues**: When calling the backend from Flutter Web, ensure the `cors` middleware in `backend/index.js` is enabled (it is by default). If hosting on different domains, configure allowed origins.
- **Emails**: If using SMTP, set `EMAIL_PROVIDER=smtp` with valid `SMTP_*` credentials (Gmail App Password recommended). If using Resend, verify your sender domain and set `RESEND_API_KEY` + `EMAIL_FROM`.
- **Supabase roles**: Make sure `users` table and auth metadata are kept in sync (especially `role`) so that `AuthWrapper` can route users correctly.

---

## 13. Scripts & Useful Commands

**Flutter**

- Fetch dependencies:

	```bash
	flutter pub get
	```

- Run on Chrome:

	```bash
	flutter run -d chrome
	```

- Build web:

	```bash
	flutter build web --web-renderer canvaskit --release
	```

**Backend**

- Install dependencies:

	```bash
	cd backend
	npm install
	```

- Run dev server:

	```bash
	npm run dev
	```

- Run production server:

	```bash
	npm start
	```

---

## 14. Contact & Ownership

- This project is part of the PulseCare telemedicine initiative.
- For questions about:
	- **Flutter app** – contact the mobile/frontend sub-team.
	- **Backend/API** – contact the Node.js backend sub-team.
	- **Supabase/DB & Infrastructure** – contact the DevOps/data sub-team.

Keep this README up to date when adding major features or changing environments so new team members can onboard quickly.

