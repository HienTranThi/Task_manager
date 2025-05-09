import 'package:flutter/material.dart';
import '../db/TaskDatabaseHelper.dart';
import '../model/Task.dart';
import '../model/User.dart';
import 'TaskForm.dart';
import 'TaskListItem.dart';
import 'login.dart';
import 'TaskDetailScreen.dart';

class TaskListScreen extends StatefulWidget {
  final User loggedInUser;
  const TaskListScreen({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskDatabaseHelper _dbHelper = TaskDatabaseHelper.instance;
  bool _isKanbanView = false;
  String _searchQuery = '';
  String? _filterCategory;
  late Future<List<Task>> _taskFuture;

  @override
  void initState() {
    super.initState();
    _loadTasks(); // Tải task ban đầu khi màn hình được tạo
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Xác nhận đăng xuất"),
          content: Text("Bạn có chắc chắn muốn đăng xuất không?"),
          actions: <Widget>[
            TextButton(
              child: Text("Hủy"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () {
                print('Logging out...');
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text(
                "Đăng xuất",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Tải danh sách công việc
  void _loadTasks() {
    setState(() {
      print('Loading tasks...');
      // TODO: Có thể thêm logic lọc task chỉ hiển thị task của người dùng hiện tại
      // trừ khi người dùng là admin NGAY TẠI ĐÂY trước khi query DB.
      // Hoặc sửa các hàm query trong TaskDatabaseHelper để nhận loggedInUser và lọc trong DB.
      // Hiện tại đang lấy tất cả tasks (getAllTasks, searchTasks, getTasksByCategory)
      // Nếu muốn phân quyền hiển thị, bạn cần modify các hàm query trong TaskDatabaseHelper
      // hoặc lọc kết quả sau khi query.

      // Tạm thời vẫn giữ logic query cũ để tập trung vào UI và Action Permission
      if (_searchQuery.isNotEmpty) {
        _taskFuture = _dbHelper.searchTasks(_searchQuery);
      } else if (_filterCategory != null) {
        _taskFuture = _dbHelper.getTasksByCategory(_filterCategory!);
      } else {
        _taskFuture = _dbHelper.getAllTasks(); // Lấy tất cả task (cho cả Admin và Regular xem, nếu không lọc)
      }
    });
  }

  void _toggleView() {
    setState(() {
      _isKanbanView = !_isKanbanView;
      print('Toggled view. _isKanbanView is now: $_isKanbanView');
    });
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Lọc theo danh mục"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text("Tất cả"), onTap: () {
              _filterCategory = null;
              Navigator.pop(context);
              _loadTasks();
            }),
            ListTile(title: Text("Công việc"), onTap: () {
              _filterCategory = "Công việc";
              Navigator.pop(context);
              _loadTasks();
            }),
            ListTile(title: Text("Cá nhân"), onTap: () {
              _filterCategory = "Cá nhân";
              Navigator.pop(context);
              _loadTasks();
            }),
          ],
        ),
      ),
    );
  }

  // Hàm xây dựng widget TaskListItem cho từng công việc
  Widget _buildTaskItem(Task task) {
    // Bọc TaskListItem bằng GestureDetector hoặc InkWell để xử lý sự kiện chạm
    return GestureDetector(
      onTap: () async {
        //  TRUYỀN USER: Truyền đối tượng User đã đăng nhập đến TaskDetailScreen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            //CẦN THAY ĐỔI CONSTRUCTOR TaskDetailScreen ĐỂ NHẬN loggedInUser -->
            builder: (context) => TaskDetailScreen(
              task: task,
              onTaskUpdated: _loadTasks,
              loggedInUser: widget.loggedInUser,
            ),
          ),
        );
        if (result == true) {
          _loadTasks();
        }
      },

      child: TaskListItem(
        task: task,
        onTaskUpdated: _loadTasks,
        loggedInUser: widget.loggedInUser,
      ),
    );
  }

  // Hàm xây dựng chế độ xem Kanban (giữ nguyên logic, gọi _buildTaskItem)
  Widget _buildKanbanView(List<Task> tasks) {
    final statuses = ['Cần làm', 'Đang tiến hành', 'Hoàn thành'];
    print('Building Kanban View...');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: statuses.map((status) {
        final filtered = tasks.where((t) => t.status == status).toList();
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    status,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey.shade800),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _buildTaskItem(filtered[i]), // _buildTaskItem giờ đã truyền user vào TaskListItem
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }


  @override
  Widget build(BuildContext context) {
    print('Building TaskListScreen for user: ${widget.loggedInUser.username} (${widget.loggedInUser.role})');
    print('Current view: ${_isKanbanView ? "Kanban" : "List"}');

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("Công việc của tôi"), // Có thể tùy chỉnh tiêu đề
        // THÊM: Hiển thị tên user và role ở đâu đó, ví dụ Drawer (tùy chọn)
        // leading: Builder( ... ),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadTasks, tooltip: 'Làm mới danh sách'),
          IconButton(
            icon: Icon(_isKanbanView ? Icons.list : Icons.view_column),
            onPressed: _toggleView,
            tooltip: _isKanbanView ? 'Chuyển sang dạng danh sách' : 'Chuyển sang dạng Kanban',
          ),
          IconButton(icon: Icon(Icons.filter_alt), onPressed: _showCategoryFilterDialog, tooltip: 'Lọc theo danh mục'),
          // Nút Đăng xuất
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Tìm kiếm công việc...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _loadTasks();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _taskFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('FutureBuilder Error: ${snapshot.error}');
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  print('No tasks data available.');
                  String emptyMessage = "Không có công việc nào";
                  if(_searchQuery.isNotEmpty) emptyMessage = "Không tìm thấy công việc nào cho '${_searchQuery}'";
                  else if (_filterCategory != null) emptyMessage = "Không có công việc nào trong danh mục '${_filterCategory}'";
                  // TODO: Nếu có lọc theo người dùng, thông báo có thể khác

                  return Center(child: Text(emptyMessage));
                }

                final tasks = snapshot.data!;
                print('Data loaded. Number of tasks: ${tasks.length}');

                return _isKanbanView
                    ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildKanbanView(tasks), // Xây dựng Kanban view
                )
                    : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, i) => _buildTaskItem(tasks[i]), // Sử dụng _buildTaskItem
                );
              },
            ),
          ),
        ],
      ),
      // Nút Floating Action Button để thêm công việc mới
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskForm(loggedInUser: widget.loggedInUser)) // <-- Truyền user
          );
          if (result == true) {
            _loadTasks();
          }
        },
      ),
    );
  }
}