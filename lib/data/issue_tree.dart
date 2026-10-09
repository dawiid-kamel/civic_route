/// Static catalog of issue categories and sub-issues.
///
/// This is the content behind the Home grid, the Category screen and the
/// search box. Each sub-issue lists the government `levels` responsible for
/// it (`federal_house`, `federal_senate`, `state`, `county`); the resolver
/// uses those to choose which lookups to run, and the Resident hub reads it to
/// show the names of saved categories and issues.
library;

import 'package:flutter/material.dart';
import '../models/issue.dart';

final List<IssueCategory> issueTree = [
  IssueCategory(
    id: "transportation", name: "Transportation", icon: Icons.directions_car_outlined,
    description: "Roads, transit, airports",
    subIssues: [
      Issue(id: "highways", name: "Highways & interstates", levels: ["federal_house", "federal_senate"], description: "Federal highway funding and interstate policy"),
      Issue(id: "transit", name: "Public transit", levels: ["state"], description: "Regional transit authority funding and routes"),
      Issue(id: "local-roads", name: "Local roads & potholes", levels: ["county"], description: "City or county public works"),
      Issue(id: "airports", name: "Airports", levels: ["federal_house", "federal_senate"], description: "FAA and federal aviation policy"),
    ],
    guide: CategoryGuide(
      covers: "Roads, highways, public transit, and airports.",
      federal: "Interstate highways and airports, including funding and FAA rules.",
      state: "Public transit funding and regional bus and rail service.",
      county: "Local roads, potholes, sidewalks, and snow removal.",
      prepare: "The street or intersection, what the problem is, when you noticed it, and photos if you have them.",
    ),
  ),
  IssueCategory(
    id: "housing", name: "Housing", icon: Icons.home_outlined,
    description: "Rent, tenants, HUD",
    subIssues: [
      Issue(id: "landlord", name: "Landlord/tenant disputes", levels: ["county"], description: "Local housing authority or tenant board"),
      Issue(id: "hud", name: "Federal housing policy (HUD)", levels: ["federal_house", "federal_senate"], description: "National housing programs and funding"),
      Issue(id: "rent-control", name: "Rent control & state housing law", levels: ["state"], description: "State legislature housing regulations"),
    ],
    guide: CategoryGuide(
      covers: "Renting, landlord and tenant problems, and housing programs.",
      federal: "National housing programs and funding (HUD). Rent control is not set federally.",
      state: "State housing law, including rules on rent increases and tenant rights.",
      county: "Local housing offices and tenant complaints.",
      prepare: "Your lease, the dates you asked the landlord for help, photos of the problem, and any notices you received.",
    ),
  ),
  IssueCategory(
    id: "healthcare", name: "Healthcare", icon: Icons.medical_services_outlined,
    description: "Medicaid, Medicare, clinics",
    subIssues: [
      Issue(id: "medicaid", name: "Medicaid", levels: ["state"], description: "State-administered, federally funded"),
      Issue(id: "medicare", name: "Medicare", levels: ["federal_house", "federal_senate"], description: "Federal health program for seniors"),
      Issue(id: "clinics", name: "Local clinics & hospital access", levels: ["county"], description: "County health department"),
    ],
    guide: CategoryGuide(
      covers: "Health coverage programs and access to local care.",
      federal: "Medicare, the federal health program for seniors.",
      state: "Medicaid, which states run with federal funding.",
      county: "The county health department and local clinics.",
      prepare: "Your insurance or program ID, the name of the provider or clinic, and the dates of any denied claims or services.",
    ),
  ),
  IssueCategory(
    id: "education", name: "Education", icon: Icons.school_outlined,
    description: "Schools, loans, curriculum",
    subIssues: [
      Issue(id: "k12", name: "School funding & curriculum", levels: ["state", "county"], description: "State education policy and local school board"),
      Issue(id: "student-loans", name: "Student loans", levels: ["federal_house", "federal_senate"], description: "Federal student aid policy"),
      Issue(id: "higher-ed", name: "Higher education policy", levels: ["federal_house", "federal_senate"], description: "Federal college funding and regulation"),
    ],
    guide: CategoryGuide(
      covers: "Schools, student loans, and college policy.",
      federal: "Student loans and federal college funding and rules.",
      state: "State education policy, school funding, and curriculum standards.",
      county: "Your local school board and school system.",
      prepare: "The school or district name, the grade or program involved, and any emails or letters you have already exchanged.",
    ),
  ),
  IssueCategory(
    id: "public-safety", name: "Public Safety", icon: Icons.shield_outlined,
    description: "Policing, gun policy",
    subIssues: [
      Issue(id: "local-police", name: "Local police conduct", levels: ["county"], description: "City council or police oversight board"),
      Issue(id: "federal-le", name: "Federal law enforcement", levels: ["federal_house", "federal_senate"], description: "FBI, DOJ, federal crime policy"),
      Issue(id: "gun-policy", name: "Gun policy", levels: ["state", "federal_house", "federal_senate"], description: "State and federal gun laws"),
    ],
    guide: CategoryGuide(
      covers: "Policing, law enforcement, and gun laws. In an emergency, call 911.",
      federal: "Federal law enforcement (FBI, DOJ) and federal gun laws.",
      state: "State gun laws.",
      county: "Local police conduct and oversight.",
      prepare: "The date, time, and place of the incident, any officer or case numbers, and the names of witnesses.",
    ),
  ),
  IssueCategory(
    id: "environment", name: "Environment", icon: Icons.eco_outlined,
    description: "Climate, waste, land",
    subIssues: [
      Issue(id: "climate", name: "Federal climate policy", levels: ["federal_house", "federal_senate"], description: "National environmental regulation"),
      Issue(id: "state-env", name: "State environmental law", levels: ["state"], description: "State-level emissions and land use rules"),
      Issue(id: "waste", name: "Local waste & recycling", levels: ["county"], description: "County or municipal waste management"),
    ],
    guide: CategoryGuide(
      covers: "Climate, pollution, and waste.",
      federal: "National climate and environmental regulation.",
      state: "State rules on emissions and land use.",
      county: "Trash, recycling, and other local waste services.",
      prepare: "The address or location, what you saw and when, and photos if possible.",
    ),
  ),
  IssueCategory(
    id: "taxes", name: "Taxes", icon: Icons.payments_outlined,
    description: "Federal, state, property",
    subIssues: [
      Issue(id: "federal-tax", name: "Federal income tax", levels: ["federal_house", "federal_senate"], description: "National tax policy"),
      Issue(id: "state-tax", name: "State income tax", levels: ["state"], description: "State tax legislation"),
      Issue(id: "property-tax", name: "Property tax", levels: ["county"], description: "County tax assessor"),
    ],
    guide: CategoryGuide(
      covers: "Income taxes and property taxes.",
      federal: "Federal income tax policy.",
      state: "State income tax laws.",
      county: "Property tax bills and assessment questions.",
      prepare: "Your tax bill or notice, your property or account number, and the tax year in question.",
    ),
  ),
  IssueCategory(
    id: "immigration", name: "Immigration", icon: Icons.public_outlined,
    description: "Federal policy",
    subIssues: [
      Issue(id: "immigration-policy", name: "Immigration policy & enforcement", levels: ["federal_house", "federal_senate"], description: "Federal jurisdiction only"),
    ],
    guide: CategoryGuide(
      covers: "Immigration law and enforcement.",
      federal: "All immigration policy and enforcement.",
      state: null,
      county: null,
      prepare: "Your case or receipt number, the relevant dates, and copies of any notices or letters.",
    ),
  ),
  IssueCategory(
    id: "labor", name: "Employment & Labor", icon: Icons.work_outline,
    description: "Wages, unemployment",
    subIssues: [
      Issue(id: "federal-labor", name: "Federal labor law", levels: ["federal_house", "federal_senate"], description: "Minimum wage floor, overtime"),
      Issue(id: "state-wage", name: "State minimum wage & workplace law", levels: ["state"], description: "State labor legislation"),
      Issue(id: "unemployment", name: "Unemployment benefits", levels: ["state"], description: "State-administered unemployment insurance"),
    ],
    guide: CategoryGuide(
      covers: "Wages, workplace rules, and unemployment benefits.",
      federal: "The federal wage floor, overtime, and labor law.",
      state: "State minimum wage, workplace law, and unemployment insurance.",
      county: null,
      prepare: "Your employer's name, your pay stubs, the dates you worked, and any written notices.",
    ),
  ),
  IssueCategory(
    id: "elections", name: "Elections & Voting", icon: Icons.how_to_vote_outlined,
    description: "Voting rights, polling",
    subIssues: [
      Issue(id: "federal-election", name: "Federal election law", levels: ["federal_house", "federal_senate"], description: "National voting rights legislation"),
      Issue(id: "state-election", name: "State election administration", levels: ["state"], description: "State voting rules and district maps"),
      Issue(id: "local-election", name: "Local polling & county elections", levels: ["county"], description: "County board of elections"),
    ],
    guide: CategoryGuide(
      covers: "Voting rights, voter registration, and polling places.",
      federal: "National voting-rights and election law.",
      state: "State election rules and district maps.",
      county: "Voter registration, polling places, and local election administration.",
      prepare: "Your name and address as registered, the election date, and the polling place involved.",
    ),
  ),
  IssueCategory(
    id: "social-security", name: "Social Security", icon: Icons.people_outline,
    description: "Retirement benefits",
    subIssues: [
      Issue(id: "ss-policy", name: "Social Security policy", levels: ["federal_house", "federal_senate"], description: "Federal retirement benefits program"),
    ],
    guide: CategoryGuide(
      covers: "Retirement and other Social Security benefits.",
      federal: "All Social Security policy and benefits.",
      state: null,
      county: null,
      prepare: "Your claim or case number (not your full Social Security number), the relevant dates, and any letters you received.",
    ),
  ),
  IssueCategory(
    id: "zoning", name: "Zoning & Development", icon: Icons.business_outlined,
    description: "Land use, building",
    subIssues: [
      Issue(id: "local-zoning", name: "Local zoning decisions", levels: ["county"], description: "County or city zoning board"),
      Issue(id: "state-land", name: "State land use law", levels: ["state"], description: "Broader state development regulation"),
    ],
    guide: CategoryGuide(
      covers: "Land use, building, and development approvals.",
      federal: null,
      state: "State land-use and development rules.",
      county: "Zoning boards and permits for local building and development.",
      prepare: "The property address, the project or change in question, and any permit or case numbers.",
    ),
  ),
];

/// Finds a category by id, or null if it no longer exists in the catalog.
IssueCategory? findCategoryById(String id) {
  for (final c in issueTree) {
    if (c.id == id) return c;
  }
  return null;
}

/// Finds a sub-issue by id, or null if it no longer exists in the catalog.
Issue? findIssueById(String id) {
  for (final c in issueTree) {
    for (final i in c.subIssues) {
      if (i.id == id) return i;
    }
  }
  return null;
}
