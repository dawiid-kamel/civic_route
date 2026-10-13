# Civic Route

A Flutter app that answers "who do I actually call?" Pick an issue (housing, transportation, healthcare, taxes...), and Civic Route shows which level of government handles it and gives you the right federal, state and county offices, with phone numbers, websites, email and a script for what to say.

## How it works
1. Your location (GPS or a typed address) goes to the U.S. Census geocoder, which returns your county and congressional district.
2. Federal officials come from Congress.gov, state legislators from Open States, and county offices from a hand-verified directory (`data/county_directory.json`).
3. The app calls Congress.gov and Open States directly. Their free API keys are passed in at build time (`--dart-define`), so they are compiled into the app and can be extracted from it; rotate them if they are ever abused.

Local county coverage is currently **Baltimore County, MD**. Other counties get federal and state officials plus a fallback to USA.gov and 211.

## Follow-up reminders
Marking an issue **Contacted** or **Waiting for a response** on the Results screen schedules a local notification 3 days later ("Any update on ...?"). Tapping it opens that issue. Marking it **Resolved** or **Not started** cancels it, and the "Issue reminders" switch in the Resident hub turns reminders on or off. Android and iOS only; everything stays on the device (`lib/services/reminder_service.dart`).

## Address picker
"Enter an address" (`lib/widgets/address_dialog.dart`) shows matching addresses from the Census geocoder as you type; tap one to use it. If you submit text the Census service can't find, the app falls back to OpenStreetMap Nominatim.

## Run it
```
flutter pub get
# Get free keys: https://api.congress.gov/sign-up/ and https://openstates.org/accounts/profile/
flutter run --dart-define=CONGRESS_API_KEY=<key> --dart-define=OPENSTATES_API_KEY=<key>
# or put both in a file (one KEY=value per line, no spaces around =) and use:
# flutter run --dart-define-from-file=.env
```
Other optional settings: `DIRECTORY_URL`, `PRIVACY_POLICY_URL`, `ENABLE_LOCAL_ALERTS`, `ENABLE_ADDRESS_ENTRY` (see `lib/config.dart`). Address entry is **off by default**: the "Enter an address" buttons are grayed out and the app always uses the device GPS location. Pass `--dart-define=ENABLE_ADDRESS_ENTRY=true` to turn it back on.

## Test
```
flutter analyze
flutter test                                   # offline tests
flutter test --dart-define=CONGRESS_API_KEY=... --dart-define=OPENSTATES_API_KEY=...   # also runs the live API tests
```

## Project layout
| Path | What it is |
|---|---|
| `lib/screens/` | Tutorial, onboarding, home, category, results, resident hub |
| `lib/services/` | Congress.gov, Open States, Census, caching, directory refresh |
| `lib/data/` | Issue catalog and the bundled county directory |
| `lib/models/` | `Contact`, `Issue`, `LocationInfo` |
| `data/county_directory.json` | Hosted contact directory the app downloads at startup |
| `docs/` | Privacy policy, release checklist, store listing drafts |

## Updating contact data
Edit `data/county_directory.json` and commit. Installed apps pick it up on next launch. Keep `lastVerified` current and mirror changes in `lib/data/county_data.dart` before the next release.

Contact information can change; always confirm with the office.
