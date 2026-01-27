import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Save bytes to a temporary file and return the file path
Future<String> saveBytesToTempFile(Uint8List bytes, String filename) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}

/// Run Tesseract OCR on an image file using a Python script
Future<String> runTesseractOCR(Uint8List imageBytes, String filename) async {
  final path = await saveBytesToTempFile(imageBytes, filename);
  final result = await Process.run(
    'python3',
    ['tesseract_ocr.py', path],
    workingDirectory: Directory.current.path,
  );
  if (result.exitCode != 0) {
    throw Exception('Tesseract OCR failed: ${result.stderr}');
  }
  return result.stdout.toString();
}
