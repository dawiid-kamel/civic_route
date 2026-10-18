/// Hand-maintained county contact directory (currently Baltimore County, MD).
///
/// There is no free API for county offices, so the `county` level in
/// `services/resolver_service.dart` reads from this map, keyed by the county
/// "County, ST" key (e.g. "Baltimore County, MD"; the state is part of the key
/// because many states have a "Washington County"). `services/directory_service.dart`
/// can replace entries at runtime from a hosted copy of `data/county_directory.json`,
/// so contact changes don't need an app release. Counties not listed here return no contacts
/// and the Results screen shows its "No contacts found yet" message. Names
/// should be re-checked after each election.
///
/// `countyServiceDirectory` (bottom of this file) groups the same offices, plus
/// a few non-county ones (BGE, MTA, 211), by the service shortcuts shown in the
/// Resident hub, so each hub service sheet lists real people to contact. It is a
/// getter (not a constant) so it always reflects the latest remote directory.
library;

import '../models/contact.dart';

// Verified against official Baltimore County / Maryland state sources as of
// September 2026. A few of these offices are elected and up for election in
// November 2026 (County Executive, Sheriff, State's Attorney, County
// Council) — the current officeholder serves until a successor is sworn in,
// generally in December. Re-check names (not office phone numbers, which
// change far less often) after that election.
//
// Two entries below (SDAT property assessments and the Attorney General's
// Consumer Protection Division) are actually STATE offices, not county ones
// — they're listed here because they're what a Baltimore County resident
// with a "county-level" issue (property tax assessment, a landlord dispute)
// actually needs to call. Their `level` is set to 'state' so the Results
// screen badges them correctly even though they're returned via the county
// lookup.
//
// `issueIds` ties a contact to specific issues from data/issue_tree.dart so
// Results only shows what's relevant to the issue you're actually viewing.
// Leave it empty for general/countywide offices that should show up
// regardless of which county issue you're viewing.
final Map<String, List<Contact>> countyDictionary = {
  "Baltimore County, MD": [
    // General / countywide — show for every county-level issue.
    Contact(
      lastVerified: "2026-09",
      name: "Kathy Klausmeier",
      office: "Baltimore County Executive",
      phone: "410-887-2450",
      website: "https://www.baltimorecountymd.gov/departments/executive",
      level: "county",
    ),
    Contact(
      lastVerified: "2026-09",
      name: "Baltimore County Council",
      office: "County Council (all 7 districts)",
      phone: "410-887-3196",
      website: "https://countycouncil.baltimorecountymd.gov",
      level: "county",
    ),
    Contact(
      lastVerified: "2026-09",
      name: "BaltCo 311",
      office: "Report a problem or request a service",
      phone: "410-887-0311",
      website: "https://www.baltimorecountymd.gov/report-problem",
      level: "county",
    ),

    // Local roads & potholes
    Contact(
      lastVerified: "2026-09",
      name: "Bureau of Highways",
      office: "Roads, potholes, sidewalks, snow removal",
      phone: "410-887-3560",
      website: "https://www.baltimorecountymd.gov/departments/public-works/highways",
      level: "county",
      issueIds: ["local-roads"],
    ),

    // Landlord/tenant disputes — this is a Maryland state office, not a
    // county one; Baltimore County has no dedicated consumer-protection
    // office of its own the way Howard or Montgomery County does.
    Contact(
      lastVerified: "2026-09",
      name: "MD Attorney General — Consumer Protection Division",
      office: "Landlord/tenant dispute mediation",
      phone: "410-528-8662",
      website: "https://oag.maryland.gov/i-need-to/Pages/landlord-tenant-disputes.aspx",
      level: "state",
      issueIds: ["landlord"],
    ),

    // Local clinics & hospital access
    Contact(
      lastVerified: "2026-09",
      name: "Baltimore County Department of Health",
      office: "Public health services & clinics",
      phone: "410-887-2243",
      website: "https://www.baltimorecountymd.gov/departments/health",
      level: "county",
      issueIds: ["clinics"],
    ),

    // School funding & curriculum
    Contact(
      lastVerified: "2026-09",
      name: "Baltimore County Public Schools",
      office: "Board of Education",
      phone: "443-809-4554",
      website: "https://www.bcps.org/board_of_education",
      level: "county",
      issueIds: ["k12"],
    ),

    // Local police conduct
    Contact(
      lastVerified: "2026-09",
      name: "Baltimore County Police Department",
      office: "Non-emergency line",
      phone: "410-887-2222",
      website: "https://www.baltimorecountymd.gov/departments/police",
      level: "county",
      issueIds: ["local-police"],
    ),

    // Local waste & recycling
    Contact(
      lastVerified: "2026-09",
      name: "Bureau of Solid Waste Management",
      office: "Trash & recycling collection",
      phone: "410-887-2000",
      website: "https://www.baltimorecountymd.gov/departments/public-works",
      level: "county",
      issueIds: ["waste"],
    ),

    // Property tax — assessment is done by the state (SDAT); the county
    // only bills and collects based on that assessed value.
    Contact(
      lastVerified: "2026-09",
      name: "MD SDAT — Baltimore County Assessments",
      office: "Property tax assessment",
      phone: "410-512-4900",
      website: "https://dat.maryland.gov/realproperty",
      level: "state",
      issueIds: ["property-tax"],
    ),

    // Local polling & county elections
    Contact(
      lastVerified: "2026-09",
      name: "Baltimore County Board of Elections",
      office: "Voter registration & polling places",
      phone: "410-887-5700",
      website: "https://www.baltimorecountymd.gov/departments/elections",
      level: "county",
      issueIds: ["local-election"],
    ),

    // Local zoning decisions
    Contact(
      lastVerified: "2026-09",
      name: "Baltimore County Department of Planning",
      office: "Zoning & land use",
      phone: "410-887-3211",
      website: "https://www.baltimorecountymd.gov/departments/planning",
      level: "county",
      issueIds: ["local-zoning"],
    ),
    Contact(
      lastVerified: "2026-09",
      name: "Permits, Approvals and Inspections",
      office: "Building permits & inspections",
      phone: "410-887-3900",
      website: "https://www.baltimorecountymd.gov/departments/pai",
      level: "county",
      issueIds: ["local-zoning"],
    ),

    // Not tied to a specific issue_tree.dart entry today, but commonly
    // needed enough to keep as general/countywide contacts.
    Contact(
      lastVerified: "2026-09",
      name: "R. Jay Fisher",
      office: "Baltimore County Sheriff",
      phone: "410-887-3151",
      website: "https://www.baltimorecountymd.gov/departments/sheriff",
      level: "county",
    ),
    Contact(
      lastVerified: "2026-09",
      name: "Scott D. Shellenberger",
      office: "Baltimore County State's Attorney",
      phone: "410-887-6600",
      website: "https://www.baltimorecountymd.gov/departments/states-attorney",
      level: "county",
    ),
  ],
};

/// Picks contacts out of [countyDictionary] by exact name so the hub and the
/// Results screen share one copy of each phone number. A name that no longer
/// exists is skipped instead of crashing the hub.
List<Contact> _pick(String county, List<String> names) {
  final all = countyDictionary[county] ?? const <Contact>[];
  return [
    for (final name in names) ...all.where((c) => c.name == name),
  ];
}

// Phone numbers and websites below were checked against the county's, BGE's,
// MTA's and Baltimore City DPW's own published pages in September 2026.
//
// Departments that only appear in this directory (not in countyDictionary):
// - BGE is the electric/gas utility for Baltimore County.
// - Baltimore City, not the County, bills and services County water accounts.
// - MTA Maryland (state) runs the region's local buses, light rail and Metro.
// - 211 Maryland is the state's free referral line for local help programs.
// The Department of Aging's main number (410-887-2594) was supplied by the app
// owner in October 2026; each senior center also has its own number on the
// department's page.
Map<String, Map<String, List<Contact>>> get countyServiceDirectory => {
  "Baltimore County, MD": {
    "City services": _pick("Baltimore County, MD", [
      "BaltCo 311",
      "Bureau of Highways",
      "Bureau of Solid Waste Management",
    ]),
    "Permits": _pick("Baltimore County, MD", [
      "Permits, Approvals and Inspections",
      "Baltimore County Department of Planning",
    ]),
    "Utilities": [
      Contact(
        lastVerified: "2026-09",
        name: "BGE — report a power outage",
        office: "Electric outages, 24 hours a day",
        phone: "877-778-2222",
        website: "https://www.bge.com",
        level: "local",
      ),
      Contact(
        lastVerified: "2026-09",
        name: "BGE Customer Care",
        office: "Billing, service, and gas leaks",
        phone: "800-685-0123",
        website: "https://www.bge.com",
        level: "local",
      ),
      Contact(
        lastVerified: "2026-09",
        name: "Baltimore City DPW — water billing",
        office: "Baltimore City bills and services County water accounts",
        phone: "410-396-5398",
        website: "https://www.baltimorecountymd.gov/departments/public-works/utilities/water-issues",
        level: "local",
      ),
    ],
    "Public records": [
      Contact(
        lastVerified: "2026-09",
        name: "Public Information Act requests",
        office: "Find the right records custodian and submit a request",
        website: "https://countycouncil.baltimorecountymd.gov/departments/law/piarequests",
        level: "county",
      ),
      ..._pick("Baltimore County, MD", ["Baltimore County Council"]),
    ],
    "Transit info": [
      Contact(
        lastVerified: "2026-09",
        name: "Maryland Transit Administration (MTA)",
        office: "Bus, light rail, and Metro routes and schedules",
        phone: "410-539-5000",
        website: "https://www.mta.maryland.gov",
        level: "state",
      ),
    ],
    "County offices": _pick("Baltimore County, MD", [
      "Kathy Klausmeier",
      "Baltimore County Council",
      "Baltimore County Department of Health",
      "Baltimore County Board of Elections",
      "MD SDAT — Baltimore County Assessments",
    ]),
    "Community programs": [
      Contact(
        lastVerified: "2026-10",
        name: "Baltimore County Department of Aging",
        office: "Senior centers, classes, and events",
        phone: "410-887-2594",
        website: "https://www.baltimorecountymd.gov/departments/aging",
        level: "county",
      ),
      Contact(
        lastVerified: "2026-09",
        name: "211 Maryland",
        office: "Free referrals to local help and assistance programs",
        phone: "211",
        website: "https://211md.org",
        level: "state",
      ),
      ..._pick("Baltimore County, MD", ["BaltCo 311"]),
    ],
  },
};
