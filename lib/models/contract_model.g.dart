// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContractModelImpl _$$ContractModelImplFromJson(Map<String, dynamic> json) =>
    _$ContractModelImpl(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      bidId: json['bidId'] as String,
      clientId: json['clientId'] as String,
      providerId: json['providerId'] as String,
      status: json['status'] as String? ?? 'active',
      terminatedBy: json['terminatedBy'] as String?,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      workSubmittedAt: json['workSubmittedAt'] == null
          ? null
          : DateTime.parse(json['workSubmittedAt'] as String),
      providerRating: (json['providerRating'] as num?)?.toInt(),
      clientRating: (json['clientRating'] as num?)?.toInt(),
      reviewText: json['reviewText'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      providerLat: (json['providerLat'] as num?)?.toDouble(),
      providerLng: (json['providerLng'] as num?)?.toDouble(),
      lastLocationUpdate: json['lastLocationUpdate'] == null
          ? null
          : DateTime.parse(json['lastLocationUpdate'] as String),
      trackingEnabled: json['trackingEnabled'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ContractModelImplToJson(_$ContractModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'jobId': instance.jobId,
      'bidId': instance.bidId,
      'clientId': instance.clientId,
      'providerId': instance.providerId,
      'status': instance.status,
      'terminatedBy': instance.terminatedBy,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'workSubmittedAt': instance.workSubmittedAt?.toIso8601String(),
      'providerRating': instance.providerRating,
      'clientRating': instance.clientRating,
      'reviewText': instance.reviewText,
      'isDeleted': instance.isDeleted,
      'providerLat': instance.providerLat,
      'providerLng': instance.providerLng,
      'lastLocationUpdate': instance.lastLocationUpdate?.toIso8601String(),
      'trackingEnabled': instance.trackingEnabled,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
