import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/Task.dart';
import '../db/TaskDatabaseHelper.dart';
import '../model/User.dart';
import 'TaskForm.dart';
import 'TaskDetailScreen.dart';
import 'package:url_launcher/url_launcher.dart';


class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTaskUpdated;
  final User loggedInUser; // NHẬN: Nhận thông tin người dùng đăng nhập


  const TaskListItem({
    Key? key,
    required this.task,
    required this.onTaskUpdated,
    required this.loggedInUser,
  }) : super(key: key);

  // Hàm helper để lấy màu sắc cho nền Card dựa trên mức độ ưu tiên
  Color _getCardBackgroundColor(int priority) {
    switch (priority) {
      case 1: return Colors.green.shade400;
      case 2: return Colors.orange.shade400;
      case 3: return Colors.red.shade400;
      default: return Colors.blueGrey.shade100;
    }
  }

  // Hàm helper để lấy màu sắc chỉ thị dựa trên trạng thái của task
  Color _getStatusIndicatorColor(String status) {
    switch (status) {
      case 'Cần làm': return Colors.blue.shade800;
      case 'Đang tiến hành': return Colors.orange.shade800;
      case 'Hoàn thành': return Colors.green.shade800;
      default: return Colors.grey.shade800;
    }
  }

  // Hàm helper để lấy màu chữ dựa trên màu nền Card
  Color _getTextColor(Color backgroundColor) {
    return Colors.black87;
  }


  @override
  Widget build(BuildContext context) {
    final TaskDatabaseHelper _dbHelper = TaskDatabaseHelper.instance;
    final formattedDueDate = task.dueDate != null ? DateFormat('dd/MM/yyyy').format(task.dueDate!) : 'Chưa đặt hạn';
    final cardBackgroundColor = _getCardBackgroundColor(task.priority);
    final textColor = _getTextColor(cardBackgroundColor);
    final statusIndicatorColor = _getStatusIndicatorColor(task.status);

    // <-- Logic kiểm tra quyền cho các nút action -->
    final bool isUserAdmin = loggedInUser.role == 'admin';
    final bool isTaskCreator = task.createdBy == loggedInUser.id;
    final bool isTaskAssigned = task.assignedTo == loggedInUser.id; // Kiểm tra xem người dùng hiện tại có phải là người được gán không

    // Định nghĩa các quyền dựa trên vai trò và mối quan hệ với task
    // - Admin: có thể chỉnh sửa, xóa, hoàn thành bất kỳ task nào.
    // - Người dùng thường:
    //   - Chỉ có thể chỉnh sửa task do họ tạo HOẶC được gán cho họ.
    //   - Chỉ có thể xóa task do họ tạo HOẶC được gán cho họ. <-- ĐÃ THAY ĐỔI
    //   - Chỉ có thể hoàn thành task do họ tạo HOẶC được gán cho họ.

    final bool canEdit = isUserAdmin || isTaskCreator || isTaskAssigned;
    final bool canDelete = isUserAdmin || isTaskCreator || isTaskAssigned; // Admin HOẶC người tạo HOẶC người được gán có thể xóa
    final bool canComplete = isUserAdmin || isTaskCreator || isTaskAssigned; // Người tạo, người được gán, hoặc admin hoàn thành được

    // In debug log để kiểm tra giá trị các biến quyền
    print('Task "${task.title}" (ID: ${task.id}) - User "${loggedInUser.username}" (ID: ${loggedInUser.id}, Role: ${loggedInUser.role})');
    print('  -> isTaskCreator: $isTaskCreator, isTaskAssigned: $isTaskAssigned');
    print('  -> canEdit: $canEdit, canDelete: $canDelete, canComplete: $canComplete');
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: cardBackgroundColor,
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () async {
          // Truyền loggedInUser khi điều hướng đến TaskDetailScreen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(
                task: task,
                onTaskUpdated: onTaskUpdated,
                loggedInUser: loggedInUser, // Truyền loggedInUser
              ),
            ),
          );
          if (result == true) {
            onTaskUpdated();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng chứa Tiêu đề
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        decoration: task.completed ? TextDecoration.lineThrough : TextDecoration.none,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              // Mô tả công việc
              if (task.description != null && task.description!.isNotEmpty) ...[
                Text(
                  task.description!,
                  style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.9)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
              ],
              // Ngày đến hạn
              Text(
                'Đến hạn: $formattedDueDate',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textColor.withOpacity(0.8)),
              ),
              SizedBox(height: 12),
              // Hàng chứa Trạng thái và các nút tác vụ nhanh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusIndicatorColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.status,
                      style: TextStyle(fontSize: 11, color: statusIndicatorColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Các nút tác vụ nhanh - Bọc trong một Row con
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút đánh dấu hoàn thành/chưa hoàn thành - ÁP DỤNG KIỂM TRA QUYỀN canComplete
                      if (canComplete)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: Icon(
                            task.completed ? Icons.check_circle : Icons.circle_outlined,
                            color: task.completed ? Colors.green.shade800 : Colors.grey.shade600,
                            size: 20,
                          ),
                          onPressed: () async {

                            final updatedTask = task.copyWith(
                              completed: !task.completed,
                              status: task.completed ? 'Cần làm' : 'Hoàn thành',
                              updatedAt: DateTime.now(),
                            );
                            await TaskDatabaseHelper.instance.updateTask(updatedTask);
                            onTaskUpdated();
                          },
                          tooltip: task.completed ? 'Đánh dấu chưa hoàn thành' : 'Đánh dấu hoàn thành',
                        ),
                      SizedBox(width: canComplete ? 8 : 0), // Điều chỉnh khoảng cách nếu nút bị ẩn

                      // Nút chỉnh sửa - ÁP DỤNG KIỂM TRA QUYỀN canEdit
                      if (canEdit)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: Icon(Icons.edit, color: Colors.blue.shade800, size: 20),
                          onPressed: () async {
                            // Logic điều hướng đến TaskForm (giữ nguyên)
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskForm(
                                  task: task,
                                  loggedInUser: loggedInUser, // Truyền loggedInUser
                                ),
                              ),
                            );
                            if (result == true) {
                              onTaskUpdated();
                            }
                          },
                          tooltip: 'Chỉnh sửa công việc',
                        ),
                      SizedBox(width: canEdit ? 8 : 0), // Điều chỉnh khoảng cách nếu nút bị ẩn

                      // Nút xóa - ÁP DỤNG KIỂM TRA QUYỀN canDelete
                      if (canDelete)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: Icon(Icons.delete, color: Colors.red.shade800, size: 20),
                          onPressed: () async {
                            // Logic xóa task (giữ nguyên)
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

                            if (confirmDelete == true && task.id != null) {
                              await TaskDatabaseHelper.instance.deleteTask(task.id!);
                              onTaskUpdated();
                            }
                          },
                          tooltip: 'Xóa công việc',
                        ),

                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
