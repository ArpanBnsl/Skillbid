// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

JobModel _$JobModelFromJson(Map<String, dynamic> json) {
  return _JobModel.fromJson(json);
}

/// @nodoc
mixin _$JobModel {
  String get id => throw _privateConstructorUsedError;
  String get clientId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get budget => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  int get skillId => throw _privateConstructorUsedError;
  int? get desiredCompletionDays => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;
  bool get isImmediate => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  double? get jobLat => throw _privateConstructorUsedError;
  double? get jobLng => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this JobModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JobModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JobModelCopyWith<JobModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JobModelCopyWith<$Res> {
  factory $JobModelCopyWith(JobModel value, $Res Function(JobModel) then) =
      _$JobModelCopyWithImpl<$Res, JobModel>;
  @useResult
  $Res call({
    String id,
    String clientId,
    String title,
    String description,
    double budget,
    String location,
    int skillId,
    int? desiredCompletionDays,
    String status,
    bool isDeleted,
    bool isImmediate,
    DateTime? expiresAt,
    double? jobLat,
    double? jobLng,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$JobModelCopyWithImpl<$Res, $Val extends JobModel>
    implements $JobModelCopyWith<$Res> {
  _$JobModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JobModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? title = null,
    Object? description = null,
    Object? budget = null,
    Object? location = null,
    Object? skillId = null,
    Object? desiredCompletionDays = freezed,
    Object? status = null,
    Object? isDeleted = null,
    Object? isImmediate = null,
    Object? expiresAt = freezed,
    Object? jobLat = freezed,
    Object? jobLng = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            clientId: null == clientId
                ? _value.clientId
                : clientId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            budget: null == budget
                ? _value.budget
                : budget // ignore: cast_nullable_to_non_nullable
                      as double,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String,
            skillId: null == skillId
                ? _value.skillId
                : skillId // ignore: cast_nullable_to_non_nullable
                      as int,
            desiredCompletionDays: freezed == desiredCompletionDays
                ? _value.desiredCompletionDays
                : desiredCompletionDays // ignore: cast_nullable_to_non_nullable
                      as int?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            isImmediate: null == isImmediate
                ? _value.isImmediate
                : isImmediate // ignore: cast_nullable_to_non_nullable
                      as bool,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            jobLat: freezed == jobLat
                ? _value.jobLat
                : jobLat // ignore: cast_nullable_to_non_nullable
                      as double?,
            jobLng: freezed == jobLng
                ? _value.jobLng
                : jobLng // ignore: cast_nullable_to_non_nullable
                      as double?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JobModelImplCopyWith<$Res>
    implements $JobModelCopyWith<$Res> {
  factory _$$JobModelImplCopyWith(
    _$JobModelImpl value,
    $Res Function(_$JobModelImpl) then,
  ) = __$$JobModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String clientId,
    String title,
    String description,
    double budget,
    String location,
    int skillId,
    int? desiredCompletionDays,
    String status,
    bool isDeleted,
    bool isImmediate,
    DateTime? expiresAt,
    double? jobLat,
    double? jobLng,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$JobModelImplCopyWithImpl<$Res>
    extends _$JobModelCopyWithImpl<$Res, _$JobModelImpl>
    implements _$$JobModelImplCopyWith<$Res> {
  __$$JobModelImplCopyWithImpl(
    _$JobModelImpl _value,
    $Res Function(_$JobModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JobModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? title = null,
    Object? description = null,
    Object? budget = null,
    Object? location = null,
    Object? skillId = null,
    Object? desiredCompletionDays = freezed,
    Object? status = null,
    Object? isDeleted = null,
    Object? isImmediate = null,
    Object? expiresAt = freezed,
    Object? jobLat = freezed,
    Object? jobLng = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$JobModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        clientId: null == clientId
            ? _value.clientId
            : clientId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        budget: null == budget
            ? _value.budget
            : budget // ignore: cast_nullable_to_non_nullable
                  as double,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String,
        skillId: null == skillId
            ? _value.skillId
            : skillId // ignore: cast_nullable_to_non_nullable
                  as int,
        desiredCompletionDays: freezed == desiredCompletionDays
            ? _value.desiredCompletionDays
            : desiredCompletionDays // ignore: cast_nullable_to_non_nullable
                  as int?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        isImmediate: null == isImmediate
            ? _value.isImmediate
            : isImmediate // ignore: cast_nullable_to_non_nullable
                  as bool,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        jobLat: freezed == jobLat
            ? _value.jobLat
            : jobLat // ignore: cast_nullable_to_non_nullable
                  as double?,
        jobLng: freezed == jobLng
            ? _value.jobLng
            : jobLng // ignore: cast_nullable_to_non_nullable
                  as double?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JobModelImpl implements _JobModel {
  const _$JobModelImpl({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.budget,
    required this.location,
    required this.skillId,
    this.desiredCompletionDays,
    this.status = 'open',
    this.isDeleted = false,
    this.isImmediate = false,
    this.expiresAt,
    this.jobLat,
    this.jobLng,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$JobModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$JobModelImplFromJson(json);

  @override
  final String id;
  @override
  final String clientId;
  @override
  final String title;
  @override
  final String description;
  @override
  final double budget;
  @override
  final String location;
  @override
  final int skillId;
  @override
  final int? desiredCompletionDays;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  @JsonKey()
  final bool isImmediate;
  @override
  final DateTime? expiresAt;
  @override
  final double? jobLat;
  @override
  final double? jobLng;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'JobModel(id: $id, clientId: $clientId, title: $title, description: $description, budget: $budget, location: $location, skillId: $skillId, desiredCompletionDays: $desiredCompletionDays, status: $status, isDeleted: $isDeleted, isImmediate: $isImmediate, expiresAt: $expiresAt, jobLat: $jobLat, jobLng: $jobLng, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JobModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.budget, budget) || other.budget == budget) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.skillId, skillId) || other.skillId == skillId) &&
            (identical(other.desiredCompletionDays, desiredCompletionDays) ||
                other.desiredCompletionDays == desiredCompletionDays) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.isImmediate, isImmediate) ||
                other.isImmediate == isImmediate) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.jobLat, jobLat) || other.jobLat == jobLat) &&
            (identical(other.jobLng, jobLng) || other.jobLng == jobLng) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    clientId,
    title,
    description,
    budget,
    location,
    skillId,
    desiredCompletionDays,
    status,
    isDeleted,
    isImmediate,
    expiresAt,
    jobLat,
    jobLng,
    createdAt,
    updatedAt,
  );

  /// Create a copy of JobModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JobModelImplCopyWith<_$JobModelImpl> get copyWith =>
      __$$JobModelImplCopyWithImpl<_$JobModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JobModelImplToJson(this);
  }
}

abstract class _JobModel implements JobModel {
  const factory _JobModel({
    required final String id,
    required final String clientId,
    required final String title,
    required final String description,
    required final double budget,
    required final String location,
    required final int skillId,
    final int? desiredCompletionDays,
    final String status,
    final bool isDeleted,
    final bool isImmediate,
    final DateTime? expiresAt,
    final double? jobLat,
    final double? jobLng,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$JobModelImpl;

  factory _JobModel.fromJson(Map<String, dynamic> json) =
      _$JobModelImpl.fromJson;

  @override
  String get id;
  @override
  String get clientId;
  @override
  String get title;
  @override
  String get description;
  @override
  double get budget;
  @override
  String get location;
  @override
  int get skillId;
  @override
  int? get desiredCompletionDays;
  @override
  String get status;
  @override
  bool get isDeleted;
  @override
  bool get isImmediate;
  @override
  DateTime? get expiresAt;
  @override
  double? get jobLat;
  @override
  double? get jobLng;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of JobModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JobModelImplCopyWith<_$JobModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
