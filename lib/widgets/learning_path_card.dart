import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class LearningPathCard extends StatelessWidget {
  const LearningPathCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E2A3A),
                  const Color(0xFF2A3F5F),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F9FF),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFFE8EAED),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withOpacity(0.2),
                              AppColors.primary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'My Learning Path',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Text(
                      'Track your progress',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Growth Chart
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: GrowthChartPainter(isDark: isDark),
            ),
          ),
          const SizedBox(height: 20),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: '12 days',
                color: const Color(0xFFFF6B6B),
                isDark: isDark,
              ),
              Container(
                width: 1.5,
                height: 40,
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFFE8EAED),
              ),
              _buildStat(
                icon: Icons.military_tech_rounded,
                label: 'Progress',
                value: '68%',
                color: const Color(0xFF4ECDC4),
                isDark: isDark,
              ),
              Container(
                width: 1.5,
                height: 40,
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFFE8EAED),
              ),
              _buildStat(
                icon: Icons.workspace_premium_rounded,
                label: 'Level',
                value: 'Expert',
                color: const Color(0xFFFFD93D),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class GrowthChartPainter extends CustomPainter {
  final bool isDark;

  GrowthChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Sample data points (x, y) - normalized to 0-1
    final dataPoints = [
      const Offset(0.0, 0.7),
      const Offset(0.15, 0.65),
      const Offset(0.3, 0.5),
      const Offset(0.45, 0.45),
      const Offset(0.6, 0.3),
      const Offset(0.75, 0.25),
      const Offset(0.9, 0.15),
      const Offset(1.0, 0.1),
    ];

    // Convert normalized points to actual coordinates
    final points = dataPoints.map((point) {
      return Offset(
        point.dx * size.width,
        point.dy * size.height,
      );
    }).toList();

    // Draw grid lines
    final gridPaint = Paint()
      ..color = isDark 
          ? Colors.white.withOpacity(0.05)
          : const Color(0xFFE8EAED)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw gradient fill under the curve
    final path = Path();
    path.moveTo(points.first.dx, size.height);
    path.lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final controlPoint1 = Offset(
        prev.dx + (current.dx - prev.dx) / 3,
        prev.dy,
      );
      final controlPoint2 = Offset(
        prev.dx + 2 * (current.dx - prev.dx) / 3,
        current.dy,
      );
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        current.dx,
        current.dy,
      );
    }

    path.lineTo(points.last.dx, size.height);
    path.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF9D8FE8).withOpacity(0.4),
          const Color(0xFF9D8FE8).withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, gradientPaint);

    // Draw the curve line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final controlPoint1 = Offset(
        prev.dx + (current.dx - prev.dx) / 3,
        prev.dy,
      );
      final controlPoint2 = Offset(
        prev.dx + 2 * (current.dx - prev.dx) / 3,
        current.dy,
      );
      linePath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        current.dx,
        current.dy,
      );
    }

    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF9D8FE8),
          const Color(0xFFB8A9F5),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Draw point circles
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      // Outer glow
      final glowPaint = Paint()
        ..color = const Color(0xFF9D8FE8).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(point, 8, glowPaint);

      // Outer circle
      final outerCirclePaint = Paint()
        ..color = isDark ? const Color(0xFF2A3F5F) : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 6, outerCirclePaint);

      // Inner circle
      final innerCirclePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF9D8FE8),
            const Color(0xFFB8A9F5),
          ],
        ).createShader(Rect.fromCircle(center: point, radius: 4))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4, innerCirclePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

