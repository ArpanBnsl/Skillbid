// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_image_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PortfolioImageModelImpl _$$PortfolioImageModelImplFromJson(
  Map<String, dynamic> json,
) => _$PortfolioImageModelImpl(
  id: json['id'] as String,
  portfolioId: json['portfolioId'] as String,
  imageUrl: json['imageUrl'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$PortfolioImageModelImplToJson(
  _$PortfolioImageModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'portfolioId': instance.portfolioId,
  'imageUrl': instance.imageUrl,
  'createdAt': instance.createdAt.toIso8601String(),
};
