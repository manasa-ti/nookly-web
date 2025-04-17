import 'package:hushmate/data/models/purchased_feature_model.dart';
import 'package:hushmate/domain/entities/purchased_feature.dart';
import 'package:hushmate/domain/repositories/purchased_features_repository.dart';

class PurchasedFeaturesRepositoryImpl implements PurchasedFeaturesRepository {
  @override
  Future<List<PurchasedFeature>> getPurchasedFeatures() async {
    // Mock data for now
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return [
      PurchasedFeatureModel(
        id: '1',
        title: 'See Who Likes You',
        description: 'Find out who has liked your profile before you match',
        icon: 'favorite',
        isActive: true,
      ),
      PurchasedFeatureModel(
        id: '2',
        title: 'Unlimited Likes',
        description: 'No daily limit on the number of profiles you can like',
        icon: 'all_inclusive',
        isActive: true,
      ),
      PurchasedFeatureModel(
        id: '3',
        title: 'Advanced Filters',
        description: 'Filter by education, height, and more',
        icon: 'filter_list',
        isActive: false,
      ),
      PurchasedFeatureModel(
        id: '4',
        title: 'Read Receipts',
        description: 'See when your messages are read',
        icon: 'done_all',
        isActive: false,
      ),
      PurchasedFeatureModel(
        id: '5',
        title: 'Priority Likes',
        description: 'Get seen by more people with priority placement',
        icon: 'star',
        isActive: false,
      ),
    ];
  }

  @override
  Future<void> purchaseFeature(String featureId) async {
    // Mock implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual API call
  }

  @override
  Future<void> cancelSubscription(String featureId) async {
    // Mock implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual API call
  }
} 