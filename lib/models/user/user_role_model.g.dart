// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_role_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserRoleModelImpl _$$UserRoleModelImplFromJson(Map<String, dynamic> json) =>
    _$UserRoleModelImpl(
      userId: json['userId'] as String,
      roleId: (json['roleId'] as num).toInt(),
    );

Map<String, dynamic> _$$UserRoleModelImplToJson(_$UserRoleModelImpl instance) =>
    <String, dynamic>{'userId': instance.userId, 'roleId': instance.roleId};
