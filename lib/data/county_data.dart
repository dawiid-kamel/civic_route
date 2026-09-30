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
  "Baltimore County": [
    // General / countywide — show for every county-level issue.
    Contact(
      name: "Kathy Klausmeier",
      office: "Baltimore County Executive",
      phone: "410-887-2450",
      website: "https://www.baltimorecountymd.gov/departments/executive",
      level: "county",
    ),
    Contact(
      name: "Baltimore County Council",
      office: "County Council (all 7 districts)",
      phone: "410-887-3196",
      website: "https://countycouncil.baltimorecountymd.gov",
      level: "county",
    ),
    Contact(
      name: "BaltCo 311",
      office: "Report a problem or request a service",
      phone: "410-887-0311",
      website: "https://www.baltimorecountymd.gov/report-problem",
      level: "county",
    ),

    // Local roads & potholes
    Contact(
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
      name: "MD Attorney General — Consumer Protection Division",
      office: "Landlord/tenant dispute mediation",
      phone: "410-528-8662",
      website: "https://oag.maryland.gov/i-need-to/Pages/landlord-tenant-disputes.aspx",
      level: "state",
      issueIds: ["landlord"],
    ),

    // Local clinics & hospital access
    Contact(
      name: "Baltimore County Department of Health",
      office: "Public health services & clinics",
      phone: "410-887-2243",
      website: "https://www.baltimorecountymd.gov/departments/health",
      level: "county",
      issueIds: ["clinics"],
    ),

    // School funding & curriculum
    Contact(
      name: "Baltimore County Public Schools",
      office: "Board of Education",
      phone: "443-809-4554",
      website: "https://www.bcps.org/board_of_education",
      level: "county",
      issueIds: ["k12"],
    ),

    // Local police conduct
    Contact(
      name: "Baltimore County Police Department",
      office: "Non-emergency line",
      phone: "410-887-2222",
      website: "https://www.baltimorecountymd.gov/departments/police",
      level: "county",
      issueIds: ["local-police"],
    ),

    // Local waste & recycling
    Contact(
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
      name: "MD SDAT — Baltimore County Assessments",
      office: "Property tax assessment",
      phone: "410-512-4900",
      website: "https://dat.maryland.gov/realproperty",
      level: "state",
      issueIds: ["property-tax"],
    ),

    // Local polling & county elections
    Contact(
      name: "Baltimore County Board of Elections",
      office: "Voter registration & polling places",
      phone: "410-887-5700",
      website: "https://www.baltimorecountymd.gov/departments/elections",
      level: "county",
      issueIds: ["local-election"],
    ),

    // Local zoning decisions
    Contact(
      name: "Baltimore County Department of Planning",
      office: "Zoning & land use",
      phone: "410-887-3211",
      website: "https://www.baltimorecountymd.gov/departments/planning",
      level: "county",
      issueIds: ["local-zoning"],
    ),
    Contact(
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
      name: "R. Jay Fisher",
      office: "Baltimore County Sheriff",
      phone: "410-887-3151",
      website: "https://www.baltimorecountymd.gov/departments/sheriff",
      level: "county",
    ),
    Contact(
      name: "Scott D. Shellenberger",
      office: "Baltimore County State's Attorney",
      phone: "410-887-6600",
      website: "https://www.baltimorecountymd.gov/departments/states-attorney",
      level: "county",
    ),
  ],
};