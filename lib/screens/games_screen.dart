import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import 'math_quiz_game_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildGameGrid(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Educational Games',
          style: AppTextStyles.heading1.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGameGrid() {
    final games = [
      {
        'title': 'Math Quiz',
        'description': 'Test your math skills',
        'players': '1.2K playing',
        'color': const Color(0xFF6C5CE7),
        'icon': Icons.calculate_outlined,
        'difficulty': 'intermediate',
      },
      {
        'title': 'Advanced Math',
        'description': 'Class 11+ level problems',
        'players': '1.5K playing',
        'color': const Color(0xFF00B894),
        'icon': Icons.functions,
        'difficulty': 'advanced',
      },
      {
        'title': 'Physics Challenge',
        'description': 'Advanced physics problems',
        'players': '850 playing',
        'color': const Color(0xFF9B59B6),
        'icon': Icons.science,
        'difficulty': 'expert',
      },
      {
        'title': 'Expert Math',
        'description': 'Masters level mathematics',
        'players': '650 playing',
        'color': const Color(0xFFE17055),
        'icon': Icons.calculate,
        'difficulty': 'expert',
      },
      {
        'title': 'Calculus Master',
        'description': 'Advanced calculus problems',
        'players': '540 playing',
        'color': const Color(0xFF0984E3),
        'icon': Icons.trending_up,
        'difficulty': 'expert',
      },
      {
        'title': 'Algebra Pro',
        'description': 'Complex algebraic equations',
        'players': '420 playing',
        'color': const Color(0xFF2D3436),
        'icon': Icons.functions_outlined,
        'difficulty': 'advanced',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameCard(
          context: context,
          title: game['title'] as String,
          description: game['description'] as String,
          players: game['players'] as String,
          color: game['color'] as Color,
          icon: game['icon'] as IconData,
          difficulty: game['difficulty'] as String?,
        );
      },
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required String description,
    required String players,
    required Color color,
    required IconData icon,
    String? difficulty,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MathQuizGameScreen(
              difficulty: difficulty ?? 'intermediate',
            ),
          ),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                // Title
                Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                // Description
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Players
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      players,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
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

