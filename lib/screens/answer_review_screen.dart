import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class AnswerReviewScreen extends StatelessWidget {
  const AnswerReviewScreen({Key? key}) : super(key: key);

  // Sample data - in real app, this would come from quiz results
  final List<Map<String, dynamic>> questions = const [
    {
      'number': 1,
      'question': 'What is the part of the animal cell that is labelled by A?',
      'options': ['Cell membrane', 'Chloroplast', 'Nucleus', 'Mitochondria'],
      'correctAnswer': 0,
      'userAnswer': 0,
      'isCorrect': true,
    },
    {
      'number': 2,
      'question': 'Which organelle is responsible for photosynthesis?',
      'options': ['Mitochondria', 'Chloroplast', 'Nucleus', 'Ribosome'],
      'correctAnswer': 1,
      'userAnswer': 2,
      'isCorrect': false,
    },
    {
      'number': 3,
      'question': 'What is the powerhouse of the cell?',
      'options': ['Nucleus', 'Chloroplast', 'Mitochondria', 'Cell wall'],
      'correctAnswer': 2,
      'userAnswer': null,
      'isCorrect': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionCard(questions[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
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
          const SizedBox(width: 12),
          Text(
            'Answer Review',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final isCorrect = question['isCorrect'] as bool;
    final isSkipped = question['userAnswer'] == null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSkipped
              ? Colors.grey[300]!
              : isCorrect
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE91E63),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${question['number']}',
                style: AppTextStyles.heading3.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSkipped
                      ? Colors.grey[200]
                      : isCorrect
                          ? const Color(0xFF4CAF50).withOpacity(0.1)
                          : const Color(0xFFE91E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSkipped
                          ? Icons.remove_circle_outline
                          : isCorrect
                              ? Icons.check_circle
                              : Icons.cancel,
                      size: 16,
                      color: isSkipped
                          ? Colors.grey[600]
                          : isCorrect
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE91E63),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSkipped
                          ? 'Skipped'
                          : isCorrect
                              ? 'Correct'
                              : 'Wrong',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSkipped
                            ? Colors.grey[600]
                            : isCorrect
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE91E63),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Question text
          Text(
            question['question'] as String,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Options
          ...List.generate(
            (question['options'] as List<String>).length,
            (index) => _buildOption(
              index,
              question['options'][index] as String,
              index == question['correctAnswer'],
              index == question['userAnswer'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int index, String text, bool isCorrect, bool isUserAnswer) {
    final letters = ['A', 'B', 'C', 'D'];
    
    Color backgroundColor = Colors.transparent;
    Color borderColor = Colors.grey[300]!;
    Color textColor = AppColors.textPrimary;
    
    if (isCorrect) {
      backgroundColor = const Color(0xFF4CAF50).withOpacity(0.1);
      borderColor = const Color(0xFF4CAF50);
      textColor = const Color(0xFF4CAF50);
    } else if (isUserAnswer && !isCorrect) {
      backgroundColor = const Color(0xFFE91E63).withOpacity(0.1);
      borderColor = const Color(0xFFE91E63);
      textColor = const Color(0xFFE91E63);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isCorrect || isUserAnswer ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon indicator
          if (isCorrect || isUserAnswer)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: isCorrect
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFE91E63),
              ),
            ),
          
          // Option text
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${letters[index]}. ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 15,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: textColor,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

