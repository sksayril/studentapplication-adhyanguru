import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:async';
import '../../utils/colors.dart';
import '../../services/api_service.dart';

class AIStoryScreen extends StatefulWidget {
  const AIStoryScreen({Key? key}) : super(key: key);

  @override
  State<AIStoryScreen> createState() => _AIStoryScreenState();
}

class _AIStoryScreenState extends State<AIStoryScreen> {
  String? _selectedStoryType;
  String? _selectedTone;
  String _selectedTopic = '';
  String _customTopic = '';
  bool _isGenerating = false;
  String? _generatedStory;
  String? _errorMessage;
  final TextEditingController _topicController = TextEditingController();
  Timer? _animationTimer;
  double _animationValue = 0.0;

  final List<Map<String, dynamic>> _storyTypes = [
    {'id': 'adventure', 'name': 'Adventure', 'emoji': '🏔️'},
    {'id': 'fantasy', 'name': 'Fantasy', 'emoji': '🧙'},
    {'id': 'friendship', 'name': 'Friendship', 'emoji': '👫'},
    {'id': 'animals', 'name': 'Animals', 'emoji': '🦁'},
    {'id': 'science', 'name': 'Science', 'emoji': '🔬'},
    {'id': 'history', 'name': 'History', 'emoji': '🏛️'},
    {'id': 'nature', 'name': 'Nature', 'emoji': '🌳'},
    {'id': 'magic', 'name': 'Magic', 'emoji': '✨'},
  ];

  final List<Map<String, dynamic>> _tones = [
    {'id': 'funny', 'name': 'Funny', 'emoji': '😄'},
    {'id': 'inspiring', 'name': 'Inspiring', 'emoji': '🌟'},
    {'id': 'educational', 'name': 'Educational', 'emoji': '📚'},
    {'id': 'mysterious', 'name': 'Mysterious', 'emoji': '🔍'},
    {'id': 'happy', 'name': 'Happy', 'emoji': '😊'},
    {'id': 'adventurous', 'name': 'Adventurous', 'emoji': '⚡'},
  ];

  final List<String> _defaultTopics = [
    'A brave little mouse',
    'The magic forest',
    'Friends helping each other',
    'A curious scientist',
    'The lost treasure',
    'A kind princess',
    'The talking animals',
    'A space adventure',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _animationValue = (_animationValue + 0.02) % 1.0;
        });
      }
    });
  }

  Future<void> _generateStory() async {
    if (_selectedStoryType == null || _selectedTone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select story type and tone'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final topic = _customTopic.trim().isNotEmpty
        ? _customTopic.trim()
        : (_selectedTopic.isNotEmpty
            ? _selectedTopic
            : (_defaultTopics.isNotEmpty ? _defaultTopics[0] : 'A fun adventure'));

    setState(() {
      _isGenerating = true;
      _generatedStory = null;
      _errorMessage = null;
    });

    final storyTypeName = _storyTypes.firstWhere(
      (t) => t['id'] == _selectedStoryType,
      orElse: () => _storyTypes[0],
    )['name'] as String;

    final toneName = _tones.firstWhere(
      (t) => t['id'] == _selectedTone,
      orElse: () => _tones[0],
    )['name'] as String;

    final prompt = '''Create a fun and engaging story for children aged 8-12 years.

Story Requirements:
- Story Type: $storyTypeName
- Tone: $toneName
- Topic/Subject: $topic

Please format the story EXACTLY as follows:

**Title:** [Story Title Here]

**Story:**

[Write the story content here. Make it engaging, age-appropriate, and around 300-500 words. Include interesting characters, a clear plot, and descriptive details.]

**Moral:** [A clear moral lesson or message from the story]

Make sure the story is:
- Age-appropriate for children 8-12 years
- Engaging and fun to read
- Has a clear beginning, middle, and end
- Includes the moral lesson naturally in the story
- Uses simple language that children can understand
- Has positive values and messages''';

    try {
      final response = await ApiService.sendAIChatMessage([
        {
          'role': 'user',
          'content': prompt,
        }
      ]);

      if (mounted) {
        if (response['success'] == true) {
          setState(() {
            _generatedStory = response['completion'] as String? ?? '';
            _isGenerating = false;
          });
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to generate story';
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

  void _resetStory() {
    setState(() {
      _generatedStory = null;
      _errorMessage = null;
      _selectedTopic = '';
      _customTopic = '';
      _topicController.clear();
    });
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
          'AI Story',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: _isGenerating
          ? _buildLoadingScreen()
          : _generatedStory != null
              ? _buildStoryView()
              : _buildStoryCreationView(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated book icon with pulsing effect
            AnimatedBuilder(
              animation: AlwaysStoppedAnimation(_animationValue),
              builder: (context, child) {
                final scale = 0.9 + (0.1 * (0.5 + 0.5 * (1 - (_animationValue * 2 % 1.0))));
                final rotation = (_animationValue * 0.1) % 0.2 - 0.1;
                return Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3 * _animationValue),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Text(
                        '📖',
                        style: TextStyle(fontSize: 100),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            // Loading indicator with custom styling
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Creating Your Story...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Our AI is crafting a magical story just for you! ✨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 60),
            // Animated progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _animationValue,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.9),
                  ),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Animated dots with wave effect
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return AnimatedBuilder(
                  animation: AlwaysStoppedAnimation(_animationValue),
                  builder: (context, child) {
                    final delay = index * 0.15;
                    final animationValue = ((_animationValue + delay) % 1.0);
                    final opacity = 0.3 + (0.7 * (0.5 + 0.5 * (1 - (animationValue * 2 % 1.0))));
                    final scale = 0.8 + (0.4 * (0.5 + 0.5 * (1 - (animationValue * 2 % 1.0))));
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 16 * scale,
                      height: 16 * scale,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(opacity),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(opacity * 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 40),
            // Sparkle effect text
            AnimatedBuilder(
              animation: AlwaysStoppedAnimation(_animationValue),
              builder: (context, child) {
                final sparkleOpacity = (0.3 + 0.7 * (0.5 + 0.5 * (1 - (_animationValue * 3 % 1.0))));
                return Opacity(
                  opacity: sparkleOpacity,
                  child: const Text(
                    '✨ Writing with magic ✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCreationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Create Your Story',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose story type, tone, and topic to generate a fun story!',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          // Story Type Selection
          const Text(
            'Story Type',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _storyTypes.map((type) {
              final isSelected = _selectedStoryType == type['id'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStoryType = type['id'] as String;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEC4899).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEC4899)
                          : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        type['emoji'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type['name'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFEC4899)
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // Tone Selection
          const Text(
            'Tone',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _tones.map((tone) {
              final isSelected = _selectedTone == tone['id'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTone = tone['id'] as String;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEC4899).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEC4899)
                          : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tone['emoji'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tone['name'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFEC4899)
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // Topic Selection
          const Text(
            'Topic / Subject',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Default Topics
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _defaultTopics.map((topic) {
              final isSelected = _customTopic.isEmpty && _selectedTopic == topic;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTopic = topic;
                    _customTopic = '';
                    _topicController.clear();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEC4899).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEC4899)
                          : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    topic,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFEC4899)
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Custom Topic Input
          TextField(
            controller: _topicController,
            decoration: InputDecoration(
              hintText: 'Or type your own topic...',
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.6),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFEC4899),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _customTopic = value;
                if (value.trim().isNotEmpty) {
                  _selectedTopic = '';
                }
              });
            },
          ),
          const SizedBox(height: 32),
          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Generating Story...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Generate Story',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
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
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStoryView() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withOpacity(0.3),
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
                  onPressed: _resetStory,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Your Story',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // TODO: Implement share functionality
                  },
                ),
              ],
            ),
          ),
        ),
        // Story Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Container(
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
              child: _generatedStory != null
                  ? MarkdownBody(
                      data: _generatedStory!,
                      styleSheet: MarkdownStyleSheet(
                        h1: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                        ),
                        h2: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                        p: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          height: 1.8,
                        ),
                        strong: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        em: const TextStyle(
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                        code: TextStyle(
                          color: AppColors.primary,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        codeblockPadding: const EdgeInsets.all(12),
                        blockquote: const TextStyle(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withOpacity(0.1),
                          border: const Border(
                            left: BorderSide(
                              color: Color(0xFFEC4899),
                              width: 4,
                            ),
                          ),
                        ),
                        blockquotePadding: const EdgeInsets.all(12),
                      ),
                      shrinkWrap: true,
                    )
                  : const SizedBox(),
            ),
          ),
        ),
        // Action Buttons
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetStory,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'New Story',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFEC4899), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateStory,
                  icon: const Icon(Icons.auto_stories),
                  label: const Text(
                    'Regenerate',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
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
        ),
      ],
    );
  }
}

