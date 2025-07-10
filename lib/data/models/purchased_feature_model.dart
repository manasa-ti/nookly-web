import 'package:nookly/domain/entities/purchased_feature.dart';

class PurchasedFeatureModel extends PurchasedFeature {
  const PurchasedFeatureModel({
    required super.id,
    required super.title,
    required super.description,
    required super.icon,
    required super.isActive,
  });

  factory PurchasedFeatureModel.fromJson(Map<String, dynamic> json) {
    return PurchasedFeatureModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'isActive': isActive,
    };
  }
} 