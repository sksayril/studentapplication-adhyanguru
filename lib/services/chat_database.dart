import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChatDatabase {
  static final ChatDatabase instance = ChatDatabase._init();
  static Database? _database;

  ChatDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chats.db');
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
    // Chat sessions table
    await db.execute('''
      CREATE TABLE chat_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Chat messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (id) ON DELETE CASCADE
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_session_id ON chat_messages(session_id)
    ''');
  }

  // Create a new chat session
  Future<int> createChatSession(String title) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return await db.insert(
      'chat_sessions',
      {
        'title': title,
        'created_at': now,
        'updated_at': now,
      },
    );
  }

  // Get all chat sessions
  Future<List<Map<String, dynamic>>> getAllChatSessions() async {
    final db = await database;
    return await db.query(
      'chat_sessions',
      orderBy: 'updated_at DESC',
    );
  }

  // Get a single chat session
  Future<Map<String, dynamic>?> getChatSession(int sessionId) async {
    final db = await database;
    final results = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    return results.first;
  }

  // Update chat session title
  Future<void> updateChatSessionTitle(int sessionId, String title) async {
    final db = await database;
    await db.update(
      'chat_sessions',
      {
        'title': title,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // Delete a chat session
  Future<void> deleteChatSession(int sessionId) async {
    final db = await database;
    await db.delete(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // Add a message to a chat session
  Future<int> addMessage(int sessionId, String role, String content) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Update session's updated_at timestamp
    await db.update(
      'chat_sessions',
      {'updated_at': now},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    
    return await db.insert(
      'chat_messages',
      {
        'session_id': sessionId,
        'role': role,
        'content': content,
        'created_at': now,
      },
    );
  }

  // Get all messages for a chat session
  Future<List<Map<String, dynamic>>> getMessages(int sessionId) async {
    final db = await database;
    return await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

