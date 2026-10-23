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
// September and October 2026. A few of these offices are elected and up for
// election on November 3, 2026 (County Executive: Jones, Dyer or Daniels;
// Sheriff: Boatwright or Burke; State's Attorney: David; County Council) —
// the current officeholder serves until a successor is sworn in, generally in
// December. Re-check names (not office phone numbers, which change far less
// often) after that election.
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
/// Month ("YYYY-MM") the bundled directory below was last updated. A hosted
/// copy of `data/county_directory.json` whose `updated` value is older than this
/// is ignored, so a stale download can never wipe out newer bundled offices.
/// Bump it (and the JSON's `updated`) whenever you change the directory.
const String bundledDirectoryUpdated = '2026-10';

/// County offices keyed by "County, ST" (e.g. "Baltimore County, MD"). Each value
/// is the list of [Contact]s for that county; directory_service can replace
/// entries at runtime. Entries are grouped below by the issue they serve.
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
      office: "Report a problem or request a service (dial 311, or 410-887-0311 from outside the county)",
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
      office: "Non-emergency line. Call 911 for emergencies or an animal being harmed right now",
      phone: "410-887-2222",
      website: "https://www.baltimorecountymd.gov/departments/police",
      level: "county",
      issueIds: ["local-police", "abandoned-vehicles", "animal-cruelty"],
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

    // ---- Added October 2026: animals, utilities, neighborhood, benefits ----
    // Animals & Pets (Baltimore County Animal Services, 410-887-PAWS)
    Contact(
      lastVerified: "2026-10",
      name: "Baltimore County Animal Services",
      office: "Strays, animal-law complaints, adoptions. Stray intake daily 9am-4pm; office Mon-Fri 8am-4pm",
      phone: "410-887-7297",
      email: "animalservices@baltimorecountymd.gov",
      website: "https://www.baltimorecountymd.gov/bcas",
      address: "13800 Manor Road, Baldwin, MD 21013",
      level: "county",
      issueIds: ["stray-animals", "leash-laws", "animal-cruelty"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Dog & Cat Licenses",
      office: "Pet licenses (required at 4 months, and within 30 days of moving in)",
      phone: "410-887-3630",
      website: "https://www.baltimorecountymd.gov/bcas",
      level: "county",
      issueIds: ["pet-licenses"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Baltimore County Rabies Investigations",
      office: "Animal bites and possible rabies exposure",
      phone: "410-887-5963",
      website: "https://www.baltimorecountymd.gov/departments/health",
      level: "county",
      issueIds: ["animal-bites", "pet-licenses"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Maryland DNR - Wildlife",
      office: "Wildlife nuisances and injured wildlife (the state, not the county, handles these)",
      phone: "1-877-463-6497",
      website: "https://dnr.maryland.gov",
      level: "state",
      issueIds: ["wildlife"],
    ),

    // Utilities (street lights, power, gas)
    Contact(
      lastVerified: "2026-10",
      name: "911 Emergency",
      office: "Gas smell, downed power line, fire, or any immediate danger",
      phone: "911",
      level: "county",
      issueIds: ["gas-leak"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "BGE Customer Care",
      office: "Street light outages and pole damage, gas leaks, billing and service",
      phone: "800-685-0123",
      website: "https://www.bge.com",
      level: "local",
      issueIds: ["streetlights", "gas-leak"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "BGE - report a power outage",
      office: "Electric outages, 24 hours a day",
      phone: "877-778-2222",
      website: "https://www.bge.com",
      level: "local",
      issueIds: ["power-outage"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Traffic Engineering - street lights",
      office: "Baltimore County Public Works street light questions",
      phone: "410-887-3716",
      website: "https://www.baltimorecountymd.gov/report-problem",
      level: "county",
      issueIds: ["streetlights"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Traffic Engineering - signals and signs",
      office: "Traffic signals and road signs (the State Highway Administration maintains signals on state roads)",
      phone: "410-887-3554",
      website: "https://www.baltimorecountymd.gov/report-problem",
      level: "county",
      issueIds: ["traffic-signals"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Sanitary Sewer Problems",
      office: "Baltimore County sewer backups and sewer line problems",
      phone: "410-887-7415",
      website: "https://www.baltimorecountymd.gov/departments/public-works",
      level: "county",
      issueIds: ["water-sewer"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Drinking Water Problems",
      office: "Drinking water quality and service problems",
      phone: "443-263-2220",
      website: "https://www.baltimorecountymd.gov/departments/public-works/utilities/water-issues",
      level: "county",
      issueIds: ["water-sewer"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Baltimore City DPW - water billing",
      office: "Baltimore City bills and services County water accounts",
      phone: "410-396-5398",
      website: "https://www.baltimorecountymd.gov/departments/public-works/utilities/water-issues",
      level: "local",
      issueIds: ["water-sewer"],
    ),

    // Trash dumping and storm-drain discharges
    Contact(
      lastVerified: "2026-10",
      name: "Environmental Protection and Sustainability",
      office: "Illegal trash dumping and wash water discharged to storm drains",
      phone: "410-887-5683",
      website: "https://www.baltimorecountymd.gov/report-problem",
      level: "county",
      issueIds: ["waste"],
    ),

    // Neighborhood & Code Enforcement
    Contact(
      lastVerified: "2026-10",
      name: "Baltimore County Code Enforcement",
      office: "Complaints about code and property violations, plus the rat extermination program",
      phone: "410-887-3351",
      website: "https://baltimorecountymd.gov/codecomplaint",
      level: "county",
      issueIds: ["code-violations", "rodents"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Zoning Complaints and Enforcement",
      office: "Zoning violation complaints",
      phone: "410-887-8099",
      website: "https://www.baltimorecountymd.gov/departments/pai",
      level: "county",
      issueIds: ["code-violations", "local-zoning"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Recreation and Parks",
      office: "County parks and recreation. The 88PARKS status line is 410-887-2757",
      phone: "410-887-3871",
      level: "county",
      issueIds: ["parks"],
    ),

    // Public safety and emergency planning
    Contact(
      lastVerified: "2026-10",
      name: "Fire Department - non-emergency",
      office: "Non-emergency fire department line",
      phone: "410-887-4500",
      level: "county",
      issueIds: ["emergency-prep"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Emergency Preparedness",
      office: "Storm, disaster and emergency planning",
      phone: "410-887-5996",
      level: "county",
      issueIds: ["emergency-prep"],
    ),

    // Benefits & Family Help, housing and health
    Contact(
      lastVerified: "2026-10",
      name: "Baltimore County Department of Social Services",
      office: "Family assistance, child care, and adult services",
      phone: "410-853-3000",
      website: "https://dhs.maryland.gov",
      level: "county",
      issueIds: ["food-cash"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "211 Maryland",
      office: "Free referrals to local help and assistance programs",
      phone: "211",
      website: "https://211md.org",
      level: "state",
      issueIds: ["help-referral", "food-cash"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Baltimore County Department of Aging",
      office: "Senior centers, classes, and events",
      phone: "410-887-2594",
      website: "https://www.baltimorecountymd.gov/departments/aging",
      level: "county",
      issueIds: ["senior-disability"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Disabilities Information and Referral",
      office: "County information and referral for people with disabilities",
      phone: "410-887-3317",
      level: "county",
      issueIds: ["senior-disability"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Community Development and Housing",
      office: "Housing Opportunities and local housing programs (also 410-887-6055)",
      phone: "410-887-3124",
      level: "county",
      issueIds: ["local-housing-help"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "988 Suicide & Crisis Lifeline",
      office: "Call or text 988, 24 hours a day. Call 911 if someone is in immediate danger",
      phone: "988",
      website: "https://988lifeline.org",
      level: "federal",
      issueIds: ["mental-health"],
    ),
    Contact(
      lastVerified: "2026-10",
      name: "Baltimore County Health - substance use services",
      office: "Substance use help from the county health department",
      phone: "410-887-3828",
      website: "https://www.baltimorecountymd.gov/departments/health",
      level: "county",
      issueIds: ["mental-health"],
    ),

    // Driver's licenses and vehicle registration (state agency)
    Contact(
      lastVerified: "2026-10",
      name: "Maryland MVA",
      office: "Driver's licenses, IDs, and vehicle registration",
      phone: "410-768-7000",
      website: "https://mva.maryland.gov",
      level: "state",
      issueIds: ["mva"],
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
// Notes on offices that are not county departments:
// - BGE is the electric/gas utility for Baltimore County and maintains most street lights.
// - Baltimore City, not the County, bills and services County water accounts.
// - MTA Maryland (state) runs the region's local buses, light rail and Metro.
// - 211 Maryland is the state's free referral line for local help programs.
// - Maryland DNR handles wildlife nuisances; the county handles pets.
// Most of these now live in countyDictionary (tied to issues by issueIds) and are
// picked into the hub below, so a number only has to be fixed in one place.
// October 2026 additions (animals, utilities, code enforcement, benefits) were
// checked against baltimorecountymd.gov's "helpful numbers", "report a problem",
// animal-laws, Animal Services and code-complaint pages.
/// Offices for each Resident hub service shortcut, shaped as
/// county key -> service title (matching `hubServices`) -> contacts. Many entries
/// reuse [countyDictionary] via [_pick]; the rest are defined here.
Map<String, Map<String, List<Contact>>> get countyServiceDirectory => {
  "Baltimore County, MD": {
    // City services: everyday county help lines.
    "City services": _pick("Baltimore County, MD", [
      "BaltCo 311",
      "Bureau of Highways",
      "Bureau of Solid Waste Management",
      "Baltimore County Code Enforcement",
      "Recreation and Parks",
    ]),
    // Permits: building, zoning and inspections.
    "Permits": _pick("Baltimore County, MD", [
      "Permits, Approvals and Inspections",
      "Baltimore County Department of Planning",
      "Zoning Complaints and Enforcement",
    ]),
    // Utilities: street lights, power, gas, water and sewer.
    "Household Utilities": _pick("Baltimore County, MD", [
      "BGE Customer Care",
      "BGE - report a power outage",
      "Traffic Engineering - street lights",
      "Sanitary Sewer Problems",
      "Drinking Water Problems",
      "Baltimore City DPW - water billing",
    ]),
    // Public records: records requests and meetings.
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
    // Transit info: local buses, light rail and Metro.
    "Transit info": [
      Contact(
        lastVerified: "2026-09",
        name: "Maryland Transit Administration (MTA)",
        office: "Bus, light rail, and Metro routes and schedules",
        phone: "410-539-5000",
        website: "https://www.mta.maryland.gov",
        level: "state",
      ),
      ..._pick("Baltimore County, MD", ["Maryland MVA"]),
    ],
    // County offices: the main elected and administrative offices.
    "County offices": _pick("Baltimore County, MD", [
      "Kathy Klausmeier",
      "Baltimore County Council",
      "Baltimore County Department of Health",
      "Baltimore County Board of Elections",
      "MD SDAT — Baltimore County Assessments",
    ]),
    // Animal services: strays, licenses, rabies and wildlife.
    "Animal services": _pick("Baltimore County, MD", [
      "Baltimore County Animal Services",
      "Dog & Cat Licenses",
      "Baltimore County Rabies Investigations",
      "Maryland DNR - Wildlife",
    ]),
    // Safety & emergency: 911, police, fire and preparedness.
    "Safety & emergency": _pick("Baltimore County, MD", [
      "911 Emergency",
      "Baltimore County Police Department",
      "Fire Department - non-emergency",
      "Emergency Preparedness",
      "988 Suicide & Crisis Lifeline",
    ]),
    // Social services: food, cash, child care, seniors and housing.
    "Social services": _pick("Baltimore County, MD", [
      "Baltimore County Department of Social Services",
      "Community Development and Housing",
      "Baltimore County Department of Aging",
      "Disabilities Information and Referral",
      "211 Maryland",
    ]),
    // Community programs: local help and referral services.
    "Community programs": _pick("Baltimore County, MD", [
      "Baltimore County Department of Aging",
      "211 Maryland",
      "BaltCo 311",
    ]),
  },
};
