import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String id,
    required String fullName,
    String? phone,
    String? avatarUrl,
    String? lastRole,
    double? averageRating,
    @Default(false) bool isDeleted,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    @Default(0) int immReqCnt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);
}
