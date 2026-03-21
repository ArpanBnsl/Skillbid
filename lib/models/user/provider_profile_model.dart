import 'package:freezed_annotation/freezed_annotation.dart';

part 'provider_profile_model.freezed.dart';
part 'provider_profile_model.g.dart';

@freezed
class ProviderProfileModel with _$ProviderProfileModel {
  const factory ProviderProfileModel({
    required String userId,
    String? bio,
    @Default(0) int experienceYears,
    @Default(0) double hourlyRate,
    @Default(5.0) double relScore,
    @Default(0) int relStreak,
    @Default(false) bool isBanned,
    @Default(false) bool verified,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProviderProfileModel;

  factory ProviderProfileModel.fromJson(Map<String, dynamic> json) => _$ProviderProfileModelFromJson(json);
}
