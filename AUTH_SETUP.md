# Firebase Auth setup

The app now uses an `AuthService` adapter layer.

Production mode does not seed demo accounts by default. Local/dev mode can use
`MockAuthService.withDemoCredentials()` by starting with:

```bash
flutter run --dart-define=ENABLE_DEMO_DATA=true
```

To use Firebase Auth in a real build:

1. Enable Email/Password sign-in in Firebase Console.
2. Create Firebase Auth users for school accounts.
3. Keep the matching profile document in `schools/{schoolId}/accounts/{uid}` or
   use the same email in the profile document. The adapter first matches by
   Firebase UID, then by email for migration compatibility.
4. Store role and status in the profile document:
   - `role`: `teacher`, `student`, `parent`, or `admin`
   - `status`: `active`, `blocked`, or `deleted`
5. Run the app with `--dart-define=USE_FIREBASE_AUTH=true`.

Client-side admin account creation still uses the dev auth adapter unless the
project is built with Firebase Auth enabled. In production, user provisioning
should be handled by a trusted backend or Firebase Admin SDK so an admin does
not have to create privileged auth users from the mobile client.
