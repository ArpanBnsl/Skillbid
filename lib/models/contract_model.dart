import 'package:freezed_annotation/freezed_annotation.dart';

part 'contract_model.freezed.dart';
part 'contract_model.g.dart';

enum ContractStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('terminated')
  terminated;

  String toJson() => name;
}

@freezed
class ContractModel with _$ContractModel {
  const factory ContractModel({
    required String id,
    required String jobId,
    required String bidId,
    required String clientId,
    required String providerId,
    @Default('active') String status,
    String? terminatedBy,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? workSubmittedAt,
    int? providerRating,
    int? clientRating,
    String? reviewText,
    @Default(false) bool isDeleted,
    double? providerLat,
    double? providerLng,
    DateTime? lastLocationUpdate,
    @Default(false) bool trackingEnabled,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ContractModel;

  factory ContractModel.fromJson(Map<String, dynamic> json) => _$ContractModelFromJson(json);
}
