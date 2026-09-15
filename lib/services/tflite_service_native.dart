import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logger/logger.dart';

class TfliteService {
  final Logger _logger = Logger();
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Loads the TFLite model and labels from assets
  Future<void> loadModel() async {
    if (_isLoaded) return;

    try {
      _logger.i('Loading TFLite model...');

      // Load model
      final modelPath = await _loadModelAsset('assets/models/plant_disease_model.tflite');
      _interpreter = await Interpreter.fromFile(File(modelPath));

      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels/plant_labels.txt');
      _labels = labelsData.split('\n').where((l) => l.trim().isNotEmpty).toList();

      _isLoaded = true;
      //_logger.i('Model loaded. Labels: ${_labels!.length}, Input shape: ${_interpreter!.inputShape}, Output shape: ${_interpreter!.outputShape}');
    } catch (e) {
      _logger.e('Failed to load TFLite model: $e');
      _isLoaded = false;
      rethrow;
    }
  }

  /// Copy asset to a temporary file so TFLite can read it
  Future<String> _loadModelAsset(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final buffer = byteData.buffer;
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/${assetPath.split('/').last}');
    await tempFile.writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return tempFile.path;
  }

  /// Runs inference on image bytes and returns top [topK] predictions
  /// Returns list of {label, confidence} maps sorted by confidence desc
  Future<List<MapEntry<String, double>>> analyzeImage({
    required Uint8List imageBytes,
    int topK = 3,
  }) async {
    if (!_isLoaded || _interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      // Decode image
      final image = img_lib.decodeImage(imageBytes);
      if (image == null) throw Exception('Could not decode image');

      // Resize to model input size (e.g. 224x224 for MobileNet-based models)
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final height = inputShape.length > 1 ? inputShape[1] : 224;
      final width = inputShape.length > 2 ? inputShape[2] : 224;

      final resized = img_lib.copyResize(
        image,
        width: width,
        height: height,
        interpolation: img_lib.Interpolation.linear,
      );
      // Build nested input tensor [1, height, width, 3] normalized to [0,1]
      final inputTensor = List.generate(1, (_) =>
        List.generate(height, (_) =>
          List.generate(width, (_) => List.filled(3, 0.0))),
        );

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixel = resized.getPixel(x, y);
          inputTensor[0][y][x][0] = pixel.r.toDouble() / 255.0;
          inputTensor[0][y][x][1] = pixel.g.toDouble() / 255.0;
          inputTensor[0][y][x][2] = pixel.b.toDouble() / 255.0;
        }
      }

      // Output tensor [1, numLabels]
      final output = List.generate(1, (_) => List.filled(_labels!.length, 0.0));

      // Run inference
      _interpreter!.run(inputTensor, output);

      // Extract probabilities and apply softmax
      var rawOutput = output[0] as List<double>;
      var probabilities = _softmax(rawOutput);

      // Get top K predictions
      var indexed = List.generate(probabilities.length, (i) => MapEntry(_labels![i], probabilities[i]));
      indexed.sort((a, b) => b.value.compareTo(a.value));

      final results = indexed.take(topK).toList();
      _logger.i('TFLite top prediction: ${results.first.key} (${(results.first.value * 100).toStringAsFixed(1)}%)');

      return results;
    } catch (e) {
      _logger.e('TFLite inference error: $e');
      rethrow;
    }
  }

  /// Softmax activation
  List<double> _softmax(List<double> input) {
    final maxVal = input.reduce((a, b) => a > b ? a : b);
    final expValues = input.map((e) => math.exp(e - maxVal)).toList();
    final sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((e) => e / sumExp).toList();
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
    _logger.i('TFLite model disposed');
  }
}
