import '../models/issue.dart';

final List<IssueCategory> issueTree = [
  IssueCategory(name: "Transportation", subIssues: [
    Issue(name: "Highways & interstates", levels: ["federal_house", "federal_senate"], description: "Federal highway funding and interstate policy"),
    Issue(name: "Public transit (buses, trains)", levels: ["state"], description: "Regional transit authority funding and routes"),
    Issue(name: "Local roads & potholes", levels: ["county"], description: "City or county public works"),
    Issue(name: "Airports", levels: ["federal_house", "federal_senate"], description: "FAA and federal aviation policy"),
  ]),

  IssueCategory(name: "Housing", subIssues: [
    Issue(name: "Landlord/tenant disputes", levels: ["county"], description: "Local housing authority or tenant board"),
    Issue(name: "Federal housing policy (HUD)", levels: ["federal_house", "federal_senate"], description: "National housing programs and funding"),
    Issue(name: "Rent control & state housing law", levels: ["state"], description: "State legislature housing regulations"),
  ]),

  IssueCategory(name: "Healthcare", subIssues: [
    Issue(name: "Medicaid", levels: ["state"], description: "State-administered, federally funded"),
    Issue(name: "Medicare", levels: ["federal_house", "federal_senate"], description: "Federal health program for seniors"),
    Issue(name: "Local clinics & hospital access", levels: ["county"], description: "County health department"),
  ]),

  IssueCategory(name: "Education", subIssues: [
    Issue(name: "School funding & curriculum", levels: ["state", "county"], description: "State education policy and local school board"),
    Issue(name: "Student loans", levels: ["federal_house", "federal_senate"], description: "Federal student aid policy"),
    Issue(name: "Higher education policy", levels: ["federal_house", "federal_senate"], description: "Federal college funding and regulation"),
  ]),

  IssueCategory(name: "Policing & Public Safety", subIssues: [
    Issue(name: "Local police conduct", levels: ["county"], description: "City council or police oversight board"),
    Issue(name: "Federal law enforcement", levels: ["federal_house", "federal_senate"], description: "FBI, DOJ, federal crime policy"),
    Issue(name: "Gun policy", levels: ["state", "federal_house", "federal_senate"], description: "State and federal gun laws"),
  ]),

  IssueCategory(name: "Environment", subIssues: [
    Issue(name: "Federal climate policy", levels: ["federal_house", "federal_senate"], description: "National environmental regulation"),
    Issue(name: "State environmental law", levels: ["state"], description: "State-level emissions and land use rules"),
    Issue(name: "Local waste & recycling", levels: ["county"], description: "County or municipal waste management"),
  ]),

  IssueCategory(name: "Taxes", subIssues: [
    Issue(name: "Federal income tax", levels: ["federal_house", "federal_senate"], description: "National tax policy"),
    Issue(name: "State income tax", levels: ["state"], description: "State tax legislation"),
    Issue(name: "Property tax", levels: ["county"], description: "County tax assessor"),
  ]),

  IssueCategory(name: "Immigration", subIssues: [
    Issue(name: "Immigration policy & enforcement", levels: ["federal_house", "federal_senate"], description: "Federal jurisdiction only — this is not handled at state or local level"),
  ]),

  IssueCategory(name: "Employment & Labor", subIssues: [
    Issue(name: "Federal labor law (minimum wage floor, overtime)", levels: ["federal_house", "federal_senate"], description: "National labor standards"),
    Issue(name: "State minimum wage & workplace law", levels: ["state"], description: "State labor legislation"),
    Issue(name: "Unemployment benefits", levels: ["state"], description: "State-administered unemployment insurance"),
  ]),

  IssueCategory(name: "Elections & Voting", subIssues: [
    Issue(name: "Federal election law", levels: ["federal_house", "federal_senate"], description: "National voting rights legislation"),
    Issue(name: "State election administration", levels: ["state"], description: "State voting rules and district maps"),
    Issue(name: "Local polling places & county elections", levels: ["county"], description: "County board of elections"),
  ]),

  IssueCategory(name: "Social Security & Retirement", subIssues: [
    Issue(name: "Social Security policy", levels: ["federal_house", "federal_senate"], description: "Federal retirement benefits program"),
  ]),

  IssueCategory(name: "Zoning & Development", subIssues: [
    Issue(name: "Local zoning decisions", levels: ["county"], description: "County or city zoning board"),
    Issue(name: "State land use law", levels: ["state"], description: "Broader state development regulation"),
  ]),
];
