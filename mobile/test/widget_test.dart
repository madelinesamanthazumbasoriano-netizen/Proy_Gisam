import 'package:flutter_test/flutter_test.dart';
import 'package:gisam_app/core/models/gisam_models.dart';

void main() {
  test('GISAM progress calculates a bounded percentage', () {
    const progress = GisamProgress(xp: 250, xpRequired: 1000);
    expect(progress.progress, 0.25);
  });
}
