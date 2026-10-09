/// Small text/date formatting helpers shared by the screens.
///
/// `formatDate` ("Oct 7, 2026") labels cached results on the Results screen;
/// `formatVerified` turns a contact's `lastVerified` value ("2026-09" or
/// "2026-09-30") into "Sep 2026" for the "Verified" stamp on contact cards.
library;

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

String? formatVerified(String? iso) {
  if (iso == null) return null;
  final parts = iso.split('-');
  if (parts.length < 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) return null;
  return '${_months[month - 1]} $year';
}
