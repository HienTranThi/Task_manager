import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/User.dart';
enum LoginResultStatus {
  success,
  userNotFound,
  incorrectPassword,
  error,
}

class LoginOperationResult {
  final LoginResultStatus status;
  final User? user;
  LoginOperationResult(this.status, {this.user});
}

class UserDatabaseHelper {
  static final UserDatabaseHelper instance = UserDatabaseHelper._init();
  static Database? _database;

  UserDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    print('Initializing database at path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        print('Database opened.');
      },
    );
  }

  // Hàm tạo bảng trong database
  Future _createDB(Database db, int version) async {
    print('Creating database tables...');
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL, -- Trong thực tế cần mã hóa/băm!
        avatar TEXT,
        createdAt TEXT NOT NULL,
        lastActive TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'regular' -- <-- THÊM: Cột role với giá trị mặc định
      )
    ''');
    print('Users table created.');
    await _insertSampleUsers(db);
  }


  // Hàm chèn dữ liệu mẫu người dùng
  Future<void> _insertSampleUsers(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'));
    if (count != null && count > 0) {
      print('Bảng users đã có dữ liệu mẫu.');
      return;
    }

    final now = DateTime.now();
    final List<Map<String, dynamic>> sampleUsers = [
      {
        'username': 'admin',
        'email': 'admin@example.com',
        'password': '123456', // TODO: Mã hóa!
        'avatar': null,
        'createdAt': now.toIso8601String(),
        'lastActive': now.toIso8601String(),
        'role': 'admin',
      },
      {
        'username': 'Hien',
        'email': 'hien.tran@example.com',
        'password': '123456', // TODO: Mã hóa!
        'avatar': null,
        'createdAt': now.toIso8601String(),
        'lastActive': now.toIso8601String(),
        'role': 'regular',
      },
      {
        'username': 'test',
        'email': 'test@example.com',
        'password': '123456', // TODO: Mã hóa!
        'avatar': 'http://example.com/avatars/test.png',
        'createdAt': now.subtract(Duration(days: 1)).toIso8601String(),
        'lastActive': now.toIso8601String(),
        'role': 'regular',
      },
      {
        'username': 'A',
        'email': 'a.nguyen@example.com',
        'password': '123456', // TODO: Mã hóa!
        'avatar': null,
        'createdAt': now.subtract(Duration(days: 5)).toIso8601String(),
        'lastActive': now.subtract(Duration(hours: 2)).toIso8601String(),
        'role': 'regular',
      },
    ];

    print('Đang chèn dữ liệu người dùng mẫu...');
    for (final userData in sampleUsers) {
      try {
        await db.insert('users', userData, conflictAlgorithm: ConflictAlgorithm.ignore);
        print('-> Đã chèn: ${userData['username']} (${userData['role']})'); // In cả role
      } catch (e) {
        print('-> Lỗi khi chèn ${userData['username']}: $e');
      }
    }
    print('Hoàn thành chèn dữ liệu người dùng mẫu.');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null;
    print('Database closed.');
  }

  // Hàm createUser (không cần thay đổi nhiều vì User.toMap() đã bao gồm role)
  Future<String> createUser(User user) async {
    final db = await instance.database;
    try {
      print('Attempting to create user: ${user.username}');
      final id = await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
      print('User created successfully with ID: $id');
      return "Đăng ký tài khoản thành công!";
    } on DatabaseException catch (e) {
      print('DatabaseException during createUser: ${e.toString()}');
      if (e.isUniqueConstraintError()) {
        if (e.toString().contains('users.email')) {
          return "Email này đã được sử dụng. Vui lòng sử dụng email khác.";
        } else if (e.toString().contains('users.username')) {
          return "Tên đăng nhập này đã được sử dụng. Vui lòng sử dụng tên đăng nhập khác.";
        } else {
          return "Lỗi ràng buộc UNIQUE: ${e.toString()}";
        }
      } else {
        throw e;
      }
    } catch (e) {
      print('Other error during createUser: ${e.toString()}');
      throw e;
    }
  }

  // Hàm login - Cập nhật để lấy cả cột role
  Future<LoginOperationResult> loginUser(String identifier, String password) async {
    final db = await instance.database;
    print('Attempting login query in DB: Identifier="$identifier", Password length=${password.length}'); // Tránh in mật khẩu thật
    try {
      final userMaps = await db.query(
        'users',
        columns: ['id', 'username', 'email', 'password', 'avatar', 'createdAt', 'lastActive', 'role'],
        where: 'username = ? OR email = ?',
        whereArgs: [identifier, identifier],
        limit: 1,
      );

      if (userMaps.isEmpty) {
        print('Login failed: User not found for identifier: $identifier');
        return LoginOperationResult(LoginResultStatus.userNotFound);
      }

      final userData = userMaps.first;
      final storedPassword = userData['password'] as String;

      // LƯU Ý: Cần mã hóa mật khẩu và so sánh bằng hàm băm trong thực tế!
      if (password == storedPassword) {
        final loggedInUser = User.fromMap(userData);
        // Tùy chọn: Cập nhật thời gian hoạt động gần nhất
        await db.update(
          'users',
          {'lastActive': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [loggedInUser.id],
        );

        print('Login successful for user: ${loggedInUser.username} (Role: ${loggedInUser.role})'); // In cả role khi đăng nhập
        return LoginOperationResult(LoginResultStatus.success, user: loggedInUser);

      } else {
        print('Login failed: Incorrect password for identifier: $identifier');
        return LoginOperationResult(LoginResultStatus.incorrectPassword);
      }

    } catch (e) {
      print('Database error during login: ${e.toString()}');
      return LoginOperationResult(LoginResultStatus.error);
    }
  }

  // Cập nhật các hàm lấy User khác để lấy cả cột role
  Future<User?> getUserById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',

      columns: ['id', 'username', 'email', 'password', 'avatar', 'createdAt', 'lastActive', 'role'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: ['id', 'username', 'email', 'password', 'avatar', 'createdAt', 'lastActive', 'role'],
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: ['id', 'username', 'email', 'password', 'avatar', 'createdAt', 'lastActive', 'role'],
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users', columns: ['id', 'username', 'email', 'password', 'avatar', 'createdAt', 'lastActive', 'role']);

    return result.map((map) => User.fromMap(map)).toList();
  }


  // Hàm updateUser (không cần thay đổi vì user.toMap() đã bao gồm role)
  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Hàm deleteUser (giữ nguyên)
  Future<int> deleteUser(String id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}