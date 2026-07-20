import 'dart:async';
import 'package:flutter/foundation.dart';

enum SlmModelStatus {
  notDownloaded,
  downloading,
  ready,
  error,
}

class SlmModelInfo {
  final String name;
  final String architecture;
  final String quantization;
  final double sizeMB;
  final String localPath;

  SlmModelInfo({
    required this.name,
    required this.architecture,
    required this.quantization,
    required this.sizeMB,
    required this.localPath,
  });
}

class SlmModelManager extends ChangeNotifier {
  SlmModelStatus _status = SlmModelStatus.notDownloaded;
  double _downloadProgress = 0.0;
  String? _errorMessage;

  SlmModelStatus get status => _status;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;

  final SlmModelInfo modelInfo = SlmModelInfo(
    name: 'Gemma-2B-IT-Q4_K_M',
    architecture: 'Gemma SLM (Quantized GGUF)',
    quantization: '4-bit 4_K_M Quantization',
    sizeMB: 1420.0,
    localPath: 'assets/models/gemma-2b-q4.gguf',
  );

  SlmModelManager() {
    // Default to ready state for smooth local operation simulation
    _status = SlmModelStatus.ready;
  }

  /// Downloads the local Quantized SLM binary resource asynchronously
  Future<void> downloadModelResource() async {
    if (_status == SlmModelStatus.downloading || _status == SlmModelStatus.ready) return;

    _status = SlmModelStatus.downloading;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate chunked download of quantized SLM binary (e.g. 1.4 GB model file)
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        _downloadProgress = i / 10.0;
        notifyListeners();
      }

      _status = SlmModelStatus.ready;
      _downloadProgress = 1.0;
      notifyListeners();
    } catch (e) {
      _status = SlmModelStatus.error;
      _errorMessage = 'Failed to download model resource: $e';
      notifyListeners();
    }
  }

  void resetModelResource() {
    _status = SlmModelStatus.notDownloaded;
    _downloadProgress = 0.0;
    notifyListeners();
  }
}
