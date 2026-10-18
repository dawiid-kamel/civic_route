/// Forgiving search over the issue catalog.
///
/// The Home search box accepts plain words ("pothole"), everyday phrases
/// ("my landlord won't fix the heat") and whole questions ("who do I call about
/// a missed trash pickup?"). Each category and sub-issue carries a list of
/// related words in [_keywords]; the query is cleaned up (lowercased,
/// punctuation and filler words removed, plurals folded) and scored against
/// those words plus the names and descriptions in `issue_tree.dart`.
/// `HomeScreen` shows the ranked [SearchHit]s in place of its other panels.
library;

import '../models/issue.dart';
import 'issue_tree.dart';

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
    'crosswalk', 'transit',
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
    'sheriff', 'unsafe',
  ],
  'environment': [
    'pollution', 'air', 'water quality', 'climate', 'recycling', 'trash', 'garbage',
    'litter', 'dumping', 'waste', 'trees', 'toxic', 'spill', 'wildlife', 'emissions',
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
    'pothole', 'road', 'street', 'sidewalk', 'pavement', 'streetlight', 'street light',
    'traffic light', 'signal', 'snow', 'plow', 'snow removal', 'crosswalk', 'curb', 'drain',
    'repair', 'speed bump',
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
