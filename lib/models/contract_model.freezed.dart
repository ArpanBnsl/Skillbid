// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contract_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ContractModel _$ContractModelFromJson(Map<String, dynamic> json) {
  return _ContractModel.fromJson(json);
}

/// @nodoc
mixin _$ContractModel {
  String get id => throw _privateConstructorUsedError;
  String get jobId => throw _privateConstructorUsedError;
  String get bidId => throw _privateConstructorUsedError;
  String get clientId => throw _privateConstructorUsedError;
  String get providerId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get terminatedBy => throw _privateConstructorUsedError;
  DateTime? get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  DateTime? get workSubmittedAt => throw _privateConstructorUsedError;
  int? get providerRating => throw _privateConstructorUsedError;
  int? get clientRating => throw _privateConstructorUsedError;
  String? get reviewText => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;
  double? get providerLat => throw _privateConstructorUsedError;
  double? get providerLng => throw _privateConstructorUsedError;
  DateTime? get lastLocationUpdate => throw _privateConstructorUsedError;
  bool get trackingEnabled => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ContractModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContractModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContractModelCopyWith<ContractModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContractModelCopyWith<$Res> {
  factory $ContractModelCopyWith(
    ContractModel value,
    $Res Function(ContractModel) then,
  ) = _$ContractModelCopyWithImpl<$Res, ContractModel>;
  @useResult
  $Res call({
    String id,
    String jobId,
    String bidId,
    String clientId,
    String providerId,
    String status,
    String? terminatedBy,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? workSubmittedAt,
    int? providerRating,
    int? clientRating,
    String? reviewText,
    bool isDeleted,
    double? providerLat,
    double? providerLng,
    DateTime? lastLocationUpdate,
    bool trackingEnabled,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$ContractModelCopyWithImpl<$Res, $Val extends ContractModel>
    implements $ContractModelCopyWith<$Res> {
  _$ContractModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContractModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? jobId = null,
    Object? bidId = null,
    Object? clientId = null,
    Object? providerId = null,
    Object? status = null,
    Object? terminatedBy = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? workSubmittedAt = freezed,
    Object? providerRating = freezed,
    Object? clientRating = freezed,
    Object? reviewText = freezed,
    Object? isDeleted = null,
    Object? providerLat = freezed,
    Object? providerLng = freezed,
    Object? lastLocationUpdate = freezed,
    Object? trackingEnabled = null,
    Object? createdAt = null,
    Object? updatedAt = null,
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
            bidId: null == bidId
                ? _value.bidId
                : bidId // ignore: cast_nullable_to_non_nullable
                      as String,
            clientId: null == clientId
                ? _value.clientId
                : clientId // ignore: cast_nullable_to_non_nullable
                      as String,
            providerId: null == providerId
                ? _value.providerId
                : providerId // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            terminatedBy: freezed == terminatedBy
                ? _value.terminatedBy
                : terminatedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            startDate: freezed == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            workSubmittedAt: freezed == workSubmittedAt
                ? _value.workSubmittedAt
                : workSubmittedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            providerRating: freezed == providerRating
                ? _value.providerRating
                : providerRating // ignore: cast_nullable_to_non_nullable
                      as int?,
            clientRating: freezed == clientRating
                ? _value.clientRating
                : clientRating // ignore: cast_nullable_to_non_nullable
                      as int?,
            reviewText: freezed == reviewText
                ? _value.reviewText
                : reviewText // ignore: cast_nullable_to_non_nullable
                      as String?,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            providerLat: freezed == providerLat
                ? _value.providerLat
                : providerLat // ignore: cast_nullable_to_non_nullable
                      as double?,
            providerLng: freezed == providerLng
                ? _value.providerLng
                : providerLng // ignore: cast_nullable_to_non_nullable
                      as double?,
            lastLocationUpdate: freezed == lastLocationUpdate
                ? _value.lastLocationUpdate
                : lastLocationUpdate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            trackingEnabled: null == trackingEnabled
                ? _value.trackingEnabled
                : trackingEnabled // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ContractModelImplCopyWith<$Res>
    implements $ContractModelCopyWith<$Res> {
  factory _$$ContractModelImplCopyWith(
    _$ContractModelImpl value,
    $Res Function(_$ContractModelImpl) then,
  ) = __$$ContractModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String jobId,
    String bidId,
    String clientId,
    String providerId,
    String status,
    String? terminatedBy,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? workSubmittedAt,
    int? providerRating,
    int? clientRating,
    String? reviewText,
    bool isDeleted,
    double? providerLat,
    double? providerLng,
    DateTime? lastLocationUpdate,
    bool trackingEnabled,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$ContractModelImplCopyWithImpl<$Res>
    extends _$ContractModelCopyWithImpl<$Res, _$ContractModelImpl>
    implements _$$ContractModelImplCopyWith<$Res> {
  __$$ContractModelImplCopyWithImpl(
    _$ContractModelImpl _value,
    $Res Function(_$ContractModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContractModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? jobId = null,
    Object? bidId = null,
    Object? clientId = null,
    Object? providerId = null,
    Object? status = null,
    Object? terminatedBy = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? workSubmittedAt = freezed,
    Object? providerRating = freezed,
    Object? clientRating = freezed,
    Object? reviewText = freezed,
    Object? isDeleted = null,
    Object? providerLat = freezed,
    Object? providerLng = freezed,
    Object? lastLocationUpdate = freezed,
    Object? trackingEnabled = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ContractModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        jobId: null == jobId
            ? _value.jobId
            : jobId // ignore: cast_nullable_to_non_nullable
                  as String,
        bidId: null == bidId
            ? _value.bidId
            : bidId // ignore: cast_nullable_to_non_nullable
                  as String,
        clientId: null == clientId
            ? _value.clientId
            : clientId // ignore: cast_nullable_to_non_nullable
                  as String,
        providerId: null == providerId
            ? _value.providerId
            : providerId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        terminatedBy: freezed == terminatedBy
            ? _value.terminatedBy
            : terminatedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        startDate: freezed == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        workSubmittedAt: freezed == workSubmittedAt
            ? _value.workSubmittedAt
            : workSubmittedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        providerRating: freezed == providerRating
            ? _value.providerRating
            : providerRating // ignore: cast_nullable_to_non_nullable
                  as int?,
        clientRating: freezed == clientRating
            ? _value.clientRating
            : clientRating // ignore: cast_nullable_to_non_nullable
                  as int?,
        reviewText: freezed == reviewText
            ? _value.reviewText
            : reviewText // ignore: cast_nullable_to_non_nullable
                  as String?,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        providerLat: freezed == providerLat
            ? _value.providerLat
            : providerLat // ignore: cast_nullable_to_non_nullable
                  as double?,
        providerLng: freezed == providerLng
            ? _value.providerLng
            : providerLng // ignore: cast_nullable_to_non_nullable
                  as double?,
        lastLocationUpdate: freezed == lastLocationUpdate
            ? _value.lastLocationUpdate
            : lastLocationUpdate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        trackingEnabled: null == trackingEnabled
            ? _value.trackingEnabled
            : trackingEnabled // ignore: cast_nullable_to_non_nullable
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
class _$ContractModelImpl implements _ContractModel {
  const _$ContractModelImpl({
    required this.id,
    required this.jobId,
    required this.bidId,
    required this.clientId,
    required this.providerId,
    this.status = 'active',
    this.terminatedBy,
    this.startDate,
    this.endDate,
    this.workSubmittedAt,
    this.providerRating,
    this.clientRating,
    this.reviewText,
    this.isDeleted = false,
    this.providerLat,
    this.providerLng,
    this.lastLocationUpdate,
    this.trackingEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$ContractModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContractModelImplFromJson(json);

  @override
  final String id;
  @override
  final String jobId;
  @override
  final String bidId;
  @override
  final String clientId;
  @override
  final String providerId;
  @override
  @JsonKey()
  final String status;
  @override
  final String? terminatedBy;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  final DateTime? workSubmittedAt;
  @override
  final int? providerRating;
  @override
  final int? clientRating;
  @override
  final String? reviewText;
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  final double? providerLat;
  @override
  final double? providerLng;
  @override
  final DateTime? lastLocationUpdate;
  @override
  @JsonKey()
  final bool trackingEnabled;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ContractModel(id: $id, jobId: $jobId, bidId: $bidId, clientId: $clientId, providerId: $providerId, status: $status, terminatedBy: $terminatedBy, startDate: $startDate, endDate: $endDate, workSubmittedAt: $workSubmittedAt, providerRating: $providerRating, clientRating: $clientRating, reviewText: $reviewText, isDeleted: $isDeleted, providerLat: $providerLat, providerLng: $providerLng, lastLocationUpdate: $lastLocationUpdate, trackingEnabled: $trackingEnabled, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContractModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.jobId, jobId) || other.jobId == jobId) &&
            (identical(other.bidId, bidId) || other.bidId == bidId) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.providerId, providerId) ||
                other.providerId == providerId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.terminatedBy, terminatedBy) ||
                other.terminatedBy == terminatedBy) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.workSubmittedAt, workSubmittedAt) ||
                other.workSubmittedAt == workSubmittedAt) &&
            (identical(other.providerRating, providerRating) ||
                other.providerRating == providerRating) &&
            (identical(other.clientRating, clientRating) ||
                other.clientRating == clientRating) &&
            (identical(other.reviewText, reviewText) ||
                other.reviewText == reviewText) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.providerLat, providerLat) ||
                other.providerLat == providerLat) &&
            (identical(other.providerLng, providerLng) ||
                other.providerLng == providerLng) &&
            (identical(other.lastLocationUpdate, lastLocationUpdate) ||
                other.lastLocationUpdate == lastLocationUpdate) &&
            (identical(other.trackingEnabled, trackingEnabled) ||
                other.trackingEnabled == trackingEnabled) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    jobId,
    bidId,
    clientId,
    providerId,
    status,
    terminatedBy,
    startDate,
    endDate,
    workSubmittedAt,
    providerRating,
    clientRating,
    reviewText,
    isDeleted,
    providerLat,
    providerLng,
    lastLocationUpdate,
    trackingEnabled,
    createdAt,
    updatedAt,
  ]);

  /// Create a copy of ContractModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContractModelImplCopyWith<_$ContractModelImpl> get copyWith =>
      __$$ContractModelImplCopyWithImpl<_$ContractModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContractModelImplToJson(this);
  }
}

abstract class _ContractModel implements ContractModel {
  const factory _ContractModel({
    required final String id,
    required final String jobId,
    required final String bidId,
    required final String clientId,
    required final String providerId,
    final String status,
    final String? terminatedBy,
    final DateTime? startDate,
    final DateTime? endDate,
    final DateTime? workSubmittedAt,
    final int? providerRating,
    final int? clientRating,
    final String? reviewText,
    final bool isDeleted,
    final double? providerLat,
    final double? providerLng,
    final DateTime? lastLocationUpdate,
    final bool trackingEnabled,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$ContractModelImpl;

  factory _ContractModel.fromJson(Map<String, dynamic> json) =
      _$ContractModelImpl.fromJson;

  @override
  String get id;
  @override
  String get jobId;
  @override
  String get bidId;
  @override
  String get clientId;
  @override
  String get providerId;
  @override
  String get status;
  @override
  String? get terminatedBy;
  @override
  DateTime? get startDate;
  @override
  DateTime? get endDate;
  @override
  DateTime? get workSubmittedAt;
  @override
  int? get providerRating;
  @override
  int? get clientRating;
  @override
  String? get reviewText;
  @override
  bool get isDeleted;
  @override
  double? get providerLat;
  @override
  double? get providerLng;
  @override
  DateTime? get lastLocationUpdate;
  @override
  bool get trackingEnabled;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of ContractModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContractModelImplCopyWith<_$ContractModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
