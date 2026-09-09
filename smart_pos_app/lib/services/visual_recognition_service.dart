import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class VisualRecognitionResult {
  final String label;
  final double confidence;

  VisualRecognitionResult({required this.label, required this.confidence});
}

class VisualRecognitionService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  // Inisialisasi model TFLite & labels
  Future<void> loadModel({
    String modelPath = 'assets/models/model.tflite',
    String labelsPath = 'assets/models/labels.txt',
  }) async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      _isModelLoaded = true;
    } catch (e) {
      // Jika model belum diunggah atau gagal dimuat
      _isModelLoaded = false;
    }
  }

  // Klasifikasi gambar produk dari file gambar
  Future<VisualRecognitionResult?> classifyImage(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) return null;

    final imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return null;

    // Asumsi input model adalah 224x224 RGB (standar MobileNet / Teachable Machine)
    img.Image resizedImage =
        img.copyResize(originalImage, width: 224, height: 224);

    // Normalisasi input [1, 224, 224, 3] float32 (0.0 s/d 1.0 atau -1 s/d 1)
    var input = List.generate(
      1,
      (b) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            var pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    // Output buffer sesuai jumlah kelas
    var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

    _interpreter!.run(input, output);

    List<double> probabilities = output[0];
    int maxIndex = 0;
    double maxConfidence = 0.0;

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        maxIndex = i;
      }
    }

    if (maxIndex < _labels.length) {
      return VisualRecognitionResult(
        label: _labels[maxIndex],
        confidence: maxConfidence,
      );
    }

    return null;
  }

  void dispose() {
    _interpreter?.close();
  }
}
