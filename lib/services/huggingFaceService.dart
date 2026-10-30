import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/pest_detection_model.dart';

/// Hugging Face Inference API service for plant disease detection
/// Uses MobileNetV2 model trained on PlantVillage dataset
class HuggingFaceService {
  final Dio _dio;
  final String _apiKey;

  HuggingFaceService({required String apiKey, Dio? dio})
      : _apiKey = apiKey,
        _dio = dio ?? Dio();

  // ✅ UPDATED — New HF router endpoint format
  static const String _baseUrl =
      'https://router.huggingface.co/hf-inference/models/linkanjarad/mobilenet_v2_1.0_224-plant-disease-identification';

  /// Main method: analyzes plant image and returns detection result
  Future<PestDetectionModel> detectDisease(String imagePath) async {
    try {
      final apiKey = _apiKey;
      if (apiKey.isEmpty) {
        throw Exception(
          'HuggingFace API key not found. Add HF_API_KEY to your .env file',
        );
      }

      debugPrint('🔍 HF: Reading image from $imagePath');

      // Read image as raw bytes
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found at $imagePath');
      }
      final imageBytes = await file.readAsBytes();

      debugPrint('🔍 HF: Image size = ${imageBytes.length} bytes');
      debugPrint('🔍 HF: Calling model...');

      // Call HuggingFace Inference API
      final response = await _dio.post(
        _baseUrl,
        data: Stream.fromIterable([imageBytes]),
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/octet-stream',
          },
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 500,
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      debugPrint('🔍 HF: Response status = ${response.statusCode}');

      // Handle model cold start (503 = model loading, retry after wait)
      if (response.statusCode == 503) {
        final estimatedTime = response.data?['estimated_time'] ?? 20;
        debugPrint('⏳ HF: Model is loading, waiting ${estimatedTime}s...');
        await Future.delayed(
          Duration(seconds: (estimatedTime as num).ceil() + 5),
        );
        return detectDisease(imagePath); // Retry
      }

      // Handle non-200 responses
      if (response.statusCode != 200) {
        throw Exception(
          'HF API returned ${response.statusCode}: ${response.data.toString()}',
        );
      }

      // Parse response
      debugPrint('🔍 HF Raw response: ${response.data}');

      final List<dynamic> results = response.data is List
          ? response.data as List<dynamic>
          : [response.data];

      if (results.isEmpty) {
        throw Exception('Model returned no results');
      }

      // Safe cast — guard against unexpected response shapes
      final first = results.first;
      if (first is! Map) {
        throw Exception('Unexpected API response format: $first');
      }
      final topResult = Map<String, dynamic>.from(first);

      // Build detection model from top result
      return _buildDetectionResult(topResult);
    } on DioException catch (e) {
      debugPrint('⛔ HF API error: ${e.message}');
      throw Exception('API call failed: ${e.message}');
    } catch (e) {
      debugPrint('⛔ HF error: $e');
      rethrow;
    }
  }

  /// Builds PestDetectionModel from HF model response
  PestDetectionModel _buildDetectionResult(Map<String, dynamic> topResult) {
    // HF returns label like "Tomato Late Blight" or "Apple Black Rot"
    final rawLabel = (topResult['label'] as String?) ?? 'Unknown Disease';
    final confidence = (topResult['score'] as num?)?.toDouble() ?? 0.0;

    debugPrint(
      '🔍 HF: Detected "$rawLabel" with ${(confidence * 100).toStringAsFixed(1)}% confidence',
    );

    // Parse crop name and disease name from label
    final parsed = _parseLabel(rawLabel);
    final diseaseInfo = _getDiseaseInfo(parsed.diseaseName);

    return PestDetectionModel(
      id: '', // Added required field
      userId: '', // Added required field
      imageUrl: '', // Added required field
      detectionResult: rawLabel,
      pestOrDiseaseName: parsed.diseaseName,
      confidence: confidence,
      cropName: parsed.cropName,
      severity: diseaseInfo['severity'] ?? 'Medium',
      description: diseaseInfo['description'] ??
          'Disease detected by AI model. Consult a local agriculture expert for confirmation.',
      symptoms: List<String>.from(
        diseaseInfo['symptoms'] ?? ['Symptoms information not available'],
      ),
      treatments: _parseTreatments(diseaseInfo['treatments'] ?? []),
      detectedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  /// Parses HF label into crop name and disease name
  /// Examples:
  ///   "Tomato Late Blight" -> crop: Tomato, disease: Late Blight
  ///   "Corn Common Rust" -> crop: Corn, disease: Common Rust
  ///   "Grape Black Rot" -> crop: Grape, disease: Black Rot
  _LabelInfo _parseLabel(String label) {
    String cropName = 'Unknown';
    String diseaseName = label;

    // PlantVillage uses "___" as separator
    if (label.contains('___')) {
      final parts = label.split('___');

      // Crop is everything before "___"
      cropName = parts[0].replaceAll('_', ' ').replaceAll('(,', '(').trim();

      // Disease is everything after "___"
      diseaseName = parts.sublist(1).join(' ').replaceAll('_', ' ').trim();

      // Capitalize first letter of each word
      diseaseName = diseaseName
          .split(' ')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');

      cropName = cropName
          .split(' ')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    } else {
      // Fallback for space-separated labels
      final parts = label.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        cropName = parts.first;
        diseaseName = parts.sublist(1).join(' ');
      }
    }

    debugPrint('🌿 Parsed: crop="$cropName", disease="$diseaseName"');
    return _LabelInfo(cropName: cropName, diseaseName: diseaseName);
  }

  /// Disease info database — maps disease name to symptoms, treatments, severity
  Map<String, dynamic> _getDiseaseInfo(String diseaseName) {
    final normalized = diseaseName.toLowerCase().trim();

    const diseaseDB = <String, Map<String, dynamic>>{
      'late blight': {
        'severity': 'High',
        'description':
            'Late blight is caused by the fungus-like organism Phytophthora infestans. It spreads rapidly in cool, moist conditions and can destroy entire crops within days. This was the pathogen responsible for the Irish Potato Famine.',
        'symptoms': [
          'Dark water-soaked lesions on leaves',
          'White fuzzy growth on leaf undersides',
          'Brown/black stems',
          'Firm dark spots on fruits',
          'Rapid wilting in wet conditions',
        ],
        'treatments': [
          {
            'name': 'Copper-based fungicide',
            'description':
                'Apply bordeaux mixture or copper hydroxide every 7-10 days',
            'type': 'chemical',
          },
          {
            'name': 'Remove infected plants',
            'description':
                'Destroy all infected plant material — do not compost',
            'type': 'cultural',
          },
          {
            'name': 'Improve air circulation',
            'description': 'Space plants adequately and prune lower leaves',
            'type': 'cultural',
          },
          {
            'name': 'Avoid overhead irrigation',
            'description': 'Use drip irrigation to keep foliage dry',
            'type': 'cultural',
          },
        ],
      },
      'early blight': {
        'severity': 'Medium',
        'description':
            'Early blight is caused by the fungus Alternaria solani. It typically appears on older lower leaves first and progresses upward. Common in warm, humid conditions.',
        'symptoms': [
          'Circular dark spots with concentric rings (bullseye pattern)',
          'Yellowing around leaf spots',
          'Leaves dropping from bottom up',
          'Stem lesions near ground level',
        ],
        'treatments': [
          {
            'name': 'Chlorothalonil fungicide',
            'description':
                'Apply at first sign of disease, repeat every 7-14 days',
            'type': 'chemical',
          },
          {
            'name': 'Crop rotation',
            'description': 'Rotate with non-solanaceous crops for 2-3 years',
            'type': 'cultural',
          },
          {
            'name': 'Mulch around plants',
            'description': 'Prevents soil splash onto lower leaves',
            'type': 'cultural',
          },
        ],
      },
      'bacterial spot': {
        'severity': 'Medium',
        'description':
            'Bacterial spot is caused by Xanthomonas species. It affects leaves, fruits, and stems. Spreads rapidly in warm, wet weather and through overhead irrigation.',
        'symptoms': [
          'Small water-soaked spots on leaves',
          'Spots turn brown with yellow halos',
          'Cracks on fruit surface',
          'Leaf drop in severe cases',
        ],
        'treatments': [
          {
            'name': 'Copper-based sprays',
            'description':
                'Apply copper hydroxide before and after rain events',
            'type': 'chemical',
          },
          {
            'name': 'Disease-free seeds/transplants',
            'description':
                'Always start with certified clean planting material',
            'type': 'cultural',
          },
          {
            'name': 'Avoid working with wet plants',
            'description': 'Bacteria spread easily on wet foliage',
            'type': 'cultural',
          },
        ],
      },
      'septoria leaf spot': {
        'severity': 'Medium',
        'description':
            'Septoria leaf spot is caused by the fungus Septoria lycopersici. One of the most common tomato diseases worldwide, it starts on lower leaves and works upward.',
        'symptoms': [
          'Small circular spots with dark borders',
          'Tiny black fruiting bodies in center of spots',
          'Yellowing and dropping of lower leaves',
          'Can defoliate entire plant',
        ],
        'treatments': [
          {
            'name': 'Mancozeb fungicide',
            'description': 'Apply every 7-10 days starting from flowering',
            'type': 'chemical',
          },
          {
            'name': 'Remove lower infected leaves',
            'description': 'Prune and destroy affected foliage immediately',
            'type': 'cultural',
          },
          {
            'name': 'Stake plants for airflow',
            'description':
                'Keep foliage off the ground and improve ventilation',
            'type': 'cultural',
          },
        ],
      },
      'powdery mildew': {
        'severity': 'Medium',
        'description':
            'Powdery mildew is caused by various fungi (Erysiphales). It appears as white powdery coating on leaves and stems. Thrives in warm dry days with cool humid nights.',
        'symptoms': [
          'White powdery patches on leaf surfaces',
          'Leaves curling and twisting',
          'Yellowing and premature leaf drop',
          'Stunted growth in severe infections',
        ],
        'treatments': [
          {
            'name': 'Neem oil spray',
            'description':
                'Mix 2 tablespoons neem oil per gallon of water, spray every 7 days',
            'type': 'organic',
          },
          {
            'name': 'Potassium bicarbonate',
            'description':
                'Mix 1 tablespoon per gallon of water as foliar spray',
            'type': 'organic',
          },
          {
            'name': 'Sulfur dust',
            'description':
                'Apply sulfur-based fungicide early before infection spreads',
            'type': 'chemical',
          },
          {
            'name': 'Increase plant spacing',
            'description': 'Ensure adequate air circulation between plants',
            'type': 'cultural',
          },
        ],
      },
      'target spot': {
        'severity': 'Medium',
        'description':
            'Target spot is caused by the fungus Corynespora cassiicola. It produces distinctive concentric ring patterns on leaves, similar to a target or bullseye.',
        'symptoms': [
          'Large circular spots with concentric rings',
          'Dark brown lesion centers',
          'Yellowing around spots',
          'Premature leaf drop',
        ],
        'treatments': [
          {
            'name': 'Azoxystrobin fungicide',
            'description': 'Apply preventively every 14 days',
            'type': 'chemical',
          },
          {
            'name': 'Remove infected debris',
            'description': 'Clean up plant residues at end of season',
            'type': 'cultural',
          },
        ],
      },
      'mosaic virus': {
        'severity': 'High',
        'description':
            'Mosaic virus (TMV or other tobamoviruses) causes mottled pattern on leaves. It is highly contagious and spreads through contact, tools, and aphids.',
        'symptoms': [
          'Mottled green and yellow pattern on leaves',
          'Curling and distortion of leaves',
          'Stunted plant growth',
          'Reduced fruit production',
        ],
        'treatments': [
          {
            'name': 'Remove and destroy infected plants',
            'description':
                'No cure exists — remove entire plant to prevent spread',
            'type': 'cultural',
          },
          {
            'name': 'Disinfect tools',
            'description': 'Wash tools with 10% bleach solution between plants',
            'type': 'cultural',
          },
          {
            'name': 'Use virus-resistant varieties',
            'description':
                'Plant certified TMV-resistant varieties next season',
            'type': 'cultural',
          },
          {
            'name': 'Control aphid populations',
            'description':
                'Use reflective mulch or insecticidal soap to reduce vectors',
            'type': 'chemical',
          },
        ],
      },
      'yellow leaf curl virus': {
        'severity': 'High',
        'description':
            'Tomato yellow leaf curl virus (TYLCV) is transmitted by whiteflies. It causes severe stunting, leaf curling, and massive yield loss. Very common in tropical and subtropical regions.',
        'symptoms': [
          'Severe upward curling of leaf edges',
          'Yellowing of leaf margins',
          'Stunted plant growth',
          'Dramatically reduced fruit set',
          'Small, dry fruits if any are produced',
        ],
        'treatments': [
          {
            'name': 'Remove infected plants immediately',
            'description':
                'No cure — destroy plants to reduce whitefly transmission',
            'type': 'cultural',
          },
          {
            'name': 'Whitefly control',
            'description': 'Use yellow sticky traps and apply imidacloprid',
            'type': 'chemical',
          },
          {
            'name': 'Use TYLCV-resistant varieties',
            'description': 'Plant resistant hybrids like Tygress or TY20',
            'type': 'cultural',
          },
        ],
      },
      'common rust': {
        'severity': 'Low',
        'description':
            'Common rust of corn is caused by Puccinia sorghi. It appears as reddish-brown pustules on leaves. Yield loss depends on severity and timing of infection.',
        'symptoms': [
          'Small reddish-brown pustules on upper leaf surface',
          'Dark brown powder (spores) when rubbed',
          'Heavier infection on upper leaves',
          'Reduced photosynthesis',
        ],
        'treatments': [
          {
            'name': 'Triazole fungicide',
            'description':
                'Apply propiconazole or tebuconazole at early infection',
            'type': 'chemical',
          },
          {
            'name': 'Plant resistant hybrids',
            'description': 'Use corn varieties with Ht or Rp resistance genes',
            'type': 'cultural',
          },
          {
            'name': 'Scout fields early',
            'description': 'Monitor from V6 stage onward for early detection',
            'type': 'cultural',
          },
        ],
      },
      'northern leaf blight': {
        'severity': 'Medium',
        'description':
            'Northern corn leaf blight is caused by Setosphaeria turcica. It produces large elongated grayish-green lesions on leaves. Favored by cool, moist weather.',
        'symptoms': [
          'Large elongated cigar-shaped lesions (1-6 inches)',
          'Grayish-green to tan colored spots',
          'Lesions may merge and kill entire leaves',
          'Significant yield loss if infected before silking',
        ],
        'treatments': [
          {
            'name': 'Foliar fungicide application',
            'description':
                'Apply azoxystrobin + propiconazole between VT and R2',
            'type': 'chemical',
          },
          {
            'name': 'Resistant hybrids',
            'description': 'Plant NCLB-resistant corn hybrids',
            'type': 'cultural',
          },
          {
            'name': 'Crop residue management',
            'description':
                'Till under corn residue to reduce overwintering spores',
            'type': 'cultural',
          },
        ],
      },
      'black rot': {
        'severity': 'High',
        'description':
            'Black rot can affect apples and grapes. For apples, it is caused by Botryosphaeria obtusa. For grapes, it is caused by Guignardia bidwellii. Both cause dark, sunken lesions on fruit.',
        'symptoms': [
          'Dark purple/black lesions on fruit',
          'Fruit shriveling and mummifying',
          'Cankers on branches',
          'Leaf spotting with dark margins',
        ],
        'treatments': [
          {
            'name': 'Captan fungicide',
            'description':
                'Apply captan or myclobutanil at pink bud stage and after petal fall',
            'type': 'chemical',
          },
          {
            'name': 'Prune infected branches',
            'description':
                'Cut 6-8 inches below visible canker during dormant season',
            'type': 'cultural',
          },
          {
            'name': 'Remove mummified fruit',
            'description': 'Clean up all dried fruit from previous season',
            'type': 'cultural',
          },
        ],
      },
      'cedar apple rust': {
        'severity': 'Medium',
        'description':
            'Cedar apple rust requires two hosts: cedar (juniper) and apple trees. Caused by Gymnosporangium juniperi-virginianae. Produces orange gelatinous galls on cedar and orange spots on apple leaves.',
        'symptoms': [
          'Bright orange spots on upper leaf surface',
          'Small black dots in center of spots',
          'Cup-like structures on leaf underside',
          'Premature leaf drop',
          'Fruit deformation',
        ],
        'treatments': [
          {
            'name': 'Myclobutanil spray',
            'description': 'Apply before and after bloom for prevention',
            'type': 'chemical',
          },
          {
            'name': 'Remove nearby cedar trees',
            'description':
                'Break the disease cycle by eliminating alternate host',
            'type': 'cultural',
          },
          {
            'name': 'Plant resistant varieties',
            'description': 'Use varieties like Enterprise, Liberty, or Freedom',
            'type': 'cultural',
          },
        ],
      },
      'apple scab': {
        'severity': 'Medium',
        'description':
            'Apple scab is caused by Venturia inaequalis. It is the most common apple disease worldwide. Favored by cool, wet spring weather.',
        'symptoms': [
          'Olive-green to brown velvety spots on leaves',
          'Leaves curling and dropping prematurely',
          'Corky, cracked lesions on fruit',
          'Fruit distortion in severe cases',
        ],
        'treatments': [
          {
            'name': 'Captan or sulfur spray',
            'description':
                'Apply from green tip through petal fall, every 7-10 days',
            'type': 'chemical',
          },
          {
            'name': 'Rake and destroy fallen leaves',
            'description': 'Remove infected leaves from under trees in autumn',
            'type': 'cultural',
          },
        ],
      },
      'leaf scorch': {
        'severity': 'Low',
        'description':
            'Bacterial leaf scorch is caused by Xylella fastidiosa. It causes marginal browning of leaves and progressive decline. Common in grapes, shade trees, and some crops.',
        'symptoms': [
          'Brown, scorched margins on leaves',
          'Green tissue along leaf midrib persists',
          'Progressive browning from leaf edges inward',
          'Premature defoliation',
          'Gradual decline over years',
        ],
        'treatments': [
          {
            'name': 'Antibiotic injection',
            'description':
                'Oxytetracycline trunk injections may slow progression',
            'type': 'chemical',
          },
          {
            'name': 'Remove severely infected trees',
            'description': 'Prevent spread by removing advanced cases',
            'type': 'cultural',
          },
          {
            'name': 'Maintain tree health',
            'description': 'Proper watering and mulching reduce stress',
            'type': 'cultural',
          },
        ],
      },
      'healthy': {
        'severity': 'None',
        'description':
            'The plant appears healthy with no visible disease symptoms. Continue regular care and monitoring for early detection of any issues.',
        'symptoms': [
          'Normal green leaf color',
          'No spots, lesions, or discoloration',
          'Healthy growth pattern',
          'No signs of wilting or curling',
        ],
        'treatments': [
          {
            'name': 'Continue regular watering',
            'description':
                'Maintain consistent soil moisture without overwatering',
            'type': 'cultural',
          },
          {
            'name': 'Apply balanced fertilizer',
            'description':
                'Feed with NPK fertilizer according to crop schedule',
            'type': 'cultural',
          },
          {
            'name': 'Monitor regularly',
            'description': 'Inspect plants weekly for early signs of disease',
            'type': 'cultural',
          },
        ],
      },
      'downy mildew': {
        'severity': 'High',
        'description':
            'Downy mildew is caused by various oomycete pathogens. It thrives in cool, wet conditions and can spread rapidly. Different species affect grapes, cucurbits, onions, and other crops.',
        'symptoms': [
          'Yellow patches on upper leaf surface',
          'Grayish-white fuzzy growth on leaf underside',
          'Leaf curling and dieback',
          'Rapid spread during humid conditions',
        ],
        'treatments': [
          {
            'name': 'Metalaxyl + mancozeb',
            'description':
                'Apply combination fungicide at first sign of infection',
            'type': 'chemical',
          },
          {
            'name': 'Improve drainage',
            'description': 'Ensure good air circulation and reduce humidity',
            'type': 'cultural',
          },
          {
            'name': 'Avoid wetting foliage',
            'description': 'Use drip irrigation instead of overhead watering',
            'type': 'cultural',
          },
        ],
      },
      'anthracnose': {
        'severity': 'Medium',
        'description':
            'Anthracnose is caused by various Colletotrichum species. It affects many crops including mango, chili, tomato, and pepper. Produces dark sunken lesions on fruits and leaves.',
        'symptoms': [
          'Dark, sunken circular lesions on fruit',
          'Pinkish-orange spore masses in wet conditions',
          'Leaf spots with dark margins',
          'Fruit rotting and dropping',
        ],
        'treatments': [
          {
            'name': 'Mancozeb spray',
            'description':
                'Apply preventively before fruit set, continue every 10-14 days',
            'type': 'chemical',
          },
          {
            'name': 'Prune for air circulation',
            'description': 'Open canopy to reduce humidity and infection risk',
            'type': 'cultural',
          },
          {
            'name': 'Remove infected fruit',
            'description': 'Pick and destroy all diseased fruit immediately',
            'type': 'cultural',
          },
        ],
      },
      'leaf mold': {
        'severity': 'Low',
        'description':
            'Leaf mold of tomato is caused by Passalora fulva (formerly Fulvia fulva). It is common in greenhouse tomatoes where humidity is high and air circulation is poor.',
        'symptoms': [
          'Pale green to yellow patches on upper leaf surface',
          'Grayish-purple fuzzy growth on leaf underside',
          'Leaves curling upward',
          'Leaf drop starting from bottom',
        ],
        'treatments': [
          {
            'name': 'Increase ventilation',
            'description':
                'Open greenhouse vents and use fans to reduce humidity',
            'type': 'cultural',
          },
          {
            'name': 'Chlorothalonil spray',
            'description': 'Apply fungicide if infection is detected early',
            'type': 'chemical',
          },
        ],
      },
      'bacterial wilt': {
        'severity': 'High',
        'description':
            'Bacterial wilt is caused by Ralstonia solanacearum. It is one of the most devastating plant diseases, causing rapid wilting and death. Affects tomatoes, potatoes, eggplants, and bananas.',
        'symptoms': [
          'Sudden wilting of entire plant while still green',
          'Brown discoloration of vascular tissue when stem is cut',
          'Milky bacterial ooze from cut stem in water',
          'Rapid plant death within days',
        ],
        'treatments': [
          {
            'name': 'Remove and destroy entire plant',
            'description':
                'Do not compost — pathogen persists in soil for years',
            'type': 'cultural',
          },
          {
            'name': 'Soil solarization',
            'description':
                'Cover soil with clear plastic for 6-8 weeks in hot season',
            'type': 'cultural',
          },
          {
            'name': 'Use resistant varieties',
            'description': 'Plant bacterial wilt-resistant rootstocks',
            'type': 'cultural',
          },
          {
            'name': 'Apply biological control',
            'description':
                'Use Pseudomonas fluorescens or Trichoderma formulations',
            'type': 'organic',
          },
        ],
      },
      'verticillium wilt': {
        'severity': 'High',
        'description':
            'Verticillium wilt is caused by Verticillium dahliae. It is a soil-borne fungus that invades through roots and blocks water transport. Affects tomatoes, potatoes, peppers, and many other crops.',
        'symptoms': [
          'Yellowing and wilting of lower leaves first',
          'V-shaped yellow areas on leaf margins',
          'Brown discoloration inside stem',
          'Stunted growth and reduced yield',
          'One-sided wilting common',
        ],
        'treatments': [
          {
            'name': 'Remove infected plants',
            'description':
                'Destroy plants — do not replant susceptible crops in same spot',
            'type': 'cultural',
          },
          {
            'name': 'Soil solarization',
            'description':
                'Cover moist soil with clear plastic for 4-6 weeks in summer',
            'type': 'cultural',
          },
          {
            'name': 'Rotate with non-host crops',
            'description':
                'Plant grains or legumes for 4-5 years before solanaceous crops',
            'type': 'cultural',
          },
        ],
      },
      'fusarium wilt': {
        'severity': 'High',
        'description':
            'Fusarium wilt is caused by Fusarium oxysporum. It is a soil-borne pathogen that blocks water-conducting vessels. Different formae speciales attack different crops (tomato, banana, etc.).',
        'symptoms': [
          'Yellowing of lower leaves on one side first',
          'Wilting during day, recovery at night initially',
          'Brown discoloration of vascular tissue',
          'Stunted growth',
          'Eventual plant death',
        ],
        'treatments': [
          {
            'name': 'Use resistant varieties',
            'description':
                'Plant with F resistance gene (e.g., tomato hybrids)',
            'type': 'cultural',
          },
          {
            'name': 'Graft onto resistant rootstock',
            'description':
                'Use Fusarium-resistant rootstocks for susceptible scions',
            'type': 'cultural',
          },
          {
            'name': 'Soil fumigation',
            'description':
                'For severe cases, consider professional soil treatment',
            'type': 'chemical',
          },
        ],
      },
      'leaf miner': {
        'severity': 'Low',
        'description':
            'Leaf miners are insect larvae that feed between the upper and lower surfaces of leaves, creating distinctive tunnel-like patterns. Common on tomatoes, spinach, and various vegetables.',
        'symptoms': [
          'Winding tunnels or blotches inside leaves',
          'White or translucent trails visible on leaf surface',
          'Leaf dropping in heavy infestations',
          'Reduced photosynthesis and growth',
        ],
        'treatments': [
          {
            'name': 'Neem oil spray',
            'description': 'Apply neem oil to kill larvae in tunnels',
            'type': 'organic',
          },
          {
            'name': 'Remove affected leaves',
            'description':
                'Destroy heavily infested leaves to break life cycle',
            'type': 'cultural',
          },
          {
            'name': 'Yellow sticky traps',
            'description': 'Trap adult flies before they lay eggs',
            'type': 'physical',
          },
        ],
      },
      'spider mites': {
        'severity': 'Medium',
        'description':
            'Spider mites are tiny arachnids that suck sap from plant cells. They thrive in hot, dry conditions and can rapidly build up populations. Often found on undersides of leaves.',
        'symptoms': [
          'Tiny yellow dots (stippling) on leaves',
          'Fine webbing between leaves and stems',
          'Leaves turning yellow and bronze',
          'Premature leaf drop',
        ],
        'treatments': [
          {
            'name': 'Strong water spray',
            'description': 'Blast plants with water to dislodge mites',
            'type': 'physical',
          },
          {
            'name': 'Insecticidal soap',
            'description': 'Apply every 3-5 days for 2-3 weeks',
            'type': 'organic',
          },
          {
            'name': 'Neem oil',
            'description':
                'Spray neem oil every 7 days, covers eggs and adults',
            'type': 'organic',
          },
          {
            'name': 'Increase humidity',
            'description':
                'Mist plants regularly as mites prefer dry conditions',
            'type': 'cultural',
          },
        ],
      },
      'cercospora leaf spot': {
        'severity': 'Medium',
        'description':
            'Cercospora leaf spot is caused by Cercospora species. It affects many crops including beet, soybean, and peanut. Produces circular spots with gray centers and dark borders.',
        'symptoms': [
          'Circular spots with ash-gray centers',
          'Dark red to brown borders on spots',
          'Spots may merge and kill large leaf areas',
          'Premature leaf drop',
        ],
        'treatments': [
          {
            'name': 'Chlorothalonil fungicide',
            'description': 'Apply every 7-10 days during favorable conditions',
            'type': 'chemical',
          },
          {
            'name': 'Crop rotation',
            'description': 'Rotate out of susceptible crops for 2 years',
            'type': 'cultural',
          },
          {
            'name': 'Destroy infected debris',
            'description':
                'Remove and burn infected plant material after harvest',
            'type': 'cultural',
          },
        ],
      },
    };

    // Search for matching disease (partial match support)
    for (final entry in diseaseDB.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    // Default response for unmatched diseases
    return {
      'severity': 'Medium',
      'description':
          '$diseaseName was detected by the AI model. Please consult a local agriculture expert for detailed diagnosis and treatment recommendations specific to your region.',
      'symptoms': [
        'Detected by AI image analysis',
        'Consult local expert for detailed symptoms',
      ],
      'treatments': [
        {
          'name': 'Consult agriculture expert',
          'description':
              'Visit your nearest Krishi Vigyan Kendra for detailed guidance',
          'type': 'cultural',
        },
        {
          'name': 'Isolate the plant',
          'description':
              'If possible, separate from other plants to prevent spread',
          'type': 'cultural',
        },
      ],
    };
  }

  /// Parses treatment list from disease DB into TreatmentRecommendation objects
  List<TreatmentRecommendation> _parseTreatments(List<dynamic> treatments) {
    return treatments.map((t) {
      if (t is Map) {
        return TreatmentRecommendation(
          method: t['type']?.toString() ?? t['method']?.toString() ?? 'general',
          name: t['name']?.toString() ?? 'Unknown',
          description: t['description']?.toString() ?? '',
          dosage: t['dosage']?.toString(),
          applicationMethod: t['applicationMethod']?.toString(),
        );
      }
      return TreatmentRecommendation(
        name: t.toString(),
        description: '',
        method: 'general',
      );
    }).toList();
  }
}

/// Helper class for parsed label info
class _LabelInfo {
  final String cropName;
  final String diseaseName;
  _LabelInfo({required this.cropName, required this.diseaseName});
}
