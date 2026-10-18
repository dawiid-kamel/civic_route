# Release checklist

Work top to bottom. Items marked **you** need your accounts or decisions.

## 1. Secrets (do first)
- [ ] **you** Rotate both API keys (Congress.gov and Open States). The old ones are in git history and in zips you shared.
- [ ] **you** Deploy the relay: see `worker/README.md`. Note the URL it prints.
- [x] `.env` and `.DS_Store` are no longer tracked and `.gitignore` is rewritten. The old `.env` is still in git history; rotating the keys is what makes that harmless. (Optional: scrub history with `git filter-repo --path .env --invert-paths`.)
- [ ] Delete the duplicate `civic_route-1/` folder and any `__MACOSX/` folder from the repo (they should never be in the zip you submit).
- [ ] Delete your local `.env`; the app no longer reads it.

## 2. App identity
- [ ] **you** Confirm the app ID. It is set to `io.github.dawiidkamel.civicroute` in `android/app/build.gradle.kts` and `ios/Runner.xcodeproj/project.pbxproj`. It is permanent once published, so change both now if you want something else.
- [ ] Display name is "Civic Route" on both platforms.

## 3. Android signing
```
keytool -genkey -v -keystore ~/civic-route-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Create `android/key.properties` (git-ignored):
```
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/Users/<you>/civic-route-upload.jks
```
Back up the `.jks` file and passwords somewhere safe. Without them you cannot update the app.

Build:
```
flutter build appbundle --release --dart-define=API_BASE_URL=https://<your-relay>.workers.dev
```
Upload `build/app/outputs/bundle/release/app-release.aab` in Play Console.

## 4. iOS
- [ ] **you** In Xcode, set your Team and signing for the Runner target (bundle ID above).
- [ ] The location prompt text (`NSLocationWhenInUseUsageDescription`) is written and honest; keep it specific.
- [ ] `flutter build ipa --release --dart-define=API_BASE_URL=https://<your-relay>.workers.dev`, then upload with Transporter.

## 5. Privacy policy
- [ ] **you** Put your support email into `docs/privacy.html` (replace `SUPPORT_EMAIL_HERE`).
- [ ] Publish it: GitHub repo > Settings > Pages > Deploy from branch > `main` / `/docs`. The URL becomes `https://dawiid-kamel.github.io/civic_route/privacy.html` (already the default in `lib/config.dart`; override with `--dart-define=PRIVACY_POLICY_URL=...`).
- [ ] Enter that URL in Play Console and App Store Connect. Answers for the data forms are in `docs/STORE_LISTING.md`.

## 6. Keeping contact data fresh
- The directory is `data/county_directory.json`. The app downloads it from GitHub at startup, so editing and committing it updates every installed app, no release needed.
- Each entry has a `lastVerified` month. After the **November 2026 election**, re-check the County Executive, Council, Sheriff and State's Attorney names and bump `lastVerified`.
- Mirror any change in `lib/data/county_data.dart` (the offline fallback) at your next release.

## 7. Crash reporting (optional, recommended)
Pick one, then forward errors in `lib/services/error_reporting.dart`:
- **Sentry:** `flutter pub add sentry_flutter`, wrap `main()` with `SentryFlutter.init(...)` using your DSN, and call `Sentry.captureException` in `reportError`.
- **Firebase Crashlytics:** `flutterfire configure`, `flutter pub add firebase_core firebase_crashlytics`, and call `FirebaseCrashlytics.instance.recordError` in `reportError`.
If you add either, update `docs/privacy.html` (it currently says there is no crash reporting) and the store data forms.

## 8. Versioning
Bump `version:` in `pubspec.yaml` before every upload (`1.0.0+1` means version 1.0.0, build 1). The number after `+` must increase with each store upload. Tag releases: `git tag v1.0.0 && git push --tags`.

## 9. Before you hit submit
- [ ] `flutter analyze` and `flutter test` pass (CI runs them on every push).
- [ ] Run a **release** build on a real Android phone with a fresh install: location prompt, address entry, one lookup per level, airplane-mode check.
- [ ] Screenshots taken (see `docs/STORE_LISTING.md`).
