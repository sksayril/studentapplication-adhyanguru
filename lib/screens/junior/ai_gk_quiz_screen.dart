import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/api_service.dart';
import '../../services/quiz_database.dart';

class AIGKQuizScreen extends StatefulWidget {
  const AIGKQuizScreen({Key? key}) : super(key: key);

  @override
  State<AIGKQuizScreen> createState() => _AIGKQuizScreenState();
}

class QuizQuestion {
  final int number;
  final String question;
  final List<String> options;
  final String correctAnswer; // A, B, C, or D
  final String? emoji;

  QuizQuestion({
    required this.number,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.emoji,
  });
}

class _AIGKQuizScreenState extends State<AIGKQuizScreen> {
  String? _selectedTopic;
  bool _isGenerating = false;
  String? _quizContent;
  String? _errorMessage;
  List<QuizQuestion> _questions = [];
  Map<int, String> _userAnswers = {}; // question number -> selected option (A, B, C, D)
  int _currentQuestionIndex = 0;
  bool _showResults = false;
  bool _resultSaved = false;
  final QuizDatabase _quizDb = QuizDatabase.instance;

  final List<Map<String, dynamic>> _topics = [
    {
      'id': 'history',
      'name': 'History',
      'emoji': '🏛️',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 'geography',
      'name': 'Geography',
      'emoji': '🌍',
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': 'science',
      'name': 'Science',
      'emoji': '🔬',
      'color': const Color(0xFF10B981),
    },
    {
      'id': 'sports',
      'name': 'Sports',
      'emoji': '⚽',
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 'animals',
      'name': 'Animals',
      'emoji': '🦁',
      'color': const Color(0xFFEC4899),
    },
    {
      'id': 'space',
      'name': 'Space',
      'emoji': '🚀',
      'color': const Color(0xFF6366F1),
    },
    {
      'id': 'countries',
      'name': 'Countries',
      'emoji': '🗺️',
      'color': const Color(0xFFEF4444),
    },
    {
      'id': 'general',
      'name': 'General',
      'emoji': '💡',
      'color': const Color(0xFF14B8A6),
    },
  ];

  Future<void> _generateQuiz(String topicId, String topicName) async {
    setState(() {
      _selectedTopic = topicId;
      _isGenerating = true;
      _quizContent = null;
      _errorMessage = null;
      _questions = [];
      _userAnswers = {};
      _currentQuestionIndex = 0;
      _showResults = false;
    });

    // Create a prompt for generating a quiz
    final prompt = '''Create a fun and educational General Knowledge quiz about $topicName for children aged 8-12 years. 

Please format the quiz EXACTLY as follows:
1. Start with a title: "🎯 $topicName Quiz"
2. Then provide exactly 5 multiple choice questions
3. Each question should be numbered (1, 2, 3, 4, 5)
4. Each question should have exactly 4 options labeled A, B, C, D
5. After all questions, provide the answers section with "Answers:" followed by the correct answer for each question (e.g., "1. A", "2. B", etc.)
6. Make the questions interesting, age-appropriate, and educational
7. Use emojis where appropriate to make it fun

Format example:
🎯 $topicName Quiz

1. Question text here?
   A) Option 1
   B) Option 2
   C) Option 3
   D) Option 4

2. Next question...
   A) Option 1
   B) Option 2
   C) Option 3
   D) Option 4

[Continue for 5 questions]

Answers:
1. A
2. B
3. C
4. D
5. A''';

    try {
      final response = await ApiService.sendAIChatMessage([
        {
          'role': 'user',
          'content': prompt,
        }
      ]);

      if (mounted) {
        if (response['success'] == true) {
          final content = response['completion'] as String? ?? '';
          setState(() {
            _quizContent = content;
            _questions = _parseQuiz(content);
            _isGenerating = false;
            if (_questions.isEmpty) {
              _errorMessage = 'Failed to parse quiz. Please try again.';
            }
          });
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to generate quiz';
            _isGenerating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isGenerating = false;
        });
      }
    }
  }

  List<QuizQuestion> _parseQuiz(String content) {
    final questions = <QuizQuestion>[];
    final lines = content.split('\n');
    
    // Find answers section
    final answersSectionIndex = lines.indexWhere((line) => 
        line.toLowerCase().contains('answers:') || 
        line.toLowerCase().contains('answer:'));
    
    final answers = <int, String>{};
    if (answersSectionIndex != -1) {
      for (int i = answersSectionIndex + 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        // Match patterns like "1. A", "1. A)", "1) A", etc.
        final answerMatch = RegExp(r'(\d+)[\.\)]\s*([A-D])').firstMatch(line);
        if (answerMatch != null) {
          final qNum = int.tryParse(answerMatch.group(1) ?? '');
          final answer = answerMatch.group(2) ?? '';
          if (qNum != null && answer.isNotEmpty) {
            answers[qNum] = answer;
          }
        }
      }
    }

    // Parse questions
    int currentQuestionNum = 0;
    String? currentQuestion;
    List<String> currentOptions = [];
    String? currentEmoji;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Skip title line
      if (line.contains('🎯') || line.toLowerCase().contains('quiz')) {
        continue;
      }
      
      // Skip answers section
      if (i >= answersSectionIndex && answersSectionIndex != -1) {
        continue;
      }

      // Check if this is a question number (e.g., "1.", "1)", "1.")
      final questionMatch = RegExp(r'^(\d+)[\.\)]\s*(.+)').firstMatch(line);
      if (questionMatch != null) {
        // Save previous question if exists
        if (currentQuestionNum > 0 && currentQuestion != null && currentOptions.length == 4) {
          questions.add(QuizQuestion(
            number: currentQuestionNum,
            question: currentQuestion,
            options: List.from(currentOptions),
            correctAnswer: answers[currentQuestionNum] ?? 'A',
            emoji: currentEmoji,
          ));
        }
        
        // Start new question
        final qText = questionMatch.group(2) ?? '';
        currentQuestionNum = int.tryParse(questionMatch.group(1) ?? '') ?? 0;
        currentOptions = [];
        
        // Extract emoji if present (using a simpler approach)
        // Check for emoji characters in the text
        String? foundEmoji;
        final emojiRunes = qText.runes.toList();
        for (int i = 0; i < emojiRunes.length; i++) {
          final rune = emojiRunes[i];
          // Check if it's in emoji ranges (simplified check)
          if ((rune >= 0x1F300 && rune <= 0x1F9FF) ||
              (rune >= 0x2600 && rune <= 0x26FF) ||
              (rune >= 0x2700 && rune <= 0x27BF) ||
              (rune >= 0x1F600 && rune <= 0x1F64F) ||
              (rune >= 0x1F900 && rune <= 0x1F9FF)) {
            foundEmoji = String.fromCharCode(rune);
            break;
          }
        }
        currentEmoji = foundEmoji;
        
        // Remove emojis from question text (simple approach - remove first emoji-like character)
        String cleanedText = qText;
        if (foundEmoji != null) {
          cleanedText = cleanedText.replaceFirst(foundEmoji!, '').trim();
        }
        currentQuestion = cleanedText.trim();
      }
      // Check if this is an option (A), B), C), D))
      else if (RegExp(r'^[A-D][\)\.]\s*(.+)').hasMatch(line)) {
        final optionMatch = RegExp(r'^[A-D][\)\.]\s*(.+)').firstMatch(line);
        if (optionMatch != null && currentQuestionNum > 0) {
          currentOptions.add(optionMatch.group(1)?.trim() ?? '');
        }
      }
    }

    // Save last question
    if (currentQuestionNum > 0 && currentQuestion != null && currentOptions.length == 4) {
      questions.add(QuizQuestion(
        number: currentQuestionNum,
        question: currentQuestion,
        options: List.from(currentOptions),
        correctAnswer: answers[currentQuestionNum] ?? 'A',
        emoji: currentEmoji,
      ));
    }

    return questions;
  }

  void _selectAnswer(String option) {
    if (_currentQuestionIndex < _questions.length) {
      setState(() {
        _userAnswers[_questions[_currentQuestionIndex].number] = option;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Show results
      setState(() {
        _showResults = true;
      });
      // Save quiz result
      _saveQuizResult();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _resetQuiz() {
    setState(() {
      _selectedTopic = null;
      _quizContent = null;
      _errorMessage = null;
      _questions = [];
      _userAnswers = {};
      _currentQuestionIndex = 0;
      _showResults = false;
      _resultSaved = false;
    });
  }

  int _getCorrectCount() {
    int correct = 0;
    for (var question in _questions) {
      final userAnswer = _userAnswers[question.number];
      if (userAnswer == question.correctAnswer) {
        correct++;
      }
    }
    return correct;
  }

  Future<void> _saveQuizResult() async {
    if (_resultSaved || _selectedTopic == null || _questions.isEmpty) return;

    try {
      final correctCount = _getCorrectCount();
      final totalQuestions = _questions.length;
      final wrongCount = totalQuestions - correctCount;
      final percentage = (correctCount / totalQuestions * 100).toDouble();

      final topic = _topics.firstWhere(
        (t) => t['id'] == _selectedTopic,
        orElse: () => _topics[0],
      );

      await _quizDb.saveQuizResult(
        topicId: topic['id'] as String,
        topicName: topic['name'] as String,
        topicEmoji: topic['emoji'] as String?,
        topicColor: (topic['color'] as Color).value.toRadixString(16),
        totalQuestions: totalQuestions,
        correctAnswers: correctCount,
        wrongAnswers: wrongCount,
        percentage: percentage,
      );

      setState(() {
        _resultSaved = true;
      });
    } catch (e) {
      print('Error saving quiz result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _showResults || _questions.isNotEmpty
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'AI GK Quiz',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              centerTitle: false,
            ),
      body: _isGenerating && _questions.isEmpty
          ? _buildLoadingScreen()
          : _showResults
              ? _buildResultsView()
              : _questions.isNotEmpty
                  ? _buildQuestionView()
                  : _buildTopicSelection(),
    );
  }

  Widget _buildLoadingScreen() {
    final topicColor = _topics.firstWhere(
      (t) => t['id'] == _selectedTopic,
      orElse: () => _topics[0],
    )['color'] as Color;
    final topicName = _topics.firstWhere(
      (t) => t['id'] == _selectedTopic,
      orElse: () => _topics[0],
    )['name'] as String;
    final topicEmoji = _topics.firstWhere(
      (t) => t['id'] == _selectedTopic,
      orElse: () => _topics[0],
    )['emoji'] as String;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            topicColor,
            topicColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              topicEmoji,
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 4,
            ),
            const SizedBox(height: 32),
            const Text(
              'Generating your quiz...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait while we create an amazing $topicName quiz for you!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.5),
                ),
                backgroundColor: Colors.white.withOpacity(0.2),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Choose a Topic',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a topic to generate a fun quiz!',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: _topics.length,
            itemBuilder: (context, index) {
              final topic = _topics[index];
              final isSelected = _selectedTopic == topic['id'];
              final color = topic['color'] as Color;

              return GestureDetector(
                onTap: _isGenerating
                    ? null
                    : () => _generateQuiz(
                          topic['id'] as String,
                          topic['name'] as String,
                        ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        topic['emoji'] as String,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        topic['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isGenerating) ...[
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Generating your quiz...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return const Center(child: Text('No questions available'));
    }

    final question = _questions[_currentQuestionIndex];
    final topicColor = _topics.firstWhere(
      (t) => t['id'] == _selectedTopic,
      orElse: () => _topics[0],
    )['color'] as Color;
    final selectedAnswer = _userAnswers[question.number];

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                topicColor,
                topicColor.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: topicColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _resetQuiz,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _topics.firstWhere(
                          (t) => t['id'] == _selectedTopic,
                          orElse: () => _topics[0],
                        )['emoji'] as String,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_topics.firstWhere(
                          (t) => t['id'] == _selectedTopic,
                          orElse: () => _topics[0],
                        )['name']} Quiz',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentQuestionIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Question Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  topicColor,
                                  topicColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${question.number}.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (question.emoji != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              question.emoji!,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        question.question,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Options
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
                  final isSelected = selectedAnswer == optionLetter;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _selectAnswer(optionLetter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected ? topicColor.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? topicColor
                                : Colors.grey.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: topicColor.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? topicColor
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  optionLetter,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: topicColor,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                // Navigation Buttons
                Row(
                  children: [
                    if (_currentQuestionIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousQuestion,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: topicColor, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Previous',
                            style: TextStyle(
                              color: topicColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: _currentQuestionIndex > 0 ? 1 : 0,
                      child: ElevatedButton(
                        onPressed: selectedAnswer != null ? _nextQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: topicColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          _currentQuestionIndex < _questions.length - 1
                              ? 'Next'
                              : 'Finish',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    final correctCount = _getCorrectCount();
    final totalQuestions = _questions.length;
    final wrongCount = totalQuestions - correctCount;
    final percentage = (correctCount / totalQuestions * 100).round();
    final topicColor = _topics.firstWhere(
      (t) => t['id'] == _selectedTopic,
      orElse: () => _topics[0],
    )['color'] as Color;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                topicColor,
                topicColor.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: topicColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _resetQuiz,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _topics.firstWhere(
                          (t) => t['id'] == _selectedTopic,
                          orElse: () => _topics[0],
                        )['emoji'] as String,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Quiz Results',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Results Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Score Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        topicColor,
                        topicColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: topicColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Score',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            'Correct',
                            correctCount.toString(),
                            Colors.green,
                            Colors.white,
                          ),
                          _buildStatCard(
                            'Wrong',
                            wrongCount.toString(),
                            Colors.red,
                            Colors.white,
                          ),
                          _buildStatCard(
                            'Total',
                            totalQuestions.toString(),
                            Colors.white.withOpacity(0.3),
                            Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Detailed Results
                const Text(
                  'Question Review',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._questions.map((question) {
                  final userAnswer = _userAnswers[question.number];
                  final isCorrect = userAnswer == question.correctAnswer;
                  final userOptionIndex = userAnswer != null
                      ? userAnswer.codeUnitAt(0) - 65
                      : -1;
                  final correctOptionIndex =
                      question.correctAnswer.codeUnitAt(0) - 65;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isCorrect
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: isCorrect ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Question ${question.number}',
                                    style: TextStyle(
                                      color: isCorrect
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (question.emoji != null) ...[
                              const SizedBox(width: 8),
                              Text(question.emoji!, style: const TextStyle(fontSize: 20)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.question,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...question.options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          final optionLetter = String.fromCharCode(65 + index);
                          final isUserAnswer = userAnswer == optionLetter;
                          final isCorrectAnswer = question.correctAnswer == optionLetter;

                          Color? bgColor;
                          Color? textColor;
                          IconData? icon;
                          Color? iconColor;

                          if (isCorrectAnswer) {
                            bgColor = Colors.green.withOpacity(0.1);
                            textColor = Colors.green;
                            icon = Icons.check_circle;
                            iconColor = Colors.green;
                          } else if (isUserAnswer && !isCorrectAnswer) {
                            bgColor = Colors.red.withOpacity(0.1);
                            textColor = Colors.red;
                            icon = Icons.cancel;
                            iconColor = Colors.red;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgColor ?? Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: bgColor?.withOpacity(0.3) ??
                                    Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: bgColor ?? Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      optionLetter,
                                      style: TextStyle(
                                        color: textColor ?? AppColors.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: textColor ?? AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: isCorrectAnswer || isUserAnswer
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (icon != null)
                                  Icon(
                                    icon,
                                    color: iconColor,
                                    size: 20,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetQuiz,
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'New Quiz',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: topicColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex = 0;
                            _showResults = false;
                          });
                        },
                        icon: const Icon(Icons.replay),
                        label: const Text(
                          'Review',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: topicColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color bgColor, Color textColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
