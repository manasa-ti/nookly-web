import 'package:hushmate/domain/entities/purchased_feature.dart';

abstract class PurchasedFeaturesRepository {
  Future<List<PurchasedFeature>> getPurchasedFeatures();
  Future<void> purchaseFeature(String featureId);
  Future<void> cancelSubscription(String featureId);
} 