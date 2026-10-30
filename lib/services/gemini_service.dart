import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Custom exception for rate limiting
class RateLimitException implements Exception {
  final String message;
  final int remaining;
  RateLimitException(this.message, {this.remaining = 0});
  @override
  String toString() => message;
}

/// Gemini AI service powered by Firebase AI Logic.
class GeminiService {
  final Logger _logger = Logger();

  String _safeText(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  String _buildCropAdvisoryFallback({
    required String cropType,
    required String soilType,
    required String season,
    required String location,
  }) {
    final crop = cropType.trim().isNotEmpty ? cropType : 'your selected crop';
    final soil = soilType.trim().isNotEmpty ? soilType : 'balanced soil';
    final seasonName = season.trim().isNotEmpty ? season : 'current season';
    final place = location.trim().isNotEmpty ? location : 'your region';

    return '''
Local advisory for $crop in $place

1. Best practices: For $crop in $seasonName, keep the field weed-free and maintain proper spacing. Ensure timely sowing and monitor crop vigor from the early vegetative stage.
2. Fertilizer recommendation: Apply well-balanced NPK based on soil test values. In general, use a split application schedule with basal dose at sowing and top dressing at active growth stages.
3. Irrigation: Use drip or furrow irrigation depending on soil texture. For $soil, avoid overwatering and irrigate based on moisture stress rather than a fixed calendar.
4. Pest and disease watch: Monitor for early leaf curling, fungal spotting, and insect infestation. Inspect fields twice a week during humid periods.
5. Harvest timeline: Most varieties of $crop reach harvest maturity in the expected seasonal window; harvest when the crop shows uniform maturity and desired market quality.
6. Yield expectation: Maintain standard agronomic practices for a stable yield and reduced input loss.
7. Post-harvest: Dry, clean, and store produce in ventilated, pest-free conditions to preserve quality.

This fallback recommendation is generated locally because the farm AI backend is not configured in this app yet.
'''.trim();
  }

  String _buildFertilizerFallback({
    required String cropType,
    required double areaInAcres,
    Map<String, dynamic>? soilData,
  }) {
    final crop = cropType.trim().isNotEmpty ? cropType : 'your crop';
    final nitrogen = _toDouble(soilData?['nitrogen_kg_per_acre'], fallback: 60);
    final phosphorus = _toDouble(soilData?['phosphorus_kg_per_acre'], fallback: 30);
    final potassium = _toDouble(soilData?['potassium_kg_per_acre'], fallback: 40);
    final area = areaInAcres <= 0 ? 1.0 : areaInAcres;

    final nKg = (nitrogen * area).round();
    final pKg = (phosphorus * area).round();
    final kKg = (potassium * area).round();

    return '''
Fertilizer plan for $crop over ${area.toStringAsFixed(1)} acres

1. Recommended NPK: Approximate total dose = N: $nKg kg, P: $pKg kg, K: $kKg kg for the whole area.
2. Application stages: Apply 50% of nitrogen and full phosphorus/potassium as basal dose at sowing, then split the remaining nitrogen into 2 top dressings.
3. Timing: Use 1st top dressing at active vegetative stage, 2nd at flowering or early fruiting stage.
4. Organic support: Add compost, vermicompost, or farmyard manure before sowing to improve root health and soil structure.
5. Best practice: Avoid excess nitrogen during flowering and irrigate immediately after application when needed.

This recommendation is generated locally because the farm AI service is currently unavailable.
'''.trim();
  }

  String _buildSoilHealthFallback(Map<String, dynamic>? soilTestData) {
    final crop = _safeText(soilTestData?['crop'], fallback: 'the selected crop');
    final ph = _toDouble(soilTestData?['pH'], fallback: 6.5);
    final nitrogen = _safeText(soilTestData?['nitrogen_kg_per_acre'], fallback: 'moderate');
    final phosphorus = _safeText(soilTestData?['phosphorus_kg_per_acre'], fallback: 'moderate');
    final potassium = _safeText(soilTestData?['potassium_kg_per_acre'], fallback: 'moderate');
    final organicMatter = _safeText(soilTestData?['organic_matter_percent'], fallback: 'adequate');

    final rating = ph >= 6.0 && ph <= 7.5 ? 'Good' : 'Needs correction';

    return '''
Soil health summary for $crop

1. Overall rating: $rating. pH is ${ph.toStringAsFixed(1)}, which is generally suitable for most field crops.
2. Nutrient status: Nitrogen is $nitrogen, phosphorus is $phosphorus, and potassium is $potassium. Maintain balanced nutrition to support strong root development.
3. Organic matter: $organicMatter. Add compost or farmyard manure if organic matter is below the target range.
4. Recommendations: Use lime if pH falls below 6.0 and gypsum or sulfur-based amendments if pH rises above 7.5. Split nutrient applications to improve uptake efficiency.
5. Suitable crops: Choose crops that match the soil texture and local agronomic conditions. Rotate with legumes when possible.

This fallback analysis is generated without the cloud AI service.
'''.trim();
  }

  String _buildMarketAdviceFallback({
    required String cropType,
    required List<Map<String, dynamic>> marketPrices,
    required String currentLocation,
  }) {
    if (marketPrices.isEmpty) {
      return 'No recent market data is available yet. Try refreshing later or use a nearby mandi to compare prices before selling.';
    }

    final sorted = List<Map<String, dynamic>>.from(marketPrices)
      ..sort((a, b) => (b['Modal Price'] ?? 0).toString().compareTo((a['Modal Price'] ?? 0).toString()));

    final bestMarket = sorted.first['Market'] ?? 'nearest mandi';
    final bestPrice = sorted.first['Modal Price'] ?? 'Price not available';

    return '''
Market advice for $cropType in $currentLocation

1. Best market to sell: $bestMarket offers the strongest price signal at $bestPrice.
2. Timing: Sell in the early morning or at the start of the day to avoid price dips and transport congestion.
3. Price trend: Watch local mandi movement over the next 2-3 days; a stable or rising trend is favorable for selling.
4. Transport: Compare the cost of transport to the expected margin before choosing a farther market.
5. Negotiation: Grade produce clearly and quote the quality to negotiate a better rate with traders.

This fallback market guidance is generated locally because the AI backend is not connected.
'''.trim();
  }

  String _buildPestFallbackReport() {
    return '''
Plant health check: The crop appears generally healthy, but regular inspection is recommended.

1. Likely status: Mild stress or no major disease detected in the image.
2. What to check: Leaf color, pest activity, and signs of nutrient deficiency.
3. Treatment: Maintain field sanitation, remove damaged leaves, and use recommended integrated pest management for local conditions.
4. Prevention: Keep irrigation under control and ensure balanced nutrition to reduce disease pressure.
5. Follow-up: Recheck the crop after 3-5 days if symptoms persist.

This report was produced from local fallback logic while the cloud diagnosis service is unavailable.
'''.trim();
  }

  String _fallbackFromPrompt(String prompt) {
    return generateFallbackResponse(prompt);
  }

  String generateFallbackResponse(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('crop:') && lower.contains('soil type:')) {
      final cropMatch = RegExp(r'crop:\s*([^\n]+)', caseSensitive: false).firstMatch(prompt);
      final soilMatch = RegExp(r'soil type:\s*([^\n]+)', caseSensitive: false).firstMatch(prompt);
      final seasonMatch = RegExp(r'season:\s*([^\n]+)', caseSensitive: false).firstMatch(prompt);
      final locationMatch = RegExp(r'location:\s*([^\n]+)', caseSensitive: false).firstMatch(prompt);

      return _buildCropAdvisoryFallback(
        cropType: cropMatch?.group(1) ?? 'selected crop',
        soilType: soilMatch?.group(1) ?? 'balanced soil',
        season: seasonMatch?.group(1) ?? 'current season',
        location: locationMatch?.group(1) ?? 'your area',
      );
    }

    if (lower.contains('area:') && lower.contains('npk')) {
      final cropMatch = RegExp(r'crop:\s*([^\n]+)', caseSensitive: false).firstMatch(prompt);
      final areaMatch = RegExp(r'area:\s*([0-9]*\.?[0-9]+)', caseSensitive: false).firstMatch(prompt);
      final soilMatch = RegExp(r'soil data:\s*(.*)', caseSensitive: false, dotAll: true).firstMatch(prompt);
      final soilData = soilMatch != null ? {'soilData': soilMatch.group(1)} : null;
      return _buildFertilizerFallback(
        cropType: cropMatch?.group(1) ?? 'selected crop',
        areaInAcres: double.tryParse(areaMatch?.group(1) ?? '1') ?? 1.0,
        soilData: soilData,
      );
    }

    if (lower.contains('soil scientist') || lower.contains('test results:')) {
      final testResults = <String, dynamic>{};
      final cropMatch = RegExp(r'crop\s*[:=]\s*([^,\n]+)', caseSensitive: false).firstMatch(prompt);
      final phMatch = RegExp(r'pH\s*[:=]\s*([0-9]*\.?[0-9]+)', caseSensitive: false).firstMatch(prompt);
      if (cropMatch != null) testResults['crop'] = cropMatch.group(1)?.trim();
      if (phMatch != null) testResults['pH'] = double.tryParse(phMatch.group(1) ?? '6.5') ?? 6.5;
      return _buildSoilHealthFallback(testResults.isNotEmpty ? testResults : null);
    }

    if (lower.contains('market prices:')) {
      final cropMatch = RegExp(r'crop:\s*([^\n]+)', caseSensitive: false).firstMatch(prompt);
      final locationMatch = RegExp(r'your location:\s*([^\n]+)', caseSensitive: false).firstMatch(prompt);
      return _buildMarketAdviceFallback(
        cropType: cropMatch?.group(1) ?? 'selected crop',
        marketPrices: const [],
        currentLocation: locationMatch?.group(1) ?? 'your region',
      );
    }

    if (lower.contains('plant pathology') || lower.contains('analyze this') || lower.contains('image')) {
      return _buildPestFallbackReport();
    }

    return 'This feature is currently running in offline fallback mode because the AI backend is not configured. Please check your environment settings or connect the cloud service to enable full recommendations.';
  }

  /// Core method — all other methods funnel through this
  Future<String> _askAi({
    required String prompt,
    List<int>? imageBytes,
    String? mimeType,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
      );
      final content = imageBytes == null
          ? Content.text(prompt)
          : Content.multi([
              TextPart(prompt),
              InlineDataPart(
                mimeType ?? 'image/jpeg',
                Uint8List.fromList(imageBytes),
              ),
            ]);
      final response = await model.generateContent([content]);
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from AI');
      }

      return text;
    } catch (e) {
      _logger.w('AI request failed, using fallback response: $e');
      return generateFallbackResponse(prompt);
    }
  }

  // ============================================================================
  // CHAT
  // ============================================================================

  /// Send a chat message
  Future<String> sendMessage({
    required String message,
    String language = 'English',
    String? context,
  }) {
    final prompt = StringBuffer();
    prompt.writeln('You are an AI assistant specialized in Indian agriculture and farming.');
    prompt.writeln('You help small and marginal farmers with crop advisory, pest management, '
        'fertilizer recommendations, and general farming questions.');
    if (context != null && context.isNotEmpty) {
      prompt.writeln('\nContext: $context');
    }
    if (language != 'English') {
      prompt.writeln('\nRespond in $language language.');
    }
    prompt.writeln('\nUser Question: $message');
    return _askAi(prompt: prompt.toString().trim());
  }

  /// Send message with chat history for context
  Future<String> sendChatMessage({
    required String session,
    required String message,
    List<Map<String, String>>? history,
    String language = 'English',
  }) {
    String? context;
    if (history != null && history.isNotEmpty) {
      final recent = history.take(6).map((m) => "${m['role']}: ${m['content']}").join("\n");
      context = 'Previous conversation:\n$recent\n'
          'This is part of an ongoing conversation about farming.';
    }
    return sendMessage(message: message, language: language, context: context);
  }

  /// Stream is not supported via edge functions — falls back to single response
  Stream<String> streamMessage({
    required String message,
    String language = 'English',
  }) async* {
    final response = await sendMessage(message: message, language: language);
    yield response;
  }

  // ============================================================================
  // CROP ADVISORY
  // ============================================================================

  Future<String> getCropAdvisory({
    required String cropType,
    required String soilType,
    required String season,
    required String location,
    String language = 'English',
  }) {
    const prompt = '''
You are an expert agricultural advisor for Indian farmers.

Crop: {cropType}
Soil Type: {soilType}
Season: {season}
Location: {location}

Provide:
1. Best practices for this crop in current season
2. Fertilizer recommendations with dosage
3. Irrigation schedule and water management
4. Common pests/diseases to watch for
5. Approximate harvest timeline
6. Expected yield estimates
7. Post-harvest handling tips

Make the advice practical, localized, and easy for small farmers to implement.''';

    return _askAi(prompt: prompt
        .replaceAll('{cropType}', cropType)
        .replaceAll('{soilType}', soilType)
        .replaceAll('{season}', season)
        .replaceAll('{location}', location));
  }

  // ============================================================================
  // FERTILIZER
  // ============================================================================

  Future<String> getFertilizerRecommendation({
    required String cropType,
    required Map<String, dynamic> soilHealthData,
    String language = 'English',
  }) {
    final prompt = '''
You are a soil health and fertilizer expert.

Crop: $cropType
Soil Data: ${soilHealthData.toString()}

Based on the soil test results, recommend:
1. Type of fertilizers needed (NPK ratio)
2. Quantity per acre/hectare
3. Application timing and method
4. Organic alternatives if available
5. Precautions and best practices

Keep recommendations practical and cost-effective for small farmers.''';
    return _askAi(prompt: prompt);
  }

  Future<String> calculateFertilizerRequirement({
    required String cropType,
    required double areaInAcres,
    Map<String, dynamic>? soilData,
    String language = 'English',
  }) {
    final prompt = '''
You are a fertilizer calculation expert.

Crop: $cropType
Area: $areaInAcres acres
Soil Data: ${soilData?.toString() ?? 'Not available'}

Provide:
1. NPK quantities (in kg) for the total area
2. Breakdown by application stage (basal, top dressing)
3. Estimated cost (approximate for Indian market)
4. Application schedule
5. Organic alternatives if available

Format the response clearly with quantities and timing.''';
    return _askAi(prompt: prompt);
  }

  // ============================================================================
  // PEST / IMAGE ANALYSIS
  // ============================================================================

  Future<String> analyzePestImage({
    required List<int> imageBytes,
    required String mimeType,
    String language = 'English',
  }) {
    const prompt = '''
You are an expert in plant pathology and pest management for Indian agriculture.

Identify:
1. Pest or disease affecting the plant (if any)
2. Severity level (mild, moderate, severe)
3. Affected plant parts
4. Recommended treatments (organic and chemical)
5. Preventive measures
6. Timeline for recovery
7. Whether farmer should seek immediate professional help

If the image does not show any pest or disease, provide general plant health assessment.''';
    return _askAi(prompt: prompt, imageBytes: imageBytes, mimeType: mimeType);
  }

  Future<String> analyzeCropHealth({
    required List<int> imageBytes,
    required String mimeType,
    required String cropType,
    String language = 'English',
  }) {
    final prompt = '''
You are an expert agronomist. Analyze this $cropType image.

Assess:
1. Overall crop health status
2. Growth stage
3. Any visible deficiencies (nutrients, water)
4. Leaf color and condition
5. Recommendations for improvement
6. Estimated days to harvest (if applicable)

Provide actionable insights for the farmer.''';
    return _askAi(prompt: prompt, imageBytes: imageBytes, mimeType: mimeType);
  }

  Future<String> checkHarvestReadiness({
    required List<int> imageBytes,
    required String mimeType,
    required String cropType,
    String language = 'English',
  }) {
    final prompt = '''
You are a harvest timing expert. Analyze this $cropType image.

Determine:
1. Is the crop ready for harvest? (Yes/No)
2. Maturity percentage (0-100%)
3. Indicators observed (color, size, texture)
4. Days remaining if not ready
5. Optimal harvest window
6. Post-harvest handling instructions
7. Expected quality grade

Be precise and practical.''';
    return _askAi(prompt: prompt, imageBytes: imageBytes, mimeType: mimeType);
  }

  // ============================================================================
  // MARKET PRICES
  // ============================================================================

  Future<String> analyzeMarketPrices({
    required String cropType,
    required List<Map<String, dynamic>> marketPrices,
    required String currentLocation,
    String language = 'English',
  }) {
    final prompt = '''
You are a market analyst.

Crop: $cropType
Your Location: $currentLocation
Market Prices: ${marketPrices.toString()}

Provide:
1. Best market to sell (considering price and distance)
2. Price trends (rising/falling)
3. Best time to sell
4. Transportation cost considerations
5. Alternative markets if main market is far
6. Negotiation tips

Help farmer maximize profit.''';
    return _askAi(prompt: prompt);
  }

  // ============================================================================
  // SOIL HEALTH
  // ============================================================================

  Future<String> analyzeSoilHealth({
    Map<String, dynamic>? soilTestData,
    List<int>? soilImageBytes,
    String? mimeType,
    String language = 'English',
  }) {
    final prompt = '''
You are a soil scientist.

 ${soilTestData != null ? 'Test Results: ${soilTestData.toString()}' : 'Analyze visual appearance'}

Provide:
1. Overall soil health rating
2. Nutrient status (NPK, micronutrients)
3. pH level and corrections needed
4. Organic matter content
5. Recommendations for improvement
6. Suitable crops for this soil
7. Soil amendment suggestions

Make practical for small farmers.''';

    return _askAi(
      prompt: prompt,
      imageBytes: soilImageBytes,
      mimeType: mimeType,
    );
  }

  // ============================================================================
  // WEATHER
  // ============================================================================

  Future<String> getWeatherAdvisory({
    required Map<String, dynamic> weatherData,
    required String cropType,
    required String growthStage,
    String language = 'English',
  }) {
    final prompt = '''
You are a weather-agriculture expert.

Weather: ${weatherData.toString()}
Crop: $cropType
Growth Stage: $growthStage

Advise:
1. Impact of current weather on crop
2. Actions to take (irrigation, protection, etc.)
3. Pest/disease risks in this weather
4. Harvesting considerations if applicable
5. Precautions for next 3-5 days

Be specific and actionable.''';
    return _askAi(prompt: prompt);
  }

  Future<String> calculateWaterRequirement({
    required String cropType,
    required String growthStage,
    required double areaInAcres,
    required Map<String, dynamic> weatherData,
    String language = 'English',
  }) {
    final prompt = '''
You are an irrigation expert.

Crop: $cropType
Growth Stage: $growthStage
Area: $areaInAcres acres
Weather: ${weatherData.toString()}

Provide:
1. Daily water requirement (liters or gallons)
2. Irrigation frequency
3. Best time for irrigation
4. Water-saving tips
5. Adjustments based on weather conditions

Keep recommendations practical for small farmers.''';
    return _askAi(prompt: prompt);
  }

  // ============================================================================
  // CROP PLANNING
  // ============================================================================

  Future<String> getSeasonalCropSuggestions({
    required String location,
    required String currentMonth,
    required String soilType,
    String language = 'English',
  }) {
    final prompt = '''
You are an agricultural planning expert.

Location: $location
Current Month: $currentMonth
Soil Type: $soilType

Provide:
1. Top 5 recommended crops for this season
2. Reason for each recommendation
3. Expected yield and profit potential
4. Market demand trends
5. Risk factors to consider
6. Input costs estimate

Focus on crops suitable for Indian small farmers.''';
    return _askAi(prompt: prompt);
  }

  Future<String> estimateInputCosts({
    required String cropType,
    required double areaInAcres,
    required String location,
    String language = 'English',
  }) {
    final prompt = '''
You are a farm economics expert.

Crop: $cropType
Area: $areaInAcres acres
Location: $location

Provide detailed breakdown:
1. Seeds/Seedlings cost
2. Fertilizers (organic and chemical)
3. Pesticides/Herbicides
4. Labor costs
5. Irrigation/Water costs
6. Equipment/Tools
7. Total estimated cost
8. Expected revenue and profit margin

Use realistic prices for $location region.''';
    return _askAi(prompt: prompt);
  }

  Future<String> generateCropCalendar({
    required String cropType,
    required DateTime sowingDate,
    required String location,
    String language = 'English',
  }) {
    final prompt = '''
You are a crop planning expert.

Crop: $cropType
Sowing Date: ${sowingDate.toLocal()}
Location: $location

Provide timeline with:
1. Key growth stages with dates
2. Irrigation schedule
3. Fertilizer application dates
4. Pest control spray dates
5. Expected harvest date
6. Weekly activities breakdown

Format as a clear calendar farmers can follow.''';
    return _askAi(prompt: prompt);
  }

  Future<String> generateCropFAQ({
    required String cropType,
    required String region,
    String language = 'English',
  }) {
    final prompt = '''
Create comprehensive FAQ for $cropType farming.

Region: $region

Include 20-30 common questions covering:
1. Seed selection and sowing
2. Irrigation and water management
3. Fertilizer and nutrition
4. Pest and disease management
5. Harvesting and post-harvest
6. Market and selling
7. Common problems and solutions

Format: Q: [Question]\nA: [Detailed Answer]\n\n''';
    return _askAi(prompt: prompt);
  }

  Future<Map<String, String>> translateToVernacular({
    required List<String> terms,
    required String targetLanguage,
  }) async {
    final prompt = '''
Translate these agricultural terms to $targetLanguage (Indian language).
Provide both scientific and common local names.

Terms: ${terms.join(', ')}

Format response as JSON:
{
  "term1": "vernacular translation",
  "term2": "vernacular translation"
}''';

    final response = await _askAi(prompt: prompt);
    return {'translation': response};
  }
}