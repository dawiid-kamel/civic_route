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
      FaqItem(question: "Why isn't my pothole a federal issue?", answer: "Local roads are maintained by your city or county public works department, not the federal government. Your House rep can't fix a pothole, but your county can."),
      FaqItem(question: "Who funds public transit?", answer: "Most buses and trains are run by a regional transit authority funded through your state, even though some federal grants help pay for it."),
      FaqItem(question: "What about a highway near me?", answer: "Interstates and federal highways are funded through Congress, so your House rep and senators are the right contacts for those."),
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
      FaqItem(question: "My landlord won't fix something — who do I call?", answer: "That's a local issue — your county or city has a housing authority or tenant board that handles disputes like this."),
      FaqItem(question: "Is rent control a federal law?", answer: "No, rent control is decided state by state. Your state legislator is the right contact."),
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
      FaqItem(question: "Is Medicaid federal or state?", answer: "Both — it's federally funded but run by each state, so your state legislator is the right first contact for problems with it."),
      FaqItem(question: "What about Medicare?", answer: "Medicare is fully federal, so your House rep or senators are the right contacts."),
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
      FaqItem(question: "Who decides what my school teaches?", answer: "Curriculum is largely a state and local school board decision, not federal."),
      FaqItem(question: "Who handles student loan policy?", answer: "Federal student aid programs are set by Congress, so your House rep and senators are the right contacts."),
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
      FaqItem(question: "Who oversees my local police department?", answer: "That's handled at the city or county level, usually through a city council or civilian oversight board."),
      FaqItem(question: "Is gun policy federal or state?", answer: "Both — some gun laws are federal, but many restrictions are set state by state, so this issue often needs contacting both levels."),
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
      FaqItem(question: "Who handles recycling programs?", answer: "Waste and recycling are managed locally by your county or municipality."),
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
      FaqItem(question: "Who sets my property tax rate?", answer: "Property taxes are assessed and collected at the county level."),
    ],
  ),
  IssueCategory(
    id: "immigration", name: "Immigration", icon: Icons.public_outlined,
    description: "Federal policy",
    subIssues: [
      Issue(id: "immigration-policy", name: "Immigration policy & enforcement", levels: ["federal_house", "federal_senate"], description: "Federal jurisdiction only"),
    ],
    faqs: [
      FaqItem(question: "Can my state or city change immigration law?", answer: "No — immigration is exclusively federal jurisdiction, so your House rep and senators are the only correct contacts."),
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
      FaqItem(question: "Who sets minimum wage?", answer: "There's a federal minimum wage floor, but most states set their own higher minimum, so check both."),
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
      FaqItem(question: "Who runs my local polling place?", answer: "Your county board of elections manages polling locations and local voting logistics."),
    ],
  ),
  IssueCategory(
    id: "social-security", name: "Social Security", icon: Icons.people_outline,
    description: "Retirement benefits",
    subIssues: [
      Issue(id: "ss-policy", name: "Social Security policy", levels: ["federal_house", "federal_senate"], description: "Federal retirement benefits program"),
    ],
    faqs: [
      FaqItem(question: "Is Social Security ever handled at the state level?", answer: "No, it's entirely federal — your House rep and senators are the only correct contacts."),
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
      FaqItem(question: "Who approves new construction near me?", answer: "Local zoning boards, run by your city or county, handle building and land use approvals."),
    ],
  ),
];
