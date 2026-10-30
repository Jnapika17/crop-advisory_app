import 'package:flutter_test/flutter_test.dart';
import 'package:crop_advisory/services/gemini_service.dart';

void main() {
  group('GeminiService fallback logic', () {
    final service = GeminiService();

    test('returns a crop advisory fallback when backend is unavailable', () {
      final result = service.generateFallbackResponse('''
Crop: Rice
Soil Type: Black Soil
Season: Kharif (Monsoon)
Location: Nashik
''');

      expect(result, contains('Local advisory for Rice'));
      expect(result, contains('Nashik'));
      expect(result, contains('fallback'));
    });

    test('returns a fertilizer fallback with area-based estimate', () {
      final result = service.generateFallbackResponse('''
Crop: Wheat
Area: 2.5 acres
Soil Data: {nitrogen_kg_per_acre: 60, phosphorus_kg_per_acre: 30, potassium_kg_per_acre: 40}
NPK recommendations
''');

      expect(result, contains('Fertilizer plan for Wheat'));
      expect(result, contains('2.5 acres'));
      expect(result, contains('N: 150'));
    });

    test('returns a soil health fallback when soil metrics are provided', () {
      final result = service.generateFallbackResponse('''
Soil scientist analysis
Crop: Cotton
pH: 6.8
Test Results: nitrogen=70
''');

      expect(result, contains('Soil health summary for Cotton'));
      expect(result, contains('Good'));
    });
  });
}
