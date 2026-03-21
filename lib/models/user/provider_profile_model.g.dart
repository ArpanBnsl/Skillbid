// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProviderProfileModelImpl _$$ProviderProfileModelImplFromJson(
  Map<String, dynamic> json,
) => _$ProviderProfileModelImpl(
  userId: json['userId'] as String,
  bio: json['bio'] as String?,
  experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
  hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0,
  relScore: (json['relScore'] as num?)?.toDouble() ?? 5.0,
  relStreak: (json['relStreak'] as num?)?.toInt() ?? 0,
  isBanned: json['isBanned'] as bool? ?? false,
  verified: json['verified'] as bool? ?? false,
  isDeleted: json['isDeleted'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$ProviderProfileModelImplToJson(
  _$ProviderProfileModelImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'bio': instance.bio,
  'experienceYears': instance.experienceYears,
  'hourlyRate': instance.hourlyRate,
  'relScore': instance.relScore,
  'relStreak': instance.relStreak,
  'isBanned': instance.isBanned,
  'verified': instance.verified,
  'isDeleted': instance.isDeleted,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
