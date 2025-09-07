import 'package:flutter/material.dart';

class SafetyTipsBanner extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onComplete;
  final bool isLastTip;

  const SafetyTipsBanner({
    Key? key,
    this.onNext,
    this.onSkip,
    this.onComplete,
    this.isLastTip = false,
  }) : super(key: key);

  @override
  State<SafetyTipsBanner> createState() => _SafetyTipsBannerState();
}

class _SafetyTipsBannerState extends State<SafetyTipsBanner> {
  int _currentTipIndex = 0;

  final List<SafetyTip> _safetyTips = [
    SafetyTip(
      icon: "🚨",
      title: "Never Send Money",
      message: "Legitimate matches won't ask for money, gift cards, or financial help. If someone asks, it's likely a scam.",
      color: Color(0xFFE74C3C),
    ),
    SafetyTip(
      icon: "🛡️",
      title: "Stay on Platform",
      message: "Keep conversations on our platform initially. Be wary of matches who quickly want to move to other apps.",
      color: Color(0xFF3498DB),
    ),
    SafetyTip(
      icon: "✅",
      title: "Verify Your Match",
      message: "Consider having a video call before meeting in person to confirm your match is who they claim to be.",
      color: Color(0xFF27AE60),
    ),
    SafetyTip(
      icon: "🔒",
      title: "Protect Your Privacy",
      message: "Never share personal information like your address, workplace, or financial details with online matches.",
      color: Color(0xFFF39C12),
    ),
  ];

  void _nextTip() {
    if (_currentTipIndex < _safetyTips.length - 1) {
      setState(() {
        _currentTipIndex++;
      });
    } else {
      // Complete all tips
      widget.onComplete?.call();
    }
  }

  void _previousTip() {
    if (_currentTipIndex > 0) {
      setState(() {
        _currentTipIndex--;
      });
    }
  }

  void _skipTips() {
    widget.onSkip?.call();
  }

  void _completeTips() {
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final currentTip = _safetyTips[_currentTipIndex];
    final isFirstTip = _currentTipIndex == 0;
    final isLastTip = _currentTipIndex == _safetyTips.length - 1;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Minimum velocity threshold for swipe detection
        const minVelocity = 300.0;
        if (details.primaryVelocity! > minVelocity) {
          // Swipe right - go to previous
          _previousTip();
        } else if (details.primaryVelocity! < -minVelocity) {
          // Swipe left - go to next
          _nextTip();
        }
      },
      onVerticalDragEnd: (details) {
        // Minimum velocity threshold for swipe detection
        const minVelocity = 300.0;
        if (details.primaryVelocity! > minVelocity) {
          // Swipe down - dismiss
          _skipTips();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: currentTip.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: currentTip.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with progress indicator
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    currentTip.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Safety First",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentTip.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Skip button
                  TextButton(
                    onPressed: _skipTips,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress dots
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _safetyTips.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentTipIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tip message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                currentTip.message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Swipe hint
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe_left,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Swipe to navigate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (!isFirstTip)
                    Expanded(
                      child: TextButton(
                        onPressed: _previousTip,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Previous',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (!isFirstTip) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLastTip ? _completeTips : _nextTip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: currentTip.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: Text(
                        isLastTip ? 'Got it!' : 'Next',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SafetyTip {
  final String icon;
  final String title;
  final String message;
  final Color color;

  SafetyTip({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });
}
