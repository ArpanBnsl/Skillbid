import 'package:freezed_annotation/freezed_annotation.dart';

part 'bid_model.freezed.dart';
part 'bid_model.g.dart';

enum BidStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('rejected')
  rejected,
  @JsonValue('cancelled')
  cancelled;

  String toJson() => name;
}

@freezed
class BidModel with _$BidModel {
  const factory BidModel({
    required String id,
    required String jobId,
    required String providerId,
    required double amount,
    int? estimatedDays,
    String? message,
    @Default('pending') String status,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BidModel;

  factory BidModel.fromJson(Map<String, dynamic> json) => _$BidModelFromJson(json);
}
