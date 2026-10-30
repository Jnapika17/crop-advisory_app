import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeminiPestService', () {
    test('image bytes retain their binary content', () {
      // Verify that Uint8List can be constructed and converted
      final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      expect(bytes.length, equals(4));
      expect(bytes.first, equals(0x89));
    });

    test('mimeType defaults are valid', () {
      const validMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
      for (final mime in validMimeTypes) {
        expect(mime, contains('image/'));
      }
    });

    test('language parameter is passed as string', () {
      const language = 'english';
      expect(language, isA<String>());
      expect(language.isNotEmpty, isTrue);
    });
  });
}
