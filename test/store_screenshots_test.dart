import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const shots = {
    'ancient_codex': [
      '01_explore_ancient_history.png',
      '02_test_your_knowledge.png',
      '03_discover_glyphs.png',
      '04_track_learning_progress.png',
    ],
    'zenith_habits': [
      '01_build_daily_habits.png',
      '02_visualize_growth.png',
      '03_customize_routine.png',
      '04_stay_accountable.png',
    ],
    'apex_calc': [
      '01_financial_calculations.png',
      '02_currency_conversion.png',
      '03_reports_and_history.png',
      '04_math_and_units.png',
    ],
  };

  test('store screenshots are 1290x2796 RGB PNGs', () {
    for (final folder in shots.entries) {
      for (final name in folder.value) {
        final file = File('assets/store_screenshots/${folder.key}/$name');
        expect(file.existsSync(), isTrue, reason: file.path);
        final bytes = file.readAsBytesSync();
        expect(bytes.sublist(0, 8), [
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]);
        expect(_uint32(bytes, 16), 1290, reason: file.path);
        expect(_uint32(bytes, 20), 2796, reason: file.path);
        expect(bytes[25], 2, reason: 'RGB, no alpha: ${file.path}');
      }
    }
  });
}

int _uint32(List<int> bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
