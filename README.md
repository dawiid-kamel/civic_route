# Civic Route

A Flutter app that answers "who do I actually call?" Pick an issue (housing, transportation, healthcare, taxes and so on) and it shows which level of government handles it, then lists the right federal, state and county offices with phone numbers, websites, email and a script for what to say.

## How it works

1. Your location goes to the U.S. Census geocoder, which returns your county and congressional district. By default the location comes from the device GPS, and only after you tap "Use my location" and grant permission.
2. Federal officials come from Congress.gov, state legislators from Open States, and county offices from a hand-verified directory (`data/county_directory.json`).
3. The app calls Congress.gov and Open States directly. Their free API keys are passed in at build time with `--dart-define`, so they end up inside the app and can be extracted. Rotate them if they are ever abused.

Local county coverage is currently Baltimore County, MD. Other counties get federal and state officials, plus a fallback to USA.gov and 211.

## Privacy and security

Civic Route collects as little as it can. There are no accounts, logins, analytics or ads, and the app has no server of its own, so there is no central database of user data.

Location is the only personal data it uses. Android is asked for approximate as well as precise location, and the iOS prompt explains why location is needed. The Census geocoder gets your location to find your county and district. Open States gets coordinates rounded to about 100 meters. Congress.gov only gets your state and district.

Requests use HTTPS with a timeout and limited retries. Responses are parsed defensively so bad data from a service can't crash the app, and the contact directory ignores stale or invalid entries. Saved topics, progress notes and the last results stay on the device. Reminders are scheduled locally and never sent anywhere, and the error reporter only logs locally. "Clear saved data" in the Resident hub erases everything. The privacy policy is in the app and online at `docs/privacy.html`.

API keys are passed in at build time, `.env` and signing keys are gitignored, and CI runs static analysis and tests on every push.

One known limitation: the Congress.gov and Open States keys are compiled into the app, so someone could extract them. They are free, low-risk and can be rotated. A later version could send those calls through a small proxy so the keys never ship with the app.

## Follow-up reminders

Marking an issue Contacted or Waiting for a response on the Results screen schedules a local notification 3 days later ("Any update on ...?"). Tapping it opens that issue. Marking it Resolved or Not started cancels it, and the "Issue reminders" switch in the Resident hub turns reminders on or off. Android and iOS only. Everything stays on the device (`lib/services/reminder_service.dart`).

## Address picker

"Enter an address" (`lib/widgets/address_dialog.dart`) shows matching addresses from the Census geocoder as you type, and you tap one to use it. If you submit text the Census service can't find, the app falls back to OpenStreetMap Nominatim.

Address entry is off by default. The "Enter an address" buttons are grayed out and the app uses the device GPS. Pass `--dart-define=ENABLE_ADDRESS_ENTRY=true` to turn it on.

## Categories

Transportation, Housing, Healthcare, Education, Public Safety, Environment, Taxes, Immigration, Employment & Labor, Elections & Voting, Social Security and Zoning & Development, plus four local categories added in October 2026:

- Animals & Pets: stray or lost animals, leash laws and barking dogs, animal cruelty, pet licenses and rabies shots, animal bites, wildlife.
- Utilities: street lights, power outages and gas leaks. Water and sewer are under Household Utilities in the Resident hub.
- Neighborhood & Code Enforcement: code and zoning violations, rats, abandoned vehicles, parks.
- Benefits & Family Help: food, cash and child-care help, senior and disability services, 211.

## Search

The Home search box takes a word ("rent"), a phrase, or a whole question ("who do I call about a missed trash pickup?"). While you type, the other panels hide and only matching categories and topics show. Matching Resident hub services appear below them too. "Street lamps" shows the Utilities category and the hub's Household Utilities shortcut, and tapping a service opens the hub with its offices already showing. The matching code is in `lib/data/search.dart`. When you add a category or topic, add its words to `_keywords`, and for a hub service use `_serviceKeywords`.

On the Results screen, offices built for the exact topic are listed before general ones like the County Executive and 311.

## Run it

```
flutter pub get
# Get free keys: https://api.congress.gov/sign-up/ and https://openstates.org/accounts/profile/
flutter run --dart-define=CONGRESS_API_KEY=<key> --dart-define=OPENSTATES_API_KEY=<key>
# or put both in a file (one KEY=value per line, no spaces around =) and use:
# flutter run --dart-define-from-file=.env
```

Other optional settings are `DIRECTORY_URL`, `PRIVACY_POLICY_URL`, `ENABLE_LOCAL_ALERTS` and `ENABLE_ADDRESS_ENTRY` (see `lib/config.dart`).

## Test

```
flutter analyze
flutter test                                   # offline tests
flutter test --dart-define=CONGRESS_API_KEY=... --dart-define=OPENSTATES_API_KEY=...   # also runs the live API tests
```

## Project layout

| Path                         | What it is                                                             |
|------------------------------|------------------------------------------------------------------------|
| `lib/screens/`               | Tutorial, onboarding, home, category, results, resident hub            |
| `lib/services/`              | Congress.gov, Open States, Census, caching, directory refresh          |
| `lib/data/`                  | Issue catalog and the bundled county directory                         |
| `lib/models/`                | `Contact`, `Issue`, `LocationInfo`                                     |
| `data/county_directory.json` | Hosted contact directory the app downloads at startup                  |
| `docs/`                      | Privacy policy page (hosted with GitHub Pages and linked from the app) |

## Updating contact data

Edit `data/county_directory.json` and commit. Installed apps pick it up on the next launch. Keep `lastVerified` current, set the JSON's `updated` month, and bump `bundledDirectoryUpdated` in `lib/data/county_data.dart` to match. A hosted file older than the bundled one is ignored, so an old copy on `main` can't wipe out newer offices. Mirror changes in `lib/data/county_data.dart` before the next release (a test checks that both lists have the same number of entries). The Resident hub's service lists are built from the same contacts in `county_data.dart`, so a phone number only needs fixing once.

Contact information can change, so always confirm with the office.
