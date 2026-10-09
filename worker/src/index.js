/**
 * Civic Route API relay (Cloudflare Worker).
 *
 * Why this exists: the Congress.gov and Open States API keys must not ship
 * inside the app. The app calls this Worker; the Worker adds the keys (stored
 * as Worker secrets) and forwards a small allow-list of read-only requests.
 *
 *   GET /congress/<path>      -> https://api.congress.gov/v3/<path>  (adds api_key)
 *   GET /openstates/people.geo?lat=..&lng=..  -> https://v3.openstates.org/people.geo
 *
 * Responses are cached at Cloudflare's edge, so repeat lookups are fast and
 * cheap on the upstream rate limits. Nothing is logged or stored by this code.
 */

const CONGRESS_PATHS = [
  /^member\/congress\/\d{2,3}\/[A-Za-z]{2}$/,         // all members of a state
  /^member\/congress\/\d{2,3}\/[A-Za-z]{2}\/\d{1,2}$/, // one district
  /^member\/[A-Za-z]\d{6}$/,                          // one member (bioguide id)
];
const CONGRESS_QUERY = ['currentMember', 'limit', 'offset', 'format'];

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

function reply(body, status = 200, extra = {}) {
  return new Response(typeof body === 'string' ? body : JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS, ...extra },
  });
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
    if (request.method !== 'GET') return reply({ error: 'Method not allowed' }, 405);

    const url = new URL(request.url);
    const [, service, ...rest] = url.pathname.split('/');
    const path = rest.join('/');

    if (service === 'congress') {
      if (!env.CONGRESS_API_KEY) return reply({ error: 'Server is missing CONGRESS_API_KEY' }, 500);
      if (!CONGRESS_PATHS.some((re) => re.test(path))) return reply({ error: 'Path not allowed' }, 400);

      const upstream = new URL(`https://api.congress.gov/v3/${path}`);
      for (const key of CONGRESS_QUERY) {
        const value = url.searchParams.get(key);
        if (value !== null) upstream.searchParams.set(key, value);
      }
      upstream.searchParams.set('format', 'json');
      upstream.searchParams.set('api_key', env.CONGRESS_API_KEY);

      // Members rarely change, so cache for a day.
      return forward(upstream, {}, 86400);
    }

    if (service === 'openstates' && path === 'people.geo') {
      if (!env.OPENSTATES_API_KEY) return reply({ error: 'Server is missing OPENSTATES_API_KEY' }, 500);
      const lat = Number(url.searchParams.get('lat'));
      const lng = Number(url.searchParams.get('lng'));
      if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180) {
        return reply({ error: 'lat and lng must be valid coordinates' }, 400);
      }
      const upstream = new URL('https://v3.openstates.org/people.geo');
      // Rounded to ~100 m: plenty for district lookups, and it improves cache hits.
      upstream.searchParams.set('lat', lat.toFixed(3));
      upstream.searchParams.set('lng', lng.toFixed(3));
      if (url.searchParams.get('include') === 'offices') upstream.searchParams.set('include', 'offices');
      return forward(upstream, { 'X-API-KEY': env.OPENSTATES_API_KEY }, 3600);
    }

    return reply({ error: 'Not found' }, 404);
  },
};

async function forward(upstream, headers, ttl) {
  try {
    const res = await fetch(upstream.toString(), {
      headers,
      cf: { cacheTtl: ttl, cacheEverything: true },
    });
    // Pass the body and status through; never echo upstream headers (they can include keys).
    return reply(await res.text(), res.status, res.ok ? { 'Cache-Control': `public, max-age=${ttl}` } : {});
  } catch (e) {
    return reply({ error: 'Upstream request failed' }, 502);
  }
}
