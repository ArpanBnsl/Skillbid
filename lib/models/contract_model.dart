import 'package:freezed_annotation/freezed_annotation.dart';

part 'contract_model.freezed.dart';
part 'contract_model.g.dart';

enum ContractStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled;

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
    DateTime? startDate,
    DateTime? endDate,
    int? rating, // 1-5
    String? reviewText,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ContractModel;

  factory ContractModel.fromJson(Map<String, dynamic> json) => _$ContractModelFromJson(json);
}
