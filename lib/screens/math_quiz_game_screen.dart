import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/navigation_helper.dart';

class MathQuizGameScreen extends StatefulWidget {
  final String difficulty; // 'beginner', 'intermediate', 'advanced', 'expert'

  const MathQuizGameScreen({
    Key? key,
    this.difficulty = 'intermediate',
  }) : super(key: key);

  @override
  State<MathQuizGameScreen> createState() => _MathQuizGameScreenState();
}

class _MathQuizGameScreenState extends State<MathQuizGameScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();
  late AnimationController _questionController;
  late AnimationController _scoreController;
  late Animation<double> _questionAnimation;
  late Animation<double> _scoreAnimation;

  int _currentQuestion = 0;
  int _score = 0;
  int _selectedAnswer = -1;
  bool _isAnswered = false;
  bool _showResult = false;
  List<Map<String, dynamic>> _questions = [];
  List<int> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _questionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _questionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOut),
    );
    _scoreAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.elasticOut),
    );
    _generateQuestions();
    _questionController.forward();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    _questions = [];
    for (int i = 0; i < 10; i++) {
      _questions.add(_generateQuestion(i));
    }
  }

  Map<String, dynamic> _generateQuestion(int index) {
    int num1, num2, answer;
    String question;
    List<int> options = [];

    switch (widget.difficulty) {
      case 'beginner':
        num1 = _random.nextInt(20) + 1;
        num2 = _random.nextInt(20) + 1;
        answer = num1 + num2;
        question = '$num1 + $num2 = ?';
        break;
      case 'intermediate':
        num1 = _random.nextInt(50) + 10;
        num2 = _random.nextInt(50) + 10;
        answer = num1 + num2;
        question = '$num1 + $num2 = ?';
        break;
      case 'advanced':
        num1 = _random.nextInt(100) + 50;
        num2 = _random.nextInt(100) + 50;
        final operation = _random.nextInt(2);
        if (operation == 0) {
          answer = num1 + num2;
          question = '$num1 + $num2 = ?';
        } else {
          answer = num1 * num2;
          question = '$num1 × $num2 = ?';
        }
        break;
      case 'expert':
        final operation = _random.nextInt(4);
        switch (operation) {
          case 0: // Addition
            num1 = _random.nextInt(200) + 100;
            num2 = _random.nextInt(200) + 100;
            answer = num1 + num2;
            question = '$num1 + $num2 = ?';
            break;
          case 1: // Multiplication
            num1 = _random.nextInt(20) + 10;
            num2 = _random.nextInt(20) + 10;
            answer = num1 * num2;
            question = '$num1 × $num2 = ?';
            break;
          case 2: // Square root approximation
            num1 = _random.nextInt(20) + 5;
            answer = num1 * num1;
            question = '√$answer = ?';
            break;
          default: // Complex
            num1 = _random.nextInt(50) + 20;
            num2 = _random.nextInt(50) + 20;
            final num3 = _random.nextInt(20) + 5;
            answer = (num1 + num2) * num3;
            question = '($num1 + $num2) × $num3 = ?';
            break;
        }
        break;
      default:
        num1 = _random.nextInt(50) + 10;
        num2 = _random.nextInt(50) + 10;
        answer = num1 + num2;
        question = '$num1 + $num2 = ?';
    }

    // Generate wrong options
    options.add(answer);
    while (options.length < 4) {
      int wrongAnswer;
      if (widget.difficulty == 'expert') {
        wrongAnswer = answer + _random.nextInt(50) - 25;
      } else {
        wrongAnswer = answer + _random.nextInt(20) - 10;
      }
      if (wrongAnswer != answer && wrongAnswer > 0 && !options.contains(wrongAnswer)) {
        options.add(wrongAnswer);
      }
    }
    options.shuffle();

    return {
      'question': question,
      'answer': answer,
      'options': options,
      'correctIndex': options.indexOf(answer),
    };
  }

  void _selectAnswer(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswer = index;
      _isAnswered = true;
      _userAnswers.add(index);

      if (index == _questions[_currentQuestion]['correctIndex']) {
        _score++;
        _scoreController.forward(from: 0);
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = -1;
        _isAnswered = false;
        _questionController.reset();
        _questionController.forward();
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    setState(() {
      _showResult = true;
    });
  }

  void _restart() {
    setState(() {
      _currentQuestion = 0;
      _score = 0;
      _selectedAnswer = -1;
      _isAnswered = false;
      _showResult = false;
      _userAnswers = [];
      _generateQuestions();
      _questionController.reset();
      _questionController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return _buildResultScreen();
    }

    final question = _questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _questions.length;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          NavigationHelper.goBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF6C5CE7),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => NavigationHelper.goBack(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Math Quiz',
                            style: AppTextStyles.heading1.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Question ${_currentQuestion + 1}/${_questions.length}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '$_score',
                            style: AppTextStyles.heading3.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Question
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: FadeTransition(
                    opacity: _questionAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Calculator icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calculate,
                            size: 48,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Question text
                        Text(
                          question['question'],
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        // Answer options
                        ...(question['options'] as List<int>).asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          final isSelected = _selectedAnswer == index;
                          final isCorrect = index == question['correctIndex'];
                          final showResult = _isAnswered;

                          Color backgroundColor = Colors.grey[100]!;
                          Color textColor = AppColors.textPrimary;
                          Color borderColor = Colors.transparent;

                          if (showResult) {
                            if (isCorrect) {
                              backgroundColor = AppColors.successGreen.withOpacity(0.2);
                              borderColor = AppColors.successGreen;
                              textColor = AppColors.successGreen;
                            } else if (isSelected && !isCorrect) {
                              backgroundColor = Colors.red.withOpacity(0.2);
                              borderColor = Colors.red;
                              textColor = Colors.red;
                            }
                          } else if (isSelected) {
                            backgroundColor = const Color(0xFF6C5CE7).withOpacity(0.1);
                            borderColor = const Color(0xFF6C5CE7);
                            textColor = const Color(0xFF6C5CE7);
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: () => _selectAnswer(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected || (showResult && isCorrect)
                                            ? borderColor
                                            : Colors.grey[300],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          String.fromCharCode(65 + index), // A, B, C, D
                                          style: TextStyle(
                                            color: isSelected || (showResult && isCorrect)
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        option.toString(),
                                        style: AppTextStyles.heading3.copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    if (showResult && isCorrect)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.successGreen,
                                        size: 24,
                                      )
                                    else if (showResult && isSelected && !isCorrect)
                                      const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_score / _questions.length * 100).round();
    String message = 'Great Job!';
    String emoji = '🎉';
    Color resultColor = AppColors.successGreen;

    if (percentage >= 90) {
      message = 'Outstanding!';
      emoji = '🏆';
    } else if (percentage >= 70) {
      message = 'Excellent!';
      emoji = '⭐';
    } else if (percentage >= 50) {
      message = 'Good Effort!';
      emoji = '👍';
    } else {
      message = 'Keep Practicing!';
      emoji = '💪';
      resultColor = Colors.orange;
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          NavigationHelper.goBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF6C5CE7),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Result emoji
                  ScaleTransition(
                    scale: _scoreAnimation,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Result message
                  Text(
                    message,
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You scored $_score out of ${_questions.length}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Score card
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Circular progress
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: percentage / 100,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(resultColor),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$percentage%',
                                    style: AppTextStyles.heading1.copyWith(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: resultColor,
                                    ),
                                  ),
                                  Text(
                                    'Score',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Correct',
                              '$_score',
                              AppColors.successGreen,
                              Icons.check_circle,
                            ),
                            _buildStatItem(
                              'Wrong',
                              '${_questions.length - _score}',
                              Colors.red,
                              Icons.cancel,
                            ),
                            _buildStatItem(
                              'Total',
                              '${_questions.length}',
                              const Color(0xFF6C5CE7),
                              Icons.quiz,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => NavigationHelper.goBack(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Exit',
                            style: AppTextStyles.buttonText.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _restart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6C5CE7),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Play Again',
                            style: AppTextStyles.buttonText.copyWith(
                              color: const Color(0xFF6C5CE7),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

