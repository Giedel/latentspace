# LatentSpace

## Google Calendar sync

The To-do page's sync button signs the user in with Google and imports events
from all selected calendars plus due Google Tasks, from today through the next
90 days. Imported items are stored as local tasks; later syncs update the same
tasks instead of creating duplicates. The app requests read-only access and
never writes back to Google.

Before running it on Android:

1. In the Google Cloud project, enable **Google Calendar API** and **Google
   Tasks API**, then configure
   the OAuth consent screen (add your Google account as a test user while the
   app is in testing).
2. Create an **Android** OAuth 2.0 client for package
   `com.example.latentspace` and add the SHA-1 certificate fingerprint used to
   sign the app. Google Sign-In selects this client automatically; no OAuth JSON
   file is needed by this app.
3. Do not copy a downloaded `client_secret_*.json` into `assets/` or commit it.
   A client secret must not be shipped in a mobile app. `google-services.json`
   is also unnecessary unless another Firebase/Google service requires it.

For iOS, also create an iOS OAuth client for the bundle identifier and add the
reversed client ID URL scheme to `ios/Runner/Info.plist` before building.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
