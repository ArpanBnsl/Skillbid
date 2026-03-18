import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_image_model.freezed.dart';
part 'portfolio_image_model.g.dart';

@freezed
class PortfolioImageModel with _$PortfolioImageModel {
  const factory PortfolioImageModel({
    required String id,
    required String portfolioId,
    required String imageUrl,
    required DateTime createdAt,
  }) = _PortfolioImageModel;

  factory PortfolioImageModel.fromJson(Map<String, dynamic> json) => _$PortfolioImageModelFromJson(json);
}
