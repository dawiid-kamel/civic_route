/// Forgiving search over the issue catalog.
///
/// The Home search box accepts plain words ("pothole"), everyday phrases
/// ("my landlord won't fix the heat") and whole questions ("who do I call about
/// a missed trash pickup?"). Each category and sub-issue carries a list of
/// related words in [_keywords]; the query is cleaned up (lowercased,
/// punctuation and filler words removed, plurals folded) and scored against
/// those words plus the names and descriptions in `issue_tree.dart`.
/// `HomeScreen` shows the ranked [SearchHit]s in place of its other panels.
///
/// The same query is also matched against the Resident hub's services
/// ([searchServices]), so "street lamps" finds both the Utilities
/// category (which leads to BGE) and the hub's Utilities shortcut.
library;

import '../models/issue.dart';
import 'issue_tree.dart';
import 'services_data.dart';

/// One category that matched the query, with the sub-issues that matched best.
class SearchHit {
  final IssueCategory category;

  /// Matching sub-issues, best first (at most [maxIssuesPerHit]).
  final List<Issue> issues;
  final int score;

  const SearchHit({required this.category, required this.issues, required this.score});
}

const int maxIssuesPerHit = 3;

/// Words and phrases people use for each category id or issue id. Phrases
/// (two or more words) must appear in the query as written; single words also
/// match close variants ("rent" matches "renting" and "rental").
const Map<String, List<String>> _keywords = {
  // Categories
  'transportation': [
    'bus', 'train', 'subway', 'metro', 'light rail', 'commute', 'traffic', 'road',
    'street', 'driving', 'drive', 'car', 'parking', 'bike', 'bicycle', 'sidewalk',
    'crosswalk', 'transit', 'drivers license', 'driver license', 'mva', 'dmv',
  ],
  'housing': [
    'rent', 'landlord', 'tenant', 'lease', 'evict', 'eviction', 'apartment', 'mold',
    'deposit', 'mortgage', 'homeless', 'homelessness', 'shelter', 'affordable housing',
    'home', 'house', 'roommate',
  ],
  'healthcare': [
    'doctor', 'hospital', 'clinic', 'insurance', 'prescription', 'medicine', 'drug',
    'health', 'sick', 'medical', 'dental', 'mental health', 'therapy', 'vaccine',
    'coverage', 'premium', 'nursing home',
  ],
  'education': [
    'school', 'teacher', 'student', 'college', 'university', 'tuition', 'loan', 'class',
    'curriculum', 'textbook', 'bullying', 'principal', 'board of education', 'kids',
    'learning',
  ],
  'public-safety': [
    'police', 'cop', 'officer', 'crime', 'gun', 'firearm', 'shooting', 'safety',
    'robbery', 'theft', 'stolen', '911', 'fbi', 'arrest', 'violence', 'burglary',
    'sheriff', 'unsafe', 'emergency', 'fire department',
  ],
  'environment': [
    'pollution', 'air', 'water quality', 'climate', 'recycling', 'trash', 'garbage',
    'litter', 'dumping', 'waste', 'trees', 'toxic', 'spill', 'emissions',
    'smell', 'odor',
  ],
  'taxes': [
    'tax', 'irs', 'refund', 'return', 'assessment', 'assessed', 'withholding',
    'deduction', 'levy', 'tax bill',
  ],
  'immigration': [
    'visa', 'green card', 'citizenship', 'citizen', 'deportation', 'asylum', 'border',
    'ice', 'uscis', 'immigrant', 'naturalization', 'daca',
  ],
  'labor': [
    'job', 'work', 'employer', 'boss', 'fired', 'layoff', 'wage', 'pay', 'paycheck',
    'overtime', 'unemployment', 'workplace', 'union', 'hours', 'laid off', 'coworker',
  ],
  'elections': [
    'vote', 'voting', 'voter', 'ballot', 'register', 'registration', 'polling', 'polls',
    'election', 'absentee', 'precinct', 'gerrymandering',
  ],
  'social-security': [
    'social security', 'retirement', 'retire', 'pension', 'disability', 'ssi', 'ssdi',
    'survivor', 'senior', 'elderly',
  ],
  'zoning': [
    'zoning', 'zone', 'permit', 'building', 'construction', 'development', 'rezoning',
    'variance', 'land use', 'developer', 'fence', 'shed', 'deck', 'demolish', 'demolition',
  ],

  // Transportation
  'highways': ['highway', 'interstate', 'freeway', 'federal highway', 'toll'],
  'transit': ['bus', 'train', 'subway', 'metro', 'light rail', 'mta', 'schedule', 'fare', 'route', 'rider'],
  'local-roads': [
    'pothole', 'road', 'street', 'sidewalk', 'pavement', 'snow', 'plow', 'snow removal',
    'crosswalk', 'curb', 'drain', 'repair', 'speed bump',
  ],
  'traffic-signals': [
    'traffic light', 'traffic lights', 'traffic signal', 'traffic signals', 'signal', 'stoplight',
    'stop light', 'stop sign', 'road sign', 'street sign', 'traffic sign', 'red light',
    'light timing', 'blinking',
  ],
  'mva': [
    'mva', 'dmv', 'drivers license', 'driver license', 'license renewal', 'vehicle registration',
    'car registration', 'registration renewal', 'tags', 'real id', 'learner permit', 'title',
    'license plate',
  ],
  'airports': ['airport', 'flight', 'airline', 'faa', 'plane', 'tsa', 'aviation', 'airplane'],

  // Housing
  'landlord': [
    'landlord', 'tenant', 'rent', 'lease', 'evict', 'eviction', 'deposit', 'repair', 'mold',
    'heat', 'bedbug', 'pest', 'roach', 'apartment', 'leak', 'maintenance', 'rent increase',
    'security deposit', 'kicked out',
  ],
  'hud': ['hud', 'section 8', 'voucher', 'public housing', 'federal housing', 'housing assistance', 'subsidized'],
  'rent-control': ['rent control', 'rent increase', 'rent cap', 'rent hike', 'rent stabilization', 'price gouging', 'state housing'],

  // Healthcare
  'medicaid': ['medicaid', 'low income health', 'health coverage', 'enroll', 'chip', 'medical assistance', 'cant afford'],
  'medicare': ['medicare', 'senior health', 'part d', 'supplement', 'over 65'],
  'clinics': [
    'clinic', 'hospital', 'health department', 'urgent care', 'vaccine', 'vaccination',
    'flu shot', 'dental', 'county health', 'doctor', 'er', 'emergency room',
  ],

  // Education
  'k12': [
    'school', 'teacher', 'principal', 'curriculum', 'school board', 'bullying', 'class size',
    'textbook', 'school bus', 'special education', 'iep', 'grades', 'lunch', 'my kid', 'my child',
  ],
  'student-loans': ['student loan', 'loan', 'debt', 'fafsa', 'financial aid', 'forgiveness', 'repayment', 'pell grant'],
  'higher-ed': ['college', 'university', 'tuition', 'campus', 'degree', 'admissions', 'scholarship', 'community college'],

  // Public safety
  'local-police': ['police', 'officer', 'cop', 'misconduct', 'brutality', 'police complaint', 'traffic stop', 'patrol', 'pulled over'],
  'federal-le': ['fbi', 'doj', 'atf', 'dea', 'federal crime', 'federal agent', 'cybercrime', 'hate crime', 'scam'],
  'gun-policy': ['gun', 'firearm', 'background check', 'concealed carry', 'gun permit', 'shooting', 'assault weapon'],

  // Environment
  'climate': ['climate', 'global warming', 'emissions', 'epa', 'carbon', 'clean energy', 'greenhouse'],
  'state-env': ['air quality', 'pollution', 'land use', 'emissions', 'factory', 'water pollution', 'contamination'],
  'waste': [
    'trash', 'garbage', 'recycling', 'recycle', 'bulk pickup', 'dump', 'dumping', 'litter',
    'landfill', 'bin', 'collection', 'missed pickup', 'pickup', 'rubbish',
  ],

  // Taxes
  'federal-tax': ['irs', 'federal tax', 'income tax', 'refund', 'tax return', 'audit', 'deduction', 'tax credit'],
  'state-tax': ['state tax', 'state income tax', 'comptroller', 'state refund'],
  'property-tax': ['property tax', 'assessment', 'assessed', 'home value', 'tax bill', 'assessor', 'appeal', 'homestead'],

  // Immigration
  'immigration-policy': [
    'immigration', 'visa', 'green card', 'citizenship', 'deportation', 'asylum', 'border',
    'ice', 'uscis', 'daca', 'immigrant',
  ],

  // Labor
  'federal-labor': ['federal minimum wage', 'overtime', 'osha', 'flsa', 'workplace safety', 'labor board', 'nlrb', 'union'],
  'state-wage': [
    'minimum wage', 'paid sick leave', 'wage theft', 'paycheck', 'workplace', 'discrimination',
    'harassment', 'unpaid wages', 'leave', 'boss', 'employer', 'not paying me',
  ],
  'unemployment': [
    'unemployment', 'laid off', 'layoff', 'fired', 'jobless', 'benefits claim', 'lost my job',
    'lost job', 'out of work',
  ],

  // Elections
  'federal-election': ['voting rights', 'federal election', 'congress election', 'electoral', 'campaign finance'],
  'state-election': [
    'voter registration', 'register to vote', 'gerrymandering', 'redistricting', 'district map',
    'voter id', 'mail in ballot', 'absentee ballot', 'register',
  ],
  'local-election': [
    'polling place', 'poll', 'precinct', 'early voting', 'county election', 'board of elections',
    'ballot', 'where to vote', 'poll worker',
  ],

  // Social Security
  'ss-policy': ['social security', 'retirement', 'ssi', 'ssdi', 'disability benefits', 'survivor', 'benefits check', 'pension', 'retire'],

  // Zoning
  'local-zoning': [
    'zoning', 'rezone', 'variance', 'permit', 'building permit', 'construction', 'neighbor',
    'development', 'fence', 'shed', 'deck', 'demolition', 'building',
  ],
  'state-land': ['land use', 'development', 'state development', 'sprawl', 'annexation'],

  // Housing (local)
  'local-housing-help': [
    'housing voucher', 'section 8', 'rental assistance', 'housing help', 'housing opportunities',
    'affordable housing', 'homebuyer', 'first time homebuyer', 'housing assistance',
  ],

  // Healthcare (local)
  'mental-health': [
    '988', 'mental health', 'suicide', 'crisis', 'depression', 'anxiety', 'counseling',
    'therapy', 'addiction', 'substance', 'opioid', 'overdose', 'rehab', 'alcohol', 'drug',
  ],

  // Public safety (local)
  'emergency-prep': [
    'emergency', 'disaster', 'storm', 'hurricane', 'flood', 'evacuation', 'fire', 'fire department',
    'smoke alarm', 'preparedness', 'blizzard', 'power emergency',
  ],

  // Animals & Pets
  'animals': [
    'animal', 'pet', 'dog', 'cat', 'puppy', 'kitten', 'leash', 'stray', 'barking', 'bark',
    'rabies', 'animal control', 'animal services', 'raccoon', 'squirrel', 'possum', 'wildlife',
  ],
  'stray-animals': [
    'stray', 'lost dog', 'lost cat', 'found dog', 'found cat', 'lost pet', 'found pet',
    'loose dog', 'loose animal', 'animal control', 'animal services', 'adopt', 'adoption', 'pound',
  ],
  'leash-laws': [
    'leash', 'leash law', 'leash laws', 'off leash', 'barking', 'bark', 'noisy dog', 'loud dog',
    'running loose', 'running at large', 'at large', 'tether', 'chained dog', 'nuisance dog',
    'animal control', 'dog law',
  ],
  'animal-cruelty': [
    'cruelty', 'animal abuse', 'abuse', 'neglect', 'neglected', 'abused', 'starving',
    'no food or water', 'abandoned dog', 'abandoned pet', 'animal cruelty',
  ],
  'pet-licenses': [
    'dog license', 'cat license', 'pet license', 'license tag', 'pet registration', 'rabies',
    'vaccinate', 'vaccination', 'rabies shot', 'rabies vaccine', 'tag',
  ],
  'animal-bites': [
    'bite', 'bitten', 'dog bite', 'cat scratch', 'scratch', 'rabid', 'rabies exposure', 'bat',
    'exposure', 'rabies',
  ],
  'wildlife': [
    'wildlife', 'raccoon', 'squirrel', 'deer', 'fox', 'snake', 'bat', 'possum', 'opossum', 'skunk',
    'groundhog', 'coyote', 'bird', 'geese', 'nuisance animal', 'injured animal', 'wild animal',
  ],

  // Utilities (street lights, power, gas)
  'utilities': [
    'utility', 'utilities', 'bge', 'electric', 'electricity', 'power', 'outage', 'blackout',
    'gas', 'water', 'sewer', 'sewage', 'street light', 'street lights', 'street lamp',
    'street lamps', 'streetlight', 'lamp', 'lamppost', 'light pole', 'power line', 'downed wire',
  ],
  'streetlights': [
    'street light', 'street lights', 'street lamp', 'street lamps', 'streetlight', 'lamp',
    'lamppost', 'lamp post', 'light pole', 'pole', 'light out', 'light is out', 'light outage',
    'bge', 'dark street', 'street is dark', 'broken light',
  ],
  'power-outage': [
    'power', 'outage', 'electric', 'electricity', 'blackout', 'power out', 'no power',
    'downed wire', 'down wire', 'power line', 'wire', 'bge', 'lights out', 'transformer',
  ],
  'gas-leak': [
    'gas', 'gas leak', 'gas smell', 'smell gas', 'natural gas', 'rotten egg', 'carbon monoxide',
  ],
  'water-sewer': [
    'water', 'sewer', 'sewage', 'sewer backup', 'drain', 'storm drain', 'water main', 'pipe',
    'water bill', 'water pressure', 'dirty water', 'boil water', 'drinking water',
  ],

  // Neighborhood & Code Enforcement
  'neighborhood': [
    'neighbor', 'neighborhood', 'code enforcement', 'code violation', 'overgrown', 'high grass',
    'tall grass', 'weeds', 'junk', 'eyesore', 'blight', 'rat', 'rodent', 'mice', 'mouse',
    'vacant', 'abandoned', 'playground', 'recreation',
  ],
  'code-violations': [
    'code', 'violation', 'code enforcement', 'code violation', 'high grass', 'tall grass',
    'overgrown', 'weeds', 'junk', 'blight', 'eyesore', 'unsafe building', 'rental registration',
    'property maintenance', 'vacant house', 'abandoned house', 'neighbor',
  ],
  'rodents': ['rat', 'rodent', 'mice', 'mouse', 'vermin', 'infestation', 'exterminator'],
  'abandoned-vehicles': [
    'abandoned car', 'abandoned vehicle', 'abandoned', 'junk car', 'derelict', 'towed',
    'vehicle', 'car sitting',
  ],
  'parks': ['playground', 'recreation', 'rec center', '88parks', 'trail', 'pool', 'swimming', 'park'],

  // Benefits & Family Help
  'benefits': [
    'snap', 'food stamps', 'food', 'hungry', 'hunger', 'groceries', 'ebt', 'welfare',
    'cash assistance', 'child care', 'childcare', 'daycare', 'assistance', 'social services',
    'senior', 'seniors', 'aging', 'disability', 'disabled', '211', 'food bank',
  ],
  'food-cash': [
    'snap', 'food stamps', 'food', 'hungry', 'hunger', 'groceries', 'ebt', 'cash assistance',
    'welfare', 'child care', 'childcare', 'daycare', 'family assistance', 'social services', 'dss',
  ],
  'senior-disability': [
    'senior', 'seniors', 'elderly', 'aging', 'senior center', 'older adult', 'disability',
    'disabled', 'disabilities', 'wheelchair', 'ada', 'accessibility',
  ],
  'help-referral': [
    '211', 'referral', 'assistance', 'resources', 'community resources', 'local help', 'food bank',
  ],
};

/// Words and phrases for each Resident hub service, keyed by the service title
/// in `services_data.dart`. Same matching rules as [_keywords].
const Map<String, List<String>> _serviceKeywords = {
  'City services': ['311', 'city services', 'county services', 'trash', 'recycling', 'pothole', 'snow', 'report a problem'],
  'Permits': ['permit', 'building permit', 'inspection', 'zoning', 'electrical', 'plumbing permit', 'contractor'],
  'Household Utilities': [
    'street light', 'street lights', 'street lamp', 'street lamps', 'streetlight', 'lamp', 'bge',
    'electric', 'power', 'outage', 'gas', 'water', 'sewer', 'utility', 'utilities',
  ],
  'Public records': ['public records', 'records request', 'public information act', 'pia', 'foia', 'meeting', 'minutes', 'deed'],
  'Transit info': [
    'bus', 'light rail', 'metro', 'mta', 'transit', 'schedule', 'fare', 'mva', 'dmv',
    'drivers license', 'driver license', 'vehicle registration',
  ],
  'County offices': ['county executive', 'council', 'sheriff', 'state attorney', 'elections', 'assessor', 'county office'],
  'Animal services': [
    'animal', 'pet', 'dog', 'cat', 'leash', 'stray', 'barking', 'rabies', 'wildlife',
    'animal control', 'dog license', 'cat license', 'pet license',
  ],
  'Safety & emergency': ['911', 'emergency', 'police', 'fire', 'non emergency', 'storm', 'disaster', '988', 'crisis'],
  'Social services': [
    'social services', 'dss', 'snap', 'food stamps', 'food', 'cash assistance', 'child care',
    'childcare', 'senior', 'aging', 'disability', 'housing assistance', '211',
  ],
  'Community programs': ['community', 'events', '211', 'programs', 'referral'],
};

/// Filler words that carry no meaning for matching ("who do I call about the...").
const Set<String> _stopWords = {
  'a', 'about', 'after', 'all', 'am', 'an', 'and', 'any', 'are', 'as', 'at', 'be', 'because',
  'been', 'but', 'by', 'call', 'can', 'could', 'did', 'do', 'does', 'for', 'from', 'get',
  'give', 'go', 'got', 'had', 'has', 'have', 'help', 'how', 'i', 'if', 'im', 'in', 'into',
  'is', 'it', 'its', 'ive', 'just', 'know', 'like', 'make', 'me', 'more', 'my', 'need',
  'no', 'not', 'of', 'on', 'one', 'or', 'our', 'out', 'over', 'please', 'say', 'should',
  'so', 'some', 'something', 'than', 'that', 'the', 'their', 'them', 'then', 'there',
  'these', 'they', 'this', 'to', 'up', 'us', 'want', 'was', 'we', 'what', 'when', 'where',
  'which', 'who', 'whom', 'whose', 'why', 'will', 'with', 'would', 'you', 'your',
  'wont', 'dont', 'cant', 'doesnt', 'isnt', 'whos',
};

/// Lowercases, turns punctuation into spaces and collapses whitespace.
/// Apostrophes are dropped first so "won't" becomes "wont", not "won t".
String normalizeQuery(String text) {
  final lower = text.toLowerCase().replaceAll(RegExp(r"['’]"), '');
  return lower.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// Folds simple plurals so "potholes" and "taxes" match "pothole" and "tax".
String _fold(String word) {
  if (word.length > 4 && RegExp(r'(xes|ses|ches|shes|zes)$').hasMatch(word)) {
    return word.substring(0, word.length - 2);
  }
  if (word.length > 3 && word.endsWith('s') && !word.endsWith('ss')) {
    return word.substring(0, word.length - 1);
  }
  return word;
}

List<String> _stems(String text) => normalizeQuery(text)
    .split(' ')
    .where((w) => w.isNotEmpty && !_stopWords.contains(w))
    .map(_fold)
    .toList();

/// Two folded words match when they are equal, or when one is a close
/// extension of the other ("rent" / "renting"). Short words must be equal so
/// "car" doesn't match "care".
bool _wordMatches(String a, String b) {
  if (a == b) return true;
  // "parking" starts with "park", but a parking question is not a parks question.
  if ((a == 'parking' && b == 'park') || (a == 'park' && b == 'parking')) return false;
  final shorter = a.length <= b.length ? a : b;
  final longer = a.length <= b.length ? b : a;
  return shorter.length >= 4 && longer.startsWith(shorter) && longer.length - shorter.length <= 3;
}

class _Query {
  final String normalized; // whole query, for phrase matching
  final List<String> stems; // meaningful words, folded

  _Query(String raw)
      : normalized = normalizeQuery(raw),
        stems = _stems(raw);

  bool hasPhrase(String phrase) => ' $normalized '.contains(' $phrase ');
}

/// Points for how well [keywords] describe the query.
int _keywordScore(_Query q, List<String> keywords) {
  var score = 0;
  for (final k in keywords) {
    if (k.contains(' ')) {
      if (q.hasPhrase(k)) score += 6;
    } else if (q.stems.any((s) => _wordMatches(s, _fold(k)))) {
      score += 3;
    }
  }
  return score;
}

/// Points for query words that appear in a name (worth more) or description.
int _textScore(_Query q, String name, String description) {
  final nameWords = _stems(name);
  final descWords = _stems(description);
  var score = 0;
  for (final s in q.stems) {
    if (nameWords.any((w) => _wordMatches(s, w))) {
      score += 3;
    } else if (descWords.any((w) => _wordMatches(s, w))) {
      score += 1;
    }
  }
  return score;
}

int _issueScore(_Query q, Issue issue) =>
    _keywordScore(q, _keywords[issue.id] ?? const []) + _textScore(q, issue.name, issue.description);

/// Ranks the catalog against [query]. Returns an empty list when nothing
/// matches (or the query is blank).
///
/// If the query is made only of filler words ("what is"), it falls back to a
/// plain substring match on names and descriptions so typing never feels dead.
List<SearchHit> searchIssues(String query, {List<IssueCategory>? catalog}) {
  final categories = catalog ?? issueTree;
  final q = _Query(query);
  if (q.normalized.isEmpty) return const [];

  if (q.stems.isEmpty) {
    final needle = q.normalized;
    return [
      for (final c in categories)
        if ([c.name, c.description, ...c.subIssues.map((i) => i.name)]
            .join(' ')
            .toLowerCase()
            .contains(needle))
          SearchHit(category: c, issues: const [], score: 1),
    ];
  }

  final hits = <SearchHit>[];
  for (final c in categories) {
    final categoryScore =
        _keywordScore(q, _keywords[c.id] ?? const []) + _textScore(q, c.name, c.description);

    // Equal scores keep the catalog's order (List.sort alone isn't stable).
    final scored = <({int index, Issue issue, int score})>[
      for (var n = 0; n < c.subIssues.length; n++)
        (index: n, issue: c.subIssues[n], score: _issueScore(q, c.subIssues[n])),
    ].where((e) => e.score > 0).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.index.compareTo(b.index);
      });

    final best = scored.isEmpty ? 0 : scored.first.score;
    final total = categoryScore + best;
    if (total <= 0) continue;

    hits.add(SearchHit(
      category: c,
      issues: scored.take(maxIssuesPerHit).map((e) => e.issue).toList(),
      score: total,
    ));
  }

  final indexed = hits.asMap().entries.toList()
    ..sort((a, b) {
      final byScore = b.value.score.compareTo(a.value.score);
      return byScore != 0 ? byScore : a.key.compareTo(b.key);
    });
  return indexed.map((e) => e.value).toList();
}

/// One Resident hub service that matched the query (tap to open its offices).
class ServiceHit {
  final HubService service;
  final int score;

  const ServiceHit({required this.service, required this.score});
}

/// Most hub services shown under the category results.
const int maxServiceHits = 3;

/// Ranks the Resident hub's services against [query]. Needs a real keyword or
/// title match (score of at least 3), so loose description overlaps don't
/// clutter the list. Returns an empty list for a blank or filler-only query.
List<ServiceHit> searchServices(String query, {List<HubService>? services}) {
  final list = services ?? hubServices;
  final q = _Query(query);
  if (q.normalized.isEmpty || q.stems.isEmpty) return const [];

  final hits = <ServiceHit>[];
  for (var n = 0; n < list.length; n++) {
    final service = list[n];
    final score = _keywordScore(q, _serviceKeywords[service.title] ?? const []) +
        _textScore(q, service.title, service.subtitle);
    if (score >= 3) hits.add(ServiceHit(service: service, score: score));
  }

  // Equal scores keep the hub's display order.
  final indexed = hits.asMap().entries.toList()
    ..sort((a, b) {
      final byScore = b.value.score.compareTo(a.value.score);
      return byScore != 0 ? byScore : a.key.compareTo(b.key);
    });
  return indexed.take(maxServiceHits).map((e) => e.value).toList();
}
