import 'package:flutter/material.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';

// Custom compact chip for profile card
class ProfileInterestChip extends StatelessWidget {
  final String label;
  const ProfileInterestChip({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF35548b),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFF8FA3C8), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD6D9E6),
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class ProfileCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final VoidCallback onTap;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onTap,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _onHeartPressed() {
    widget.onSwipeRight();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // TEMPORARILY DISABLED: Swipe functionality commented out for future use
  // void _onDragStart(DragStartDetails details) {
  //   setState(() {
  //     _isDragging = true;
  //   });
  // }

  // void _onDragUpdate(DragUpdateDetails details) {
  //   setState(() {
  //     _dragOffset += details.delta.dx;
  //   });
  // }

  // void _onDragEnd(DragEndDetails details) {
  //   setState(() {
  //     _isDragging = false;
  //   });

  //   if (_dragOffset.abs() > MediaQuery.of(context).size.width * 0.3) {
  //     if (_dragOffset > 0) {
  //       widget.onSwipeRight();
  //     } else {
  //       widget.onSwipeLeft();
  //     }
  //   } else {
  //     _controller.forward(from: 0);
  //   }
  //   _dragOffset = 0;
  // }

  Widget _buildAvatar() {
    final name = widget.profile['name'] as String?;
    // Always use custom avatar, never load DiceBear or network images
    return _customAvatar(name);
  }

  Widget _customAvatar(String? name) {
    return CustomAvatar(
      name: name,
      size: 44,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      // TEMPORARILY DISABLED: Swipe gesture handlers commented out for future use
      // onHorizontalDragStart: _onDragStart,
      // onHorizontalDragUpdate: _onDragUpdate,
      // onHorizontalDragEnd: _onDragEnd,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            // TEMPORARILY DISABLED: Swipe offset commented out for future use
            // offset: Offset(_dragOffset, 0),
            offset: Offset.zero, // No movement since swipe is disabled
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A4A7A),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A1F3C).withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Info Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Circular Profile Image
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.pink[100],
                            ),
                            child: _buildAvatar(),
                          ),
                          const SizedBox(width: 12),
                          // Name, Age and Location
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.profile['name']}, ${widget.profile['age']}',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: (size.width * 0.045).clamp(13.0, 17.0),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14.0,
                                      color: Color(0xFFD6D9E6),
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        '${(widget.profile['distance'] ?? 0.0).toStringAsFixed(1)} km away',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          color: Color(0xFFD6D9E6),
                                          fontSize: (size.width * 0.032).clamp(11.0, 15.0),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Connect button at the end of the row with size constraint
                          // Wrap in a container that provides space for tooltip
                          Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: AnimatedConnectButton(
                              key: ValueKey('connect_${widget.profile['id']}'),
                              onTap: _onHeartPressed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Bio (remove Expanded)
                      Text(
                        widget.profile['bio'],
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: (size.width * 0.035).clamp(12.0, 16.0),
                          height: 1.5,
                          color: Colors.white,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Interests (use custom compact ProfileInterestChip for display)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          height: 28,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            children: (widget.profile['interests'] as List<String>? ?? [])
                                .take(5)
                                .map((interest) => ProfileInterestChip(label: interest))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AnimatedConnectButton extends StatefulWidget {
  final VoidCallback onTap;
  const AnimatedConnectButton({super.key, required this.onTap});

  @override
  State<AnimatedConnectButton> createState() => _AnimatedConnectButtonState();
}

class _AnimatedConnectButtonState extends State<AnimatedConnectButton> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late AnimationController _outlineController;
  late Animation<double> _scaleAnim;
  late Animation<Color?> _colorAnim;
  late Animation<double> _outlineAnim;
  bool _isFilled = false;
  List<Widget> _floatingHearts = [];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _outlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _colorAnim = ColorTween(
      begin: Colors.transparent,
      end: const Color(0xFFFF4B6A),
    ).animate(CurvedAnimation(parent: _colorController, curve: Curves.easeInOut));
    _outlineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _outlineController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    _outlineController.dispose();
    // Reset state when widget is disposed
    _isFilled = false;
    _floatingHearts = [];
    super.dispose();
  }

  void _onPressed() async {
    if (_isFilled) return;
    setState(() => _isFilled = true);
    
    // Start animations
    _scaleController.forward();
    _colorController.forward();
    _outlineController.forward();
    _emitFloatingHearts();
    
    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 400));
    _scaleController.reverse();
    _outlineController.reverse();
    
    // Call the callback
    widget.onTap();
  }

  void _emitFloatingHearts() {
    final hearts = List.generate(3, (i) => _FloatingHeart(key: UniqueKey(), offset: i - 1));
    setState(() {
      _floatingHearts = hearts;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() => _floatingHearts = []);
    });
  }

  void resetState() {
    if (mounted) {
      setState(() {
        _isFilled = false;
        _floatingHearts = [];
      });
      _scaleController.reset();
      _colorController.reset();
      _outlineController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ..._floatingHearts,
        ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedBuilder(
            animation: Listenable.merge([_colorAnim, _outlineAnim]),
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF4B6A).withOpacity(_outlineAnim.value),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4B6A).withOpacity(_outlineAnim.value * 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _onPressed,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(4),
                    backgroundColor: _colorAnim.value ?? Colors.transparent,
                    elevation: 4,
                    shadowColor: Colors.black26,
                  ),
                  child: Center(
                    child: Icon(
                      _isFilled ? Icons.favorite : Icons.favorite_border,
                      color: _isFilled ? const Color.fromARGB(255, 149, 3, 3) : const Color(0xFFFF4B6A),
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FloatingHeart extends StatefulWidget {
  final int offset;
  const _FloatingHeart({super.key, required this.offset});

  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveUp;
  late Animation<double> _fadeOut;
  late Animation<double> _scale;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _moveUp = Tween<double>(begin: 0, end: -60).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.5, end: 1.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _rotate = Tween<double>(begin: 0, end: 360).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          bottom: 0,
          left: widget.offset * 15.0,
          child: Opacity(
            opacity: _fadeOut.value,
            child: Transform.translate(
              offset: Offset(0, _moveUp.value),
              child: Transform.scale(
                scale: _scale.value,
                child: Transform.rotate(
                  angle: _rotate.value * 3.14159 / 180,
                  child: Icon(Icons.favorite, color: const Color(0xFFFF4B6A), size: 16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 