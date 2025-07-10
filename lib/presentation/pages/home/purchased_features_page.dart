import 'package:flutter/material.dart';
import 'package:nookly/core/config/app_config.dart';

class PurchasedFeaturesPage extends StatelessWidget {
  const PurchasedFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium Features',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enhance your dating experience with our premium features',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureCard(
            context,
            title: 'See Who Likes You',
            description: 'Find out who has liked your profile before you match',
            icon: Icons.favorite,
            isActive: true,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Unlimited Likes',
            description: 'No daily limit on the number of profiles you can like',
            icon: Icons.all_inclusive,
            isActive: true,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Advanced Filters',
            description: 'Filter by education, height, and more',
            icon: Icons.filter_list,
            isActive: false,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Read Receipts',
            description: 'See when your messages are read',
            icon: Icons.done_all,
            isActive: false,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Priority Likes',
            description: 'Get seen by more people with priority placement',
            icon: Icons.star,
            isActive: false,
          ),
          const SizedBox(height: 32),
          const Text(
            'Subscription Plans',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSubscriptionCard(
            context,
            title: 'Monthly',
            price: '\$9.99',
            period: 'per month',
            features: [
              'See Who Likes You',
              'Unlimited Likes',
              'Advanced Filters',
              'Read Receipts',
              'Priority Likes',
            ],
            isPopular: false,
          ),
          const SizedBox(height: 16),
          _buildSubscriptionCard(
            context,
            title: '6 Months',
            price: '\$49.99',
            period: 'for 6 months',
            features: [
              'See Who Likes You',
              'Unlimited Likes',
              'Advanced Filters',
              'Read Receipts',
              'Priority Likes',
            ],
            isPopular: true,
            savings: 'Save 17%',
          ),
          const SizedBox(height: 16),
          _buildSubscriptionCard(
            context,
            title: 'Yearly',
            price: '\$89.99',
            period: 'per year',
            features: [
              'See Who Likes You',
              'Unlimited Likes',
              'Advanced Filters',
              'Read Receipts',
              'Priority Likes',
            ],
            isPopular: false,
            savings: 'Save 25%',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isActive,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isPopular,
    String? savings,
  }) {
    return Card(
      elevation: isPopular ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPopular
            ? BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Most Popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isPopular) const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (savings != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      savings,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    period,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(feature),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement subscription purchase
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Subscribing to $title plan'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: isPopular
                      ? Theme.of(context).primaryColor
                      : Colors.grey[800],
                ),
                child: Text(
                  isPopular ? 'Subscribe Now' : 'Choose Plan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 