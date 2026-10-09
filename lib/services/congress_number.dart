/// Works out which numbered U.S. Congress is currently in session.
///
/// A new Congress is sworn in on January 3 of every odd year (the 119th began
/// in January 2025; the 120th begins in January 2027). `congress_service.dart`
/// uses this for the Congress.gov URL and `location_service.dart` uses it to
/// pick the right congressional-district layer, so neither needs a yearly edit.
library;

int currentCongress([DateTime? now]) {
  final date = now ?? DateTime.now();
  var year = date.year;
  if (year.isOdd && date.month == 1 && date.day < 3) year -= 1;
  return (year - 1789) ~/ 2 + 1;
}
