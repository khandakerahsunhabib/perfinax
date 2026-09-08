import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AnimatedEmptyPieChart extends StatefulWidget {
  const AnimatedEmptyPieChart({super.key});

  @override
  State<AnimatedEmptyPieChart> createState() => _AnimatedEmptyPieChartState();
}

class _AnimatedEmptyPieChartState extends State<AnimatedEmptyPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
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
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Pie Chart Icon Placeholder
              Transform.rotate(
                angle: _rotationAnimation.value,
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing Glow Ring
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.08 * _pulseAnimation.value),
                        ),
                      ),
                      // Inner Icon Badge
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border.all(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.15),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.pie_chart_outline_rounded,
                          size: 32,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              const Text(
                'No Expense Data Available',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle Description
              const Text(
                'Log expenses for this month to view category breakdown.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.slate400,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
