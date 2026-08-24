import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:civic_route/services/congress_service.dart';

void main() {
  test('fetchFederalReps returns MD district 1 rep', () async {
    await dotenv.load(fileName: ".env");

    final reps = await fetchFederalReps("MD", "1");
    for (var rep in reps) {
      print("---");
      print("Name: ${rep.name}");
      print("Phone: ${rep.phone}");
      print("Website: ${rep.website}");
    }

    expect(reps, isNotEmpty);
  });
}