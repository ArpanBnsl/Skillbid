// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobModelImpl _$$JobModelImplFromJson(Map<String, dynamic> json) =>
    _$JobModelImpl(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      budget: (json['budget'] as num).toDouble(),
      location: json['location'] as String,
      skillId: (json['skillId'] as num).toInt(),
      desiredCompletionDays: (json['desiredCompletionDays'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'open',
      isDeleted: json['isDeleted'] as bool? ?? false,
      isImmediate: json['isImmediate'] as bool? ?? false,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      jobLat: (json['jobLat'] as num?)?.toDouble(),
      jobLng: (json['jobLng'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$JobModelImplToJson(_$JobModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'title': instance.title,
      'description': instance.description,
      'budget': instance.budget,
      'location': instance.location,
      'skillId': instance.skillId,
      'desiredCompletionDays': instance.desiredCompletionDays,
      'status': instance.status,
      'isDeleted': instance.isDeleted,
      'isImmediate': instance.isImmediate,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'jobLat': instance.jobLat,
      'jobLng': instance.jobLng,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
