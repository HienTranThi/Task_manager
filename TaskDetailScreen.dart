import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/Task.dart';
import '../db/TaskDatabaseHelper.dart';
import 'TaskForm.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/User.dart';

// Màn hình hiển thị chi tiết công việc
class TaskDetailScreen extends StatefulWidget {
  final Task task; // Đối tượng Task cần hiển thị chi tiết
  // Callback để thông báo cho màn hình trước (TaskListScreen) khi có thay đổi
  final VoidCallback onTaskUpdated;
  final User loggedInUser; //  Đối tượng User đã đăng nhập


  const TaskDetailScreen({
    Key? key,
    required this.task,
    required this.onTaskUpdated,
    required this.loggedInUser,
  }) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  // Biến để lưu trữ task hiện tại (có thể thay đổi trạng thái)
  late Task _currentTask;
  final TaskDatabaseHelper _dbHelper = TaskDatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    // Khi vào màn hình chi tiết, có thể cần lấy lại task đầy đủ
    // để đảm bảo dữ liệu mới nhất nếu có thay đổi ở TaskListItem (ví dụ: đánh dấu hoàn thành nhanh)
    _loadTaskDetails();
  }

  // Thêm hàm tải chi tiết task riêng nếu cần refresh data
  Future<void> _loadTaskDetails() async {
    if (_currentTask.id != null) {
      final latestTask = await _dbHelper.getTaskById(_currentTask.id!);
      if (latestTask != null && mounted) { // Kiểm tra mounted trước khi setState
        setState(() {
          _currentTask = latestTask;
        });
      }
    }
  }


  // Hàm cập nhật trạng thái công việc - THÊM KIỂM TRA QUYỀN
  Future<void> _updateStatus(String newStatus) async {
    //  Kiểm tra quyền trước khi cập nhật trạng thái
    final bool isUserAdmin = widget.loggedInUser.role == 'admin';
    final bool isTaskCreator = _currentTask.createdBy == widget.loggedInUser.id;
    final bool isTaskAssigned = _currentTask.assignedTo == widget.loggedInUser.id;
    // Quy tắc quyền hoàn thành task: Admin HOẶC người tạo HOẶC người được gán
    final bool canComplete = isUserAdmin || isTaskCreator || isTaskAssigned;

    if (!canComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bạn không có quyền thay đổi trạng thái công việc này.')),
      );
      return; // Dừng hàm nếu không có quyền
    }
    if (_currentTask.status != newStatus) {
      final updatedTask = _currentTask.copyWith(
        status: newStatus,
        completed: newStatus == 'Hoàn thành',
        updatedAt: DateTime.now(),
      );
      await _dbHelper.updateTask(updatedTask);
      // Cập nhật UI và thông báo cho màn hình cha
      setState(() {
        _currentTask = updatedTask;
      });
      widget.onTaskUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật trạng thái thành: $newStatus')),
      );
    }
  }

  // Hàm mở tệp đính kèm (giữ nguyên)
  Future<void> _launchAttachment(String filePath) async {
    final uri = Uri.file(filePath);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở tệp: $filePath')),
        );
        print('Could not launch $filePath');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi mở tệp: ${e.toString()}')),
      );
      print('Error launching file: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final formattedCreatedAt = DateFormat('dd/MM/yyyy HH:mm').format(_currentTask.createdAt);
    final formattedUpdatedAt = DateFormat('dd/MM/yyyy HH:mm').format(_currentTask.updatedAt);
    final formattedDueDate = _currentTask.dueDate != null ? DateFormat('dd/MM/yyyy').format(_currentTask.dueDate!) : 'Chưa đặt';

    //  Logic kiểm tra quyền cho nút Edit và cập nhật trạng thái UI
    final bool isUserAdmin = widget.loggedInUser.role == 'admin';
    final bool isTaskCreator = _currentTask.createdBy == widget.loggedInUser.id;
    final bool isTaskAssigned = _currentTask.assignedTo == widget.loggedInUser.id;
    // Quyền chỉnh sửa: Admin HOẶC người tạo HOẶC người được gán
    final bool canEdit = isUserAdmin || isTaskCreator || isTaskAssigned;

    // Quyền hiển thị phần cập nhật trạng thái: Giống quyền chỉnh sửa trong ví dụ này
    final bool canUpdateStatusUI = canEdit; // Hoặc định nghĩa luật riêng nếu khác

    // Quyền xóa: Admin HOẶC người tạo
    final bool canDelete = isUserAdmin || isTaskCreator; // Giống như ở TaskListItem


    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết công việc'),
        actions: [
          // Nút chỉnh sửa - ÁP DỤNG KIỂM TRA QUYỀN canEdit
          if (canEdit) // CHỈ HIỂN THỊ NÚT NÀY NẾU canEdit là true
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                // Logic điều hướng đến TaskForm
                // Bạn có thể thêm kiểm tra quyền lần nữa ở đây trước khi điều hướng (tùy chọn)
                // if (!canEdit) { show message; return; }
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskForm(
                      task: _currentTask,
                      loggedInUser: widget.loggedInUser, // Truyền loggedInUser
                    ),
                  ),
                );
                if (result == true) {
                  // Tải lại chi tiết task sau khi chỉnh sửa
                  await _loadTaskDetails(); // Gọi hàm tải lại chi tiết
                  widget.onTaskUpdated(); // Thông báo list để refresh
                }
              },
              tooltip: 'Chỉnh sửa công việc',
            ),
          if (canDelete)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                // TODO: Triển khai logic xóa task tương tự như trong TaskListItem
                // và gọi _loadTaskDetails() sau khi xóa thành công (hoặc pop về màn hình trước)
                bool? confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Xác nhận xóa'),
                      content: const Text('Bạn có chắc chắn muốn xóa công việc này?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );

                if (confirmDelete == true && _currentTask.id != null) {
                  await _dbHelper.deleteTask(_currentTask.id!);
                  widget.onTaskUpdated();
                  Navigator.of(context).pop(); // Quay lại màn hình danh sách sau khi xóa
                }
              },
              tooltip: 'Xóa công việc',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ... Hiển thị thông tin task (Title, Description, DueDate, ...) giữ nguyên ...
            Text(
              _currentTask.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (_currentTask.description != null && _currentTask.description!.isNotEmpty) ...[
              Text(
                _currentTask.description!,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              ),
              SizedBox(height: 16),
            ],
            _buildDetailRow('Trạng thái:', _currentTask.status),
            _buildDetailRow('Mức độ ưu tiên:', _currentTask.priority.toString()),
            _buildDetailRow('Ngày đến hạn:', formattedDueDate),
            // TODO: Hiển thị tên người được giao và người tạo thay vì ID (Cần query User theo ID)
            _buildDetailRow('Người được giao:', _currentTask.assignedTo ?? 'Chưa gán'),
            _buildDetailRow('Người tạo:', _currentTask.createdBy),
            _buildDetailRow('Ngày tạo:', formattedCreatedAt),
            _buildDetailRow('Cập nhật lần cuối:', formattedUpdatedAt),
            _buildDetailRow('Đã hoàn thành:', _currentTask.completed ? 'Có' : 'Không'),

            SizedBox(height: 20),

            if (_currentTask.attachments != null && _currentTask.attachments!.isNotEmpty) ...[
              // ... Hiển thị tệp đính kèm giữ nguyên ...
              Text(
                'Tệp đính kèm:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _currentTask.attachments!.map((filePath) {
                  return ListTile(
                    leading: Icon(Icons.attach_file),
                    title: Text(filePath.split('/').last),
                    onTap: () => _launchAttachment(filePath),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
            ],

            // Cập nhật trạng thái: ÁP DỤNG KIỂM TRA QUYỀN canUpdateStatusUI
            if (canUpdateStatusUI) // CHỈ HIỂN THỊ PHẦN CẬP NHẬT TRẠNG THÁI NẾU CÓ QUYỀN
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cập nhật trạng thái:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _currentTask.status,
                    items: ['Cần làm', 'Đang tiến hành', 'Hoàn thành']
                        .map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _updateStatus(newValue); // Hàm này đã tự kiểm tra quyền bên trong
                      }
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  // Hàm helper để xây dựng hàng hiển thị chi tiết (giữ nguyên)
  Widget _buildDetailRow(String label, String value) { /* ... giữ nguyên ... */
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}