# Civic Route

A Flutter app that answers "who do I actually call?" Pick an issue (housing, transportation, healthcare, taxes...), and Civic Route shows which level of government handles it and gives you the right federal, state and county offices, with phone numbers, websites, email and a script for what to say.

## How it works
1. Your location (GPS or a typed address) goes to the U.S. Census geocoder, which returns your county and congressional district.
2. Federal officials come from Congress.gov, state legislators from Open States, and county offices from a hand-verified directory (`data/county_directory.json`).
3. The Congress.gov and Open States API keys never ship in the app. They live in a small Cloudflare Worker relay (`worker/`) that the app calls.

Local county coverage is currently **Baltimore County, MD**. Other counties get federal and state officials plus a fallback to USA.gov and 211.

## Search
The Home search box accepts a word ("rent"), a phrase, or a whole question ("who do I call about a missed trash pickup?"). While you type, the other panels hide and only the matching categories and topics show. The matching lives in `lib/data/search.dart`; add words to its `_keywords` map when a new issue or category is added.

## Run it
```
flutter pub get
# Deploy the relay first (worker/README.md), then:
flutter run --dart-define=API_BASE_URL=https://<your-relay>.workers.dev
```
Other optional settings: `DIRECTORY_URL`, `PRIVACY_POLICY_URL`, `ENABLE_LOCAL_ALERTS` (see `lib/config.dart`).

## Test
```
flutter analyze
flutter test                                   # offline tests
flutter test --dart-define=API_BASE_URL=...    # also runs the live API tests
```

## Project layout
| Path | What it is |
|---|---|
| `lib/screens/` | Tutorial, onboarding, home, category, results, resident hub |
| `lib/services/` | Congress.gov, Open States, Census, caching, directory refresh |
| `lib/data/` | Issue catalog and the bundled county directory |
| `lib/models/` | `Contact`, `Issue`, `LocationInfo` |
| `worker/` | API relay that holds the keys |
| `data/county_directory.json` | Hosted contact directory the app downloads at startup |
| `docs/` | Privacy policy, release checklist, store listing drafts |

## Updating contact data
Edit `data/county_directory.json` and commit. Installed apps pick it up on next launch. Keep `lastVerified` current and mirror changes in `lib/data/county_data.dart` before the next release.

Contact information can change; always confirm with the office.
