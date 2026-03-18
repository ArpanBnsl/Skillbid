import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_image_model.freezed.dart';
part 'job_image_model.g.dart';

@freezed
class JobImageModel with _$JobImageModel {
  const factory JobImageModel({
    required String id,
    required String jobId,
    required String imageUrl,
    required DateTime createdAt,
  }) = _JobImageModel;

  factory JobImageModel.fromJson(Map<String, dynamic> json) => _$JobImageModelFromJson(json);
}
