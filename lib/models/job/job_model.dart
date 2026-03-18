import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_model.freezed.dart';
part 'job_model.g.dart';

enum JobStatus {
  @JsonValue('open')
  open,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled;

  String toJson() => name;
}

@freezed
class JobModel with _$JobModel {
  const factory JobModel({
    required String id,
    required String clientId,
    required String title,
    required String description,
    required double budget,
    required String location,
    required int skillId,
    int? desiredCompletionDays,
    @Default('open') String status,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _JobModel;

  factory JobModel.fromJson(Map<String, dynamic> json) => _$JobModelFromJson(json);
}
