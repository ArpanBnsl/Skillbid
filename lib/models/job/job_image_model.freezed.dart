// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_image_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

JobImageModel _$JobImageModelFromJson(Map<String, dynamic> json) {
  return _JobImageModel.fromJson(json);
}

/// @nodoc
mixin _$JobImageModel {
  String get id => throw _privateConstructorUsedError;
  String get jobId => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this JobImageModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JobImageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JobImageModelCopyWith<JobImageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JobImageModelCopyWith<$Res> {
  factory $JobImageModelCopyWith(
    JobImageModel value,
    $Res Function(JobImageModel) then,
  ) = _$JobImageModelCopyWithImpl<$Res, JobImageModel>;
  @useResult
  $Res call({String id, String jobId, String imageUrl, DateTime createdAt});
}

/// @nodoc
class _$JobImageModelCopyWithImpl<$Res, $Val extends JobImageModel>
    implements $JobImageModelCopyWith<$Res> {
  _$JobImageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JobImageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? jobId = null,
    Object? imageUrl = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            jobId: null == jobId
                ? _value.jobId
                : jobId // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JobImageModelImplCopyWith<$Res>
    implements $JobImageModelCopyWith<$Res> {
  factory _$$JobImageModelImplCopyWith(
    _$JobImageModelImpl value,
    $Res Function(_$JobImageModelImpl) then,
  ) = __$$JobImageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String jobId, String imageUrl, DateTime createdAt});
}

/// @nodoc
class __$$JobImageModelImplCopyWithImpl<$Res>
    extends _$JobImageModelCopyWithImpl<$Res, _$JobImageModelImpl>
    implements _$$JobImageModelImplCopyWith<$Res> {
  __$$JobImageModelImplCopyWithImpl(
    _$JobImageModelImpl _value,
    $Res Function(_$JobImageModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JobImageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? jobId = null,
    Object? imageUrl = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$JobImageModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        jobId: null == jobId
            ? _value.jobId
            : jobId // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JobImageModelImpl implements _JobImageModel {
  const _$JobImageModelImpl({
    required this.id,
    required this.jobId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory _$JobImageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$JobImageModelImplFromJson(json);

  @override
  final String id;
  @override
  final String jobId;
  @override
  final String imageUrl;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'JobImageModel(id: $id, jobId: $jobId, imageUrl: $imageUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JobImageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.jobId, jobId) || other.jobId == jobId) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, jobId, imageUrl, createdAt);

  /// Create a copy of JobImageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JobImageModelImplCopyWith<_$JobImageModelImpl> get copyWith =>
      __$$JobImageModelImplCopyWithImpl<_$JobImageModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JobImageModelImplToJson(this);
  }
}

abstract class _JobImageModel implements JobImageModel {
  const factory _JobImageModel({
    required final String id,
    required final String jobId,
    required final String imageUrl,
    required final DateTime createdAt,
  }) = _$JobImageModelImpl;

  factory _JobImageModel.fromJson(Map<String, dynamic> json) =
      _$JobImageModelImpl.fromJson;

  @override
  String get id;
  @override
  String get jobId;
  @override
  String get imageUrl;
  @override
  DateTime get createdAt;

  /// Create a copy of JobImageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JobImageModelImplCopyWith<_$JobImageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
