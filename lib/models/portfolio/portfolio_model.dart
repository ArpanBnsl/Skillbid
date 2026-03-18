import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_model.freezed.dart';
part 'portfolio_model.g.dart';

@freezed
class PortfolioModel with _$PortfolioModel {
  const factory PortfolioModel({
    required String id,
    required String providerId,
    required String title,
    String? description,
    double? cost,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PortfolioModel;

  factory PortfolioModel.fromJson(Map<String, dynamic> json) => _$PortfolioModelFromJson(json);
}
