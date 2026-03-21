// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'provider_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ProviderProfileModel _$ProviderProfileModelFromJson(Map<String, dynamic> json) {
  return _ProviderProfileModel.fromJson(json);
}

/// @nodoc
mixin _$ProviderProfileModel {
  String get userId => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  int get experienceYears => throw _privateConstructorUsedError;
  double get hourlyRate => throw _privateConstructorUsedError;
  double get relScore => throw _privateConstructorUsedError;
  int get relStreak => throw _privateConstructorUsedError;
  bool get isBanned => throw _privateConstructorUsedError;
  bool get verified => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ProviderProfileModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProviderProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProviderProfileModelCopyWith<ProviderProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProviderProfileModelCopyWith<$Res> {
  factory $ProviderProfileModelCopyWith(
    ProviderProfileModel value,
    $Res Function(ProviderProfileModel) then,
  ) = _$ProviderProfileModelCopyWithImpl<$Res, ProviderProfileModel>;
  @useResult
  $Res call({
    String userId,
    String? bio,
    int experienceYears,
    double hourlyRate,
    double relScore,
    int relStreak,
    bool isBanned,
    bool verified,
    bool isDeleted,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$ProviderProfileModelCopyWithImpl<
  $Res,
  $Val extends ProviderProfileModel
>
    implements $ProviderProfileModelCopyWith<$Res> {
  _$ProviderProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProviderProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? bio = freezed,
    Object? experienceYears = null,
    Object? hourlyRate = null,
    Object? relScore = null,
    Object? relStreak = null,
    Object? isBanned = null,
    Object? verified = null,
    Object? isDeleted = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            bio: freezed == bio
                ? _value.bio
                : bio // ignore: cast_nullable_to_non_nullable
                      as String?,
            experienceYears: null == experienceYears
                ? _value.experienceYears
                : experienceYears // ignore: cast_nullable_to_non_nullable
                      as int,
            hourlyRate: null == hourlyRate
                ? _value.hourlyRate
                : hourlyRate // ignore: cast_nullable_to_non_nullable
                      as double,
            relScore: null == relScore
                ? _value.relScore
                : relScore // ignore: cast_nullable_to_non_nullable
                      as double,
            relStreak: null == relStreak
                ? _value.relStreak
                : relStreak // ignore: cast_nullable_to_non_nullable
                      as int,
            isBanned: null == isBanned
                ? _value.isBanned
                : isBanned // ignore: cast_nullable_to_non_nullable
                      as bool,
            verified: null == verified
                ? _value.verified
                : verified // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$ProviderProfileModelImplCopyWith<$Res>
    implements $ProviderProfileModelCopyWith<$Res> {
  factory _$$ProviderProfileModelImplCopyWith(
    _$ProviderProfileModelImpl value,
    $Res Function(_$ProviderProfileModelImpl) then,
  ) = __$$ProviderProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String? bio,
    int experienceYears,
    double hourlyRate,
    double relScore,
    int relStreak,
    bool isBanned,
    bool verified,
    bool isDeleted,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$ProviderProfileModelImplCopyWithImpl<$Res>
    extends _$ProviderProfileModelCopyWithImpl<$Res, _$ProviderProfileModelImpl>
    implements _$$ProviderProfileModelImplCopyWith<$Res> {
  __$$ProviderProfileModelImplCopyWithImpl(
    _$ProviderProfileModelImpl _value,
    $Res Function(_$ProviderProfileModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProviderProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? bio = freezed,
    Object? experienceYears = null,
    Object? hourlyRate = null,
    Object? relScore = null,
    Object? relStreak = null,
    Object? isBanned = null,
    Object? verified = null,
    Object? isDeleted = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ProviderProfileModelImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        bio: freezed == bio
            ? _value.bio
            : bio // ignore: cast_nullable_to_non_nullable
                  as String?,
        experienceYears: null == experienceYears
            ? _value.experienceYears
            : experienceYears // ignore: cast_nullable_to_non_nullable
                  as int,
        hourlyRate: null == hourlyRate
            ? _value.hourlyRate
            : hourlyRate // ignore: cast_nullable_to_non_nullable
                  as double,
        relScore: null == relScore
            ? _value.relScore
            : relScore // ignore: cast_nullable_to_non_nullable
                  as double,
        relStreak: null == relStreak
            ? _value.relStreak
            : relStreak // ignore: cast_nullable_to_non_nullable
                  as int,
        isBanned: null == isBanned
            ? _value.isBanned
            : isBanned // ignore: cast_nullable_to_non_nullable
                  as bool,
        verified: null == verified
            ? _value.verified
            : verified // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$ProviderProfileModelImpl implements _ProviderProfileModel {
  const _$ProviderProfileModelImpl({
    required this.userId,
    this.bio,
    this.experienceYears = 0,
    this.hourlyRate = 0,
    this.relScore = 5.0,
    this.relStreak = 0,
    this.isBanned = false,
    this.verified = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$ProviderProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProviderProfileModelImplFromJson(json);

  @override
  final String userId;
  @override
  final String? bio;
  @override
  @JsonKey()
  final int experienceYears;
  @override
  @JsonKey()
  final double hourlyRate;
  @override
  @JsonKey()
  final double relScore;
  @override
  @JsonKey()
  final int relStreak;
  @override
  @JsonKey()
  final bool isBanned;
  @override
  @JsonKey()
  final bool verified;
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ProviderProfileModel(userId: $userId, bio: $bio, experienceYears: $experienceYears, hourlyRate: $hourlyRate, relScore: $relScore, relStreak: $relStreak, isBanned: $isBanned, verified: $verified, isDeleted: $isDeleted, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProviderProfileModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.experienceYears, experienceYears) ||
                other.experienceYears == experienceYears) &&
            (identical(other.hourlyRate, hourlyRate) ||
                other.hourlyRate == hourlyRate) &&
            (identical(other.relScore, relScore) ||
                other.relScore == relScore) &&
            (identical(other.relStreak, relStreak) ||
                other.relStreak == relStreak) &&
            (identical(other.isBanned, isBanned) ||
                other.isBanned == isBanned) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    bio,
    experienceYears,
    hourlyRate,
    relScore,
    relStreak,
    isBanned,
    verified,
    isDeleted,
    createdAt,
    updatedAt,
  );

  /// Create a copy of ProviderProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProviderProfileModelImplCopyWith<_$ProviderProfileModelImpl>
  get copyWith =>
      __$$ProviderProfileModelImplCopyWithImpl<_$ProviderProfileModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ProviderProfileModelImplToJson(this);
  }
}

abstract class _ProviderProfileModel implements ProviderProfileModel {
  const factory _ProviderProfileModel({
    required final String userId,
    final String? bio,
    final int experienceYears,
    final double hourlyRate,
    final double relScore,
    final int relStreak,
    final bool isBanned,
    final bool verified,
    final bool isDeleted,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$ProviderProfileModelImpl;

  factory _ProviderProfileModel.fromJson(Map<String, dynamic> json) =
      _$ProviderProfileModelImpl.fromJson;

  @override
  String get userId;
  @override
  String? get bio;
  @override
  int get experienceYears;
  @override
  double get hourlyRate;
  @override
  double get relScore;
  @override
  int get relStreak;
  @override
  bool get isBanned;
  @override
  bool get verified;
  @override
  bool get isDeleted;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of ProviderProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProviderProfileModelImplCopyWith<_$ProviderProfileModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
