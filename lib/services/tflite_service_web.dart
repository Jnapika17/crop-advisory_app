import 'dart:typed_data';

class TfliteService {
  bool get isLoaded => false;

  Future<void> loadModel() async {
    throw UnsupportedError('On-device TFLite is not supported on web. Use Gemini cloud analysis instead.');
  }

  Future<List<MapEntry<String, double>>> analyzeImage({
    required Uint8List imageBytes,
    int topK = 3,
  }) async {
    throw UnsupportedError('On-device TFLite is not supported on web. Use Gemini cloud analysis instead.');
  }

  void dispose() {}
}
