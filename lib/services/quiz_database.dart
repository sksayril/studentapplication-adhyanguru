import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QuizDatabase {
  static final QuizDatabase instance = QuizDatabase._init();
  static Database? _database;

  QuizDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quizzes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Quiz results table
    await db.execute('''
      CREATE TABLE quiz_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id TEXT NOT NULL,
        topic_name TEXT NOT NULL,
        topic_emoji TEXT,
        topic_color TEXT,
        total_questions INTEGER NOT NULL,
        correct_answers INTEGER NOT NULL,
        wrong_answers INTEGER NOT NULL,
        percentage REAL NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_created_at ON quiz_results(created_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_topic_id ON quiz_results(topic_id)
    ''');
  }

  // Save a quiz result
  Future<int> saveQuizResult({
    required String topicId,
    required String topicName,
    String? topicEmoji,
    String? topicColor,
    required int totalQuestions,
    required int correctAnswers,
    required int wrongAnswers,
    required double percentage,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    return await db.insert(
      'quiz_results',
      {
        'topic_id': topicId,
        'topic_name': topicName,
        'topic_emoji': topicEmoji,
        'topic_color': topicColor,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'wrong_answers': wrongAnswers,
        'percentage': percentage,
        'created_at': now,
      },
    );
  }

  // Get all quiz results
  Future<List<Map<String, dynamic>>> getAllQuizResults() async {
    final db = await database;
    return await db.query(
      'quiz_results',
      orderBy: 'created_at DESC',
    );
  }

  // Get recent quiz results (limit)
  Future<List<Map<String, dynamic>>> getRecentQuizResults({int limit = 10}) async {
    final db = await database;
    return await db.query(
      'quiz_results',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  // Get quiz results by topic
  Future<List<Map<String, dynamic>>> getQuizResultsByTopic(String topicId) async {
    final db = await database;
    return await db.query(
      'quiz_results',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'created_at DESC',
    );
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    
    // Get total quizzes
    final totalQuizzesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM quiz_results',
    );
    final totalQuizzes = totalQuizzesResult.first['count'] as int? ?? 0;

    // Get total correct answers
    final correctResult = await db.rawQuery(
      'SELECT SUM(correct_answers) as total FROM quiz_results',
    );
    final totalCorrect = correctResult.first['total'] as int? ?? 0;

    // Get total questions
    final questionsResult = await db.rawQuery(
      'SELECT SUM(total_questions) as total FROM quiz_results',
    );
    final totalQuestions = questionsResult.first['total'] as int? ?? 0;

    // Calculate winning percentage
    double winningPercentage = 0.0;
    if (totalQuestions > 0) {
      winningPercentage = (totalCorrect / totalQuestions) * 100;
    }

    // Get average percentage
    final avgResult = await db.rawQuery(
      'SELECT AVG(percentage) as avg FROM quiz_results',
    );
    final avgPercentage = avgResult.first['avg'] as double? ?? 0.0;

    return {
      'totalQuizzes': totalQuizzes,
      'totalCorrect': totalCorrect,
      'totalQuestions': totalQuestions,
      'winningPercentage': winningPercentage,
      'averagePercentage': avgPercentage,
    };
  }

  // Delete a quiz result
  Future<void> deleteQuizResult(int id) async {
    final db = await database;
    await db.delete(
      'quiz_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all quiz results
  Future<void> deleteAllQuizResults() async {
    final db = await database;
    await db.delete('quiz_results');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

