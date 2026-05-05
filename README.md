# UPamakal — Your Campus, Your Marketplace

A Flutter-based campus marketplace app that lets students buy and sell within their university community. Built with MVVM architecture and powered by Firebase Authentication.

---

## Architecture

```
lib/
├── main.dart                     # Entry point, Firebase init, Provider setup
├── app.dart                      # MaterialApp, AuthGate routing
├── firebase_options.dart         # Firebase configuration (auto-generated)
├── models/
│   └── user_model.dart           # Domain model (decoupled from Firebase)
├── view_models/
│   ├── auth_view_model.dart      # Auth state + business logic
│   └── landing_view_model.dart   # First-launch flag management
├── views/
│   ├── landing_page.dart         # Onboarding (first launch only)
│   ├── login_page.dart           # Email/Google sign-in
│   ├── signup_page.dart          # Email/Google registration
│   ├── forgot_password_page.dart # Password reset flow
│   └── home_page.dart            # Authenticated placeholder
├── services/
│   └── auth_service.dart         # Firebase Auth data-access layer
├── widgets/
│   ├── logo_widget.dart          # Brand logo with fallback
│   └── auth_text_field.dart      # Reusable form field
└── utils/
    └── constants.dart            # App-wide colours, strings, tokens
```

### MVVM Layers

| Layer | Role | Accesses Firebase? |
|---|---|---|
| Model | Plain data classes (`UserModel`) | ❌ No |
| View | UI widgets only — no business logic | ❌ No |
| ViewModel | State management, validation, error mapping | ❌ No (calls Service) |
| Service | Direct Firebase interaction | ✅ Yes |

The frontend never accesses Firebase directly — all data flows through the **Service → ViewModel → View** pipeline.

---

## Features

- ✅ **Email/Password Registration** — with email verification
- ✅ **Email/Password Login** — with error handling for common failures
- ✅ **Google Sign-In** — one-tap OAuth (Android, iOS, Web)
- ✅ **Password Reset** — sends a reset link via Firebase
- ✅ **First-Launch Landing Page** — shown only once, persisted via SharedPreferences
- ✅ **Maroon Theme** — primary colour `#800000`
- ✅ **MVVM Architecture** — clean separation of concerns
- ✅ **Form Validation** — real-time email format, password strength, match checks

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.10.7
- Firebase project with Authentication enabled (Email/Password + Google)
- `UPamakal.png` logo placed in `assets/images/`

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd upamakal

# Install dependencies
flutter pub get

# Run on a connected device
flutter run
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** and **Google** sign-in methods under Authentication
3. Add your Android SHA-1 fingerprint (required for Google Sign-In)
4. Run `flutterfire configure` to regenerate `firebase_options.dart` if needed

### Google Sign-In Configuration

- **Android:** SHA-1 fingerprint must be added in Firebase Console → Project Settings
- **iOS:** Add the reversed client ID to `Info.plist` (see [google_sign_in docs](https://pub.dev/packages/google_sign_in))
- **Web:** Add your OAuth client ID in the Firebase Console

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^4.7.0 | Firebase initialisation |
| `firebase_auth` | ^5.5.2 | Email/password + OAuth auth |
| `google_sign_in` | ^6.3.0 | Native Google Sign-In flows |
| `shared_preferences` | ^2.3.5 | Persist first-launch flag |
| `provider` | ^6.1.2 | Lightweight state management |

---

## Color Scheme

| Role | Hex | Usage |
|---|---|---|
| Primary | `#800000` | Buttons, links, accents |
| Primary Dark | `#5C0000` | Hover/pressed states |
| Primary Light | `#FFF0F0` | Subtle backgrounds |
| Background | `#FAFAFA` | Page background |
| Google Blue | `#4285F4` | Google Sign-In button accent |

---

## License

To be determined.