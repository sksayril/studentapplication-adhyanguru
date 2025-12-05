import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/quiz_database.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({Key? key}) : super(key: key);

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  final QuizDatabase _quizDb = QuizDatabase.instance;
  List<Map<String, dynamic>> _quizResults = [];
  bool _isLoading = true;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadQuizHistory();
  }

  Future<void> _loadQuizHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _quizDb.getAllQuizResults();
      final stats = await _quizDb.getStatistics();

      if (mounted) {
        setState(() {
          _quizResults = results;
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quiz history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteQuizResult(int id) async {
    try {
      await _quizDb.deleteQuizResult(id);
      _loadQuizHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz result deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getColorFromString(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return AppColors.primary;
    }
    try {
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quiz History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_quizResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.textPrimary),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete All History'),
                    content: const Text('Are you sure you want to delete all quiz history?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await _quizDb.deleteAllQuizResults();
                    _loadQuizHistory();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All quiz history deleted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizResults.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadQuizHistory,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        if (_statistics != null) _buildStatisticsCard(),
                        const SizedBox(height: 16),
                        ..._quizResults.map((result) => _buildQuizResultCard(result)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 100,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Quiz History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.grey.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some quizzes to see your history here!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final stats = _statistics!;
    final winningPercentage = stats['winningPercentage'] as double? ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'My Winning Percentage',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${winningPercentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Quizzes', '${stats['totalQuizzes']}'),
              _buildStatItem('Total Correct', '${stats['totalCorrect']}/${stats['totalQuestions']}'),
              _buildStatItem('Average', '${(stats['averagePercentage'] as double).toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizResultCard(Map<String, dynamic> result) {
    final topicColor = _getColorFromString(result['topic_color'] as String?);
    final percentage = result['percentage'] as double? ?? 0.0;
    final correctAnswers = result['correct_answers'] as int? ?? 0;
    final totalQuestions = result['total_questions'] as int? ?? 0;
    final topicName = result['topic_name'] as String? ?? 'Unknown';
    final topicEmoji = result['topic_emoji'] as String? ?? '📚';
    final createdAt = result['created_at'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Topic emoji and number
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: topicColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                topicEmoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Topic name and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topicName,
                  style: TextStyle(
                    color: topicColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(topicColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$correctAnswers/$totalQuestions',
                style: TextStyle(
                  color: topicColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey.withOpacity(0.6)),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Quiz Result'),
                  content: const Text('Are you sure you want to delete this quiz result?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                _deleteQuizResult(result['id'] as int);
              }
            },
          ),
        ],
      ),
    );
  }
}

