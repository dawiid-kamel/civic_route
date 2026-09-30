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
    faqs: [
      FaqItem(question: "Who should I contact for a pothole or street repair?", answer: "Most road repairs are handled by your city or county public works office. Federal offices usually handle interstate or highway funding, not local potholes."),
      FaqItem(question: "Why do I sometimes need a state office instead of a federal one?", answer: "Public transit and bus service are often run by regional agencies and funded through state policy, while interstates and airports are usually federal."),
    ],
  ),
  IssueCategory(
    id: "housing", name: "Housing", icon: Icons.home_outlined,
    description: "Rent, tenants, HUD",
    subIssues: [
      Issue(id: "landlord", name: "Landlord/tenant disputes", levels: ["county"], description: "Local housing authority or tenant board"),
      Issue(id: "hud", name: "Federal housing policy (HUD)", levels: ["federal_house", "federal_senate"], description: "National housing programs and funding"),
      Issue(id: "rent-control", name: "Rent control & state housing law", levels: ["state"], description: "State legislature housing regulations"),
    ],
    faqs: [
      FaqItem(question: "My landlord will not fix something — who handles that?", answer: "Local housing authorities, city offices, or tenant boards usually handle landlord-tenant issues; those are rarely federal matters."),
      FaqItem(question: "Is rent control set by the federal government?", answer: "No. Rent control and many housing policies are decided at the state or local level, so your state lawmakers are often the right starting point."),
    ],
  ),
  IssueCategory(
    id: "healthcare", name: "Healthcare", icon: Icons.medical_services_outlined,
    description: "Medicaid, Medicare, clinics",
    subIssues: [
      Issue(id: "medicaid", name: "Medicaid", levels: ["state"], description: "State-administered, federally funded"),
      Issue(id: "medicare", name: "Medicare", levels: ["federal_house", "federal_senate"], description: "Federal health program for seniors"),
      Issue(id: "clinics", name: "Local clinics & hospital access", levels: ["county"], description: "County health department"),
    ],
    faqs: [
      FaqItem(question: "When should I contact my state legislators instead of Congress?", answer: "Programs like Medicaid and many local health services are managed by the state or county, even though the federal government helps fund them."),
      FaqItem(question: "What is Medicare handled by?", answer: "Medicare is a federal program, so your U.S. House representative or senators are usually the best federal contacts."),
    ],
  ),
  IssueCategory(
    id: "education", name: "Education", icon: Icons.school_outlined,
    description: "Schools, loans, curriculum",
    subIssues: [
      Issue(id: "k12", name: "School funding & curriculum", levels: ["state", "county"], description: "State education policy and local school board"),
      Issue(id: "student-loans", name: "Student loans", levels: ["federal_house", "federal_senate"], description: "Federal student aid policy"),
      Issue(id: "higher-ed", name: "Higher education policy", levels: ["federal_house", "federal_senate"], description: "Federal college funding and regulation"),
    ],
    faqs: [
      FaqItem(question: "Who decides what schools teach?", answer: "Most curriculum and K-12 policy is set by state or local education leaders, not by Congress."),
      FaqItem(question: "Who handles student loans?", answer: "Federal student aid is controlled by national policy, so your House rep and senators are usually the right federal contacts."),
    ],
  ),
  IssueCategory(
    id: "public-safety", name: "Public Safety", icon: Icons.shield_outlined,
    description: "Policing, gun policy",
    subIssues: [
      Issue(id: "local-police", name: "Local police conduct", levels: ["county"], description: "City council or police oversight board"),
      Issue(id: "federal-le", name: "Federal law enforcement", levels: ["federal_house", "federal_senate"], description: "FBI, DOJ, federal crime policy"),
      Issue(id: "gun-policy", name: "Gun policy", levels: ["state", "federal_house", "federal_senate"], description: "State and federal gun laws"),
    ],
    faqs: [
      FaqItem(question: "Who investigates local police concerns?", answer: "Most local complaints are handled by city or county officials, oversight boards, or the local police department itself, not by a federal office."),
      FaqItem(question: "Why can gun policy involve multiple levels of government?", answer: "Some gun laws are federal, while others are set by a state. A local issue may require both state and federal contacts depending on the concern."),
    ],
  ),
  IssueCategory(
    id: "environment", name: "Environment", icon: Icons.eco_outlined,
    description: "Climate, waste, land",
    subIssues: [
      Issue(id: "climate", name: "Federal climate policy", levels: ["federal_house", "federal_senate"], description: "National environmental regulation"),
      Issue(id: "state-env", name: "State environmental law", levels: ["state"], description: "State-level emissions and land use rules"),
      Issue(id: "waste", name: "Local waste & recycling", levels: ["county"], description: "County or municipal waste management"),
    ],
    faqs: [
      FaqItem(question: "Who handles trash or recycling complaints?", answer: "Those are usually local county or municipal services, not a congressional office."),
      FaqItem(question: "When is it a state or federal environmental issue?", answer: "Broad changes in air, water, and climate policy are often federal or state issues, while waste pickup and local land use are usually local."),
    ],
  ),
  IssueCategory(
    id: "taxes", name: "Taxes", icon: Icons.payments_outlined,
    description: "Federal, state, property",
    subIssues: [
      Issue(id: "federal-tax", name: "Federal income tax", levels: ["federal_house", "federal_senate"], description: "National tax policy"),
      Issue(id: "state-tax", name: "State income tax", levels: ["state"], description: "State tax legislation"),
      Issue(id: "property-tax", name: "Property tax", levels: ["county"], description: "County tax assessor"),
    ],
    faqs: [
      FaqItem(question: "Who sets my property taxes?", answer: "Property tax is usually determined at the county or local level through the assessor and local taxing agencies."),
      FaqItem(question: "When should I contact a state or federal official about taxes?", answer: "Federal tax policy is national, while state income tax and property tax are typically handled by state and county offices."),
    ],
  ),
  IssueCategory(
    id: "immigration", name: "Immigration", icon: Icons.public_outlined,
    description: "Federal policy",
    subIssues: [
      Issue(id: "immigration-policy", name: "Immigration policy & enforcement", levels: ["federal_house", "federal_senate"], description: "Federal jurisdiction only"),
    ],
    faqs: [
      FaqItem(question: "Can city or state offices decide immigration policy?", answer: "Not in the way Congress does. Immigration enforcement and policy are primarily federal responsibilities."),
    ],
  ),
  IssueCategory(
    id: "labor", name: "Employment & Labor", icon: Icons.work_outline,
    description: "Wages, unemployment",
    subIssues: [
      Issue(id: "federal-labor", name: "Federal labor law", levels: ["federal_house", "federal_senate"], description: "Minimum wage floor, overtime"),
      Issue(id: "state-wage", name: "State minimum wage & workplace law", levels: ["state"], description: "State labor legislation"),
      Issue(id: "unemployment", name: "Unemployment benefits", levels: ["state"], description: "State-administered unemployment insurance"),
    ],
    faqs: [
      FaqItem(question: "Who sets minimum wage rules?", answer: "There is a federal wage floor, but many states and local governments set higher minimums or additional workplace rules."),
      FaqItem(question: "Who manages unemployment claims?", answer: "Most unemployment benefits are handled by the state, even if federal labor rules create the larger legal framework."),
    ],
  ),
  IssueCategory(
    id: "elections", name: "Elections & Voting", icon: Icons.how_to_vote_outlined,
    description: "Voting rights, polling",
    subIssues: [
      Issue(id: "federal-election", name: "Federal election law", levels: ["federal_house", "federal_senate"], description: "National voting rights legislation"),
      Issue(id: "state-election", name: "State election administration", levels: ["state"], description: "State voting rules and district maps"),
      Issue(id: "local-election", name: "Local polling & county elections", levels: ["county"], description: "County board of elections"),
    ],
    faqs: [
      FaqItem(question: "Who runs polling places in my area?", answer: "Your county election office typically manages polling locations, voting logistics, and local election administration."),
      FaqItem(question: "When is the issue federal versus state?", answer: "Federal law covers national voting rights and elections, while state and county offices handle local rules, ballot issues, and polling locations."),
    ],
  ),
  IssueCategory(
    id: "social-security", name: "Social Security", icon: Icons.people_outline,
    description: "Retirement benefits",
    subIssues: [
      Issue(id: "ss-policy", name: "Social Security policy", levels: ["federal_house", "federal_senate"], description: "Federal retirement benefits program"),
    ],
    faqs: [
      FaqItem(question: "Is Social Security handled by local or state offices?", answer: "No. Social Security is a federal program, so congressional offices are the proper federal contacts for policy questions."),
    ],
  ),
  IssueCategory(
    id: "zoning", name: "Zoning & Development", icon: Icons.business_outlined,
    description: "Land use, building",
    subIssues: [
      Issue(id: "local-zoning", name: "Local zoning decisions", levels: ["county"], description: "County or city zoning board"),
      Issue(id: "state-land", name: "State land use law", levels: ["state"], description: "Broader state development regulation"),
    ],
    faqs: [
      FaqItem(question: "Who approves a new development or zoning change?", answer: "Local city or county zoning boards usually make those decisions, while state rules affect broader land use and development policy."),
    ],
  ),
];
