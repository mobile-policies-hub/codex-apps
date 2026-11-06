import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const sets = ['AppIconAncient', 'AppIconZenith', 'AppIconApex'];

  for (final setName in sets) {
    test('$setName ships an opaque 1024 icon and every listed PNG', () {
      final directory = Directory(
        'ios/Runner/Assets.xcassets/$setName.appiconset',
      );
      final catalog = jsonDecode(
        File('${directory.path}/Contents.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final slots = catalog['images'] as List<dynamic>;
      final filenames = <String>{};

      for (final slot in slots) {
        final filename = (slot as Map<String, dynamic>)['filename'] as String;
        filenames.add(filename);
        expect(
          File('${directory.path}/$filename').existsSync(),
          isTrue,
          reason: filename,
        );
      }

      expect(filenames, contains('Icon-App-1024x1024@1x.png'));
      final marketing = File('${directory.path}/Icon-App-1024x1024@1x.png')
          .readAsBytesSync();
      expect(_pngSide(marketing), 1024);
      expect(marketing[25], 2, reason: 'RGB color type, no alpha');
      expect(_chunkTypes(marketing), isNot(contains('tRNS')));
    });
  }
}

int _pngSide(List<int> bytes) {
  return (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
}

List<String> _chunkTypes(List<int> bytes) {
  final types = <String>[];
  var offset = 8;
  while (offset + 8 <= bytes.length) {
    final length =
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    types.add(String.fromCharCodes(bytes.sublist(offset + 4, offset + 8)));
    if (types.last == 'IEND') break;
    offset += 12 + length;
  }
  return types;
}
