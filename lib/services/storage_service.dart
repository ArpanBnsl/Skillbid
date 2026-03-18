import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

class StorageService {
  final _imagePicker = ImagePicker();

  /// Pick image from gallery
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final image = await _imagePicker.pickImage(source: source);
      return image;
    } catch (e) {
      AppLogger.logError('Image pick failed', e);
      throw AppException(
        message: 'Image pick failed: $e',
        originalException: e,
      );
    }
  }

  /// Upload image to Supabase Storage
  Future<String> uploadImage({
    required XFile image,
    required String bucket,
    required String path,
  }) async {
    try {
      final bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final filePath = '$path/$fileName';

      await supabase.storage.from(bucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final publicUrl = supabase.storage.from(bucket).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      AppLogger.logError('Image upload failed', e);
      throw AppException(
        message: 'Image upload failed: $e',
        originalException: e,
      );
    }
  }

  /// Delete image from storage
  Future<void> deleteImage({
    required String bucket,
    required String path,
  }) async {
    try {
      await supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      AppLogger.logError('Image delete failed', e);
      throw AppException(
        message: 'Image delete failed: $e',
        originalException: e,
      );
    }
  }

  /// Get public URL for an image
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return supabase.storage.from(bucket).getPublicUrl(path);
  }
}
