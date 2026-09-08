import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AnimatedEmptyTransactions extends StatefulWidget {
  final VoidCallback onAddTap;

  const AnimatedEmptyTransactions({
    super.key,
    required this.onAddTap,
  });

  @override
  State<AnimatedEmptyTransactions> createState() =>
      _AnimatedEmptyTransactionsState();
}

class _AnimatedEmptyTransactionsState extends State<AnimatedEmptyTransactions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.15)),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Floating Icon with Pulsing Outer Glow
              Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulsing Glow
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.08 * _pulseAnimation.value),
                        ),
                      ),
                    ),
                    // Inner Circle Container
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 34,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'No Transactions Yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'No transactions recorded for this period.\nLog your first income, expense, or savings!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.slate400,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Button
              ElevatedButton.icon(
                onPressed: widget.onAddTap,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text(
                  'LOG FIRST TRANSACTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
