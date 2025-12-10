import 'package:flutter/material.dart';
import 'package:nookly/core/theme/app_colors.dart';
import 'package:nookly/core/theme/app_text_styles.dart';

class UniqueExperiencesPage extends StatelessWidget {
  const UniqueExperiencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Unique Experiences',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: AppTextStyles.getAppBarTitleFontSize(context),
            fontWeight: FontWeight.w600,
            color: AppColors.white85,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white85),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Title
                    Text(
                      'Discover What Makes nookly Truly Different',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: AppTextStyles.getTitleFontSize(context),
                        fontWeight: FontWeight.w600,
                        color: AppColors.white85,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'nookly is designed for adults who value comfort, privacy, and meaningful conversations.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: AppTextStyles.getBodyFontSize(context),
                        color: AppColors.white85,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s what sets us apart:',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: AppTextStyles.getBodyFontSize(context),
                        color: AppColors.white85,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Privacy-First Connections
                    _buildFeatureSection(
                      context,
                      icon: '🛡',
                      title: 'Privacy-First Connections',
                      description: 'No photos, no public profiles, no pressure to reveal your identity.\n\nYour comfort decides the pace.',
                    ),
                    const SizedBox(height: 24),
                    
                    // Conversation-Enhancing Mini-Experiences
                    _buildFeatureSection(
                      context,
                      icon: '🎮',
                      title: 'Conversation-Enhancing Mini-Experiences',
                      description: 'Interactive activities that help you understand someone beyond words:\n\n• Truth or Thrill\n• Would You Rather\n• Memory Sparks\n• Guess Me\n\nThese aren\'t games for winning — they\'re tools for opening up and connecting comfortably.',
                    ),
                    const SizedBox(height: 24),
                    
                    // AI-Assisted Conversation Flow
                    _buildFeatureSection(
                      context,
                      icon: '💬',
                      title: 'AI-Assisted Conversation Flow',
                      description: 'Thoughtful, context-aware conversation prompts that help you start or deepen meaningful interactions without awkwardness.',
                    ),
                    const SizedBox(height: 24),
                    
                    // Rich Personal Journeys
                    _buildFeatureSection(
                      context,
                      icon: '📘',
                      title: 'Rich Personal Journeys',
                      description: 'Every conversation space includes shared prompts, personal reflections, availability preferences, and comfort settings — making each interaction unique and expressive.',
                    ),
                    const SizedBox(height: 24),
                    
                    // Completely Anonymous, Judgment-Free Environment
                    _buildFeatureSection(
                      context,
                      icon: '🎧',
                      title: 'Completely Anonymous, Judgment-Free Environment',
                      description: 'Whether you\'re seeking companionship, conversation, or simply a calm place to unwind, nookly provides a safe corner just for you.',
                    ),
                    const SizedBox(height: 24),
                    
                    // Optional Intimacy Layer
                    _buildFeatureSection(
                      context,
                      icon: '🔥',
                      title: 'Deeper Exploration (Coming Soon)',
                      description: 'A consent-based mode that allows both participants to explore more personal conversations at their own pace.',
                    ),
                    const SizedBox(height: 32),
                    
                    // Closing statement
                    Text(
                      '**nookly focuses on emotional comfort.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: AppTextStyles.getBodyFontSize(context),
                        fontWeight: FontWeight.w600,
                        color: AppColors.white85,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'It\'s connection without labels, pressure, or expectations.**',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: AppTextStyles.getBodyFontSize(context),
                        fontWeight: FontWeight.w600,
                        color: AppColors.white85,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Got it button
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: AppTextStyles.getBodyFontSize(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection(
    BuildContext context, {
    required String icon,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: AppTextStyles.getTitleFontSize(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: AppTextStyles.getSubtitleFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.white85,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(
            description,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: AppTextStyles.getBodyFontSize(context),
              color: AppColors.white85,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

