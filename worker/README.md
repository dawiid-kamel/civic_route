# Civic Route API relay

Holds the Congress.gov and Open States keys so they never ship inside the app.

## Deploy (about 5 minutes, free tier is enough)

1. Create a free Cloudflare account, then install Node.js.
2. From this folder:
   ```
   npx wrangler login
   npx wrangler secret put CONGRESS_API_KEY      # paste your NEW key
   npx wrangler secret put OPENSTATES_API_KEY    # paste your NEW key
   npx wrangler deploy
   ```
3. Wrangler prints a URL like `https://civic-route-api.<you>.workers.dev`.
4. Build the app pointing at it:
   ```
   flutter run --dart-define=API_BASE_URL=https://civic-route-api.<you>.workers.dev
   flutter build appbundle --release --dart-define=API_BASE_URL=https://civic-route-api.<you>.workers.dev
   ```
5. In the Cloudflare dashboard, add a rate-limiting rule (for example 60 requests per minute per IP) so nobody can burn your upstream quota.
6. Leave Workers Logs off (the default) so coordinates are not retained.

Rotate the old keys first: the old ones are in your git history and in the zip you shared.
