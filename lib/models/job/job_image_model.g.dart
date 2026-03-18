// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_image_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobImageModelImpl _$$JobImageModelImplFromJson(Map<String, dynamic> json) =>
    _$JobImageModelImpl(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      imageUrl: json['imageUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$JobImageModelImplToJson(_$JobImageModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'jobId': instance.jobId,
      'imageUrl': instance.imageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
    };
