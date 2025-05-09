import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/Task.dart';

class TaskDatabaseHelper {
  static final TaskDatabaseHelper instance = TaskDatabaseHelper._init();
  static Database? _database;
  TaskDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks_database.db');
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

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        priority INTEGER NOT NULL,
        dueDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        assignedTo TEXT,
        createdBy TEXT NOT NULL,
        category TEXT,
        attachments TEXT,
        completed INTEGER NOT NULL
      )
    ''');
    await insertSampleTasks(db);
  }

  Future<void> insertSampleTasks(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tasks'));
    if (count != null && count > 0) return;

    final now = DateTime.now();
    final sampleTasks = [
      {
        'title': 'Hoàn thành báo cáo quý',
        'description': 'Viết báo cáo tổng kết hoạt động quý 1.',
        'status': 'Đang tiến hành',
        'priority': 3,
        'dueDate': now.add(Duration(days: 7)).toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'assignedTo': 'user123',
        'createdBy': 'user123',
        'category': 'Công việc',
        'attachments': 'link1,link2',
        'completed': 0,
      },
      {
        'title': 'Mua sữa và bánh mì',
        'description': null,
        'status': 'Cần làm',
        'priority': 1,
        'dueDate': now.add(Duration(hours: 2)).toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'assignedTo': null,
        'createdBy': 'user456',
        'category': 'Cá nhân',
        'attachments': null,
        'completed': 0,
      },
    ];

    for (final task in sampleTasks) {
      await db.insert('tasks', task, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
  Future<Task?> getTaskById(String id) async {
    final db = await instance.database;
    // Truy vấn bảng 'tasks' với điều kiện 'id = ?'
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id], // Giá trị cho điều kiện where
      limit: 1, // Chỉ lấy 1 kết quả vì ID là duy nhất
    );

    // Nếu có kết quả (maps không rỗng), chuyển đổi Map đầu tiên thành đối tượng Task
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    // Trả về null nếu không tìm thấy công việc với ID đó
    return null;
  }

  Future<List<Task>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', orderBy: 'createdAt DESC');
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> searchTasks(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksByCategory(String category) async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<Task> createTask(Task task) async {
    final db = await instance.database;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id.toString());
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
