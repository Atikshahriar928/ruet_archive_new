import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  /// Compresses an image and encodes it to a Base64 string.
  /// Replicates the logic of: 
  /// 1. Auto-rotation (EXIF)
  /// 2. Scale down to max 800px
  /// 3. JPEG compression at 50% quality
  static Future<String?> compressAndEncodeToBase64(String path) async {
    try {
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        path,
        path + "_compressed.jpg", // Temporary path suffix
        quality: 50,
        minWidth: 800,
        minHeight: 800,
        rotate: 0, // 0 means it will use EXIF to auto-rotate
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) return null;

      final Uint8List bytes = await compressedFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("ImageUtils compress ERROR: $e");
      return null;
    }
  }

  /// Decodes a Base64 string into Uint8List bytes for use with Image.memory().
  static Uint8List? decodeBase64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print("ImageUtils decode ERROR: $e");
      return null;
    }
  }
}
