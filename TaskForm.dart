import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../model/Task.dart';
import '../db/TaskDatabaseHelper.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../model/User.dart';

class TaskForm extends StatefulWidget {
  final Task? task; // Để nhận task khi chỉnh sửa (có thể null nếu là tạo mới)
  final User loggedInUser;

  // CẦN THAY ĐỔI CONSTRUCTOR ĐỂ NHẬN loggedInUser -->
  const TaskForm({Key? key, this.task, required this.loggedInUser}) : super(key: key);

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _assignedToController = TextEditingController();
  int _priority = 1;
  String _status = 'Cần làm';
  DateTime? _dueDate;
  List<String> _attachments = [];
  final TaskDatabaseHelper _dbHelper = TaskDatabaseHelper.instance;
  bool _isLoading = false;

  // Có thể truy cập thông tin người dùng đã đăng nhập qua widget.loggedInUser
  @override
  void initState() {
    super.initState();
    // Lấy thông tin người dùng hiện tại
    final currentUser = widget.loggedInUser;

    // Nếu đang ở chế độ chỉnh sửa (task không null), điền dữ liệu cũ vào form
    if (widget.task != null) {
      final t = widget.task!;
      _titleController.text = t.title;
      _descriptionController.text = t.description ?? '';
      _priority = t.priority;
      _status = t.status;
      _categoryController.text = t.category ?? '';
      _assignedToController.text = t.assignedTo ?? ''; // Điền giá trị assignedTo cũ

      // TODO: Có thể thêm logic kiểm tra quyền chỉnh sửa ngay tại đây
      // Nếu không phải admin và không phải người tạo/người được giao,
      // có thể vô hiệu hóa toàn bộ form hoặc điều hướng về.

      _dueDate = t.dueDate;
      _attachments = t.attachments ?? [];
    } else {
      // Nếu là tạo mới, mặc định người được giao là chính người dùng hiện tại
      // (trừ khi là admin, họ có thể gán cho người khác)
      if (currentUser.role != 'admin') {
        _assignedToController.text = currentUser.id ?? ''; // Mặc định gán cho chính mình nếu không phải admin
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  // Hàm chọn ngày đến hạn (giữ nguyên)
  Future<void> _pickDueDate(BuildContext context) async { /* ... giữ nguyên ... */
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Chọn ngày đến hạn',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  // Hàm chọn file đính kèm (giữ nguyên)
  Future<void> _pickAttachment() async { /* ... giữ nguyên ... */
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      setState(() {
        _attachments.addAll(result.paths.whereType<String>());
      });
    } else {
      // Người dùng hủy chọn file
    }
  }

  // Hàm xóa file đính kèm (giữ nguyên)
  void _removeAttachment(String filePath) { /* ... giữ nguyên ... */
    setState(() {
      _attachments.remove(filePath);
    });
  }


  // Hàm lưu hoặc cập nhật công việc
  void _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng điền đầy đủ thông tin bắt buộc!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final now = DateTime.now();
    final currentUser = widget.loggedInUser;

    // TODO: Kiểm tra quyền chỉnh sửa hoặc tạo mới trước khi gọi DB
    // Nếu là chỉnh sửa: Chỉ cho phép lưu nếu người dùng hiện tại có quyền (admin, người tạo, người được giao)
    // Lấy task cũ để so sánh người tạo/người được giao
    bool canEdit = true; // Mặc định là có quyền, sẽ kiểm tra lại
    if (widget.task != null) {
      final existingTask = await _dbHelper.getTaskById(widget.task!.id!);
      if (existingTask != null) {
        final bool isUserAdmin = currentUser.role == 'admin';
        final bool isTaskCreator = existingTask.createdBy == currentUser.id;
        final bool isTaskAssigned = existingTask.assignedTo == currentUser.id;
        canEdit = isUserAdmin || isTaskCreator || isTaskAssigned;
      } else {
        // Task cũ không tồn tại, coi như không có quyền sửa? Hoặc là lỗi?
        canEdit = false; // Coi là không có quyền
      }
    }


    if (widget.task != null && !canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bạn không có quyền chỉnh sửa công việc này!')));
      setState(() { _isLoading = false; });
      // Có thể không pop() hoặc pop với kết quả false
      return; // Dừng hàm
    }
    String? finalAssignedTo;
    if (currentUser.role == 'admin') {
      // Admin: Lấy giá trị từ trường nhập liệu (có thể gán cho bất kỳ ai)
      finalAssignedTo = _assignedToController.text.isEmpty ? null : _assignedToController.text;
      // TODO: Có thể thêm validation ở đây để kiểm tra xem assignedTo ID có tồn tại không

    } else {
      // Người dùng thường: Chỉ có thể gán cho chính bản thân họ.
      // Bỏ qua giá trị nhập trong TextFormField và gán ID của người dùng hiện tại.
      finalAssignedTo = currentUser.id;
      // Cập nhật controller để UI hiển thị đúng ID của họ sau khi lưu (dù trường bị readOnly)
      // _assignedToController.text = currentUser.id ?? ''; // Không cần thiết nếu trường đã readOnly
    }

    final taskToSave = Task(
      id: widget.task?.id,
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      status: _status,
      priority: _priority,
      dueDate: _dueDate,
      createdAt: widget.task?.createdAt ?? now, // Giữ nguyên thời gian tạo nếu là chỉnh sửa
      updatedAt: now, // Cập nhật thời gian chỉnh sửa
      assignedTo: finalAssignedTo, // <-- Sử dụng giá trị assignedTo đã được xử lý theo quyền
      createdBy: widget.task?.createdBy ?? currentUser.id ?? 'unknown', // Đảm bảo createdBy là ID của người tạo ban đầu hoặc người dùng hiện tại nếu là task mới
      category: _categoryController.text.isEmpty ? null : _categoryController.text,
      attachments: _attachments.isEmpty ? null : _attachments,
      completed: _status == 'Hoàn thành',
    );

    final db = TaskDatabaseHelper.instance;


    if (widget.task == null) {
      // Nếu là tạo mới
      await db.createTask(taskToSave); // taskToSave đã có createdBy và assignedTo đúng
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm công việc mới!')),
      );
    } else {
      // Nếu là chỉnh sửa
      await db.updateTask(taskToSave); // taskToSave đã có assignedTo đúng
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật công việc!')),
      );
    }

    setState(() {
      _isLoading = false;
    });

    Future.delayed(Duration(milliseconds: 500), () {
      Navigator.pop(context, true); // pop với kết quả true để thông báo list refresh
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra vai trò của người dùng hiện tại
    final isUserAdmin = widget.loggedInUser.role == 'admin';

    // TODO: Kiểm tra quyền chỉnh sửa toàn bộ form nếu là chế độ chỉnh sửa task
    // Nếu không có quyền, có thể disable toàn bộ form hoặc chỉ hiển thị dữ liệu (readOnly)
    // Đây là kiểm tra quyền ở UI, khác với kiểm tra quyền khi nhấn nút Save
    // final bool canEditUI = isUserAdmin || (widget.task != null && (widget.task!.createdBy == widget.loggedInUser.id || widget.task!.assignedTo == widget.loggedInUser.id));
    // bool isFormReadOnly = !canEditUI && widget.task != null;


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Thêm công việc' : 'Sửa công việc'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
          // Nút Save chỉ hiển thị nếu người dùng có quyền chỉnh sửa/tạo mới
          // (Logic kiểm tra quyền tạo mới/chỉnh sửa đã thêm ở _saveTask)
          // TODO: Bạn có thể ẩn nút này nếu isFormReadOnly là true
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveTask, // _saveTask sẽ tự kiểm tra quyền lần nữa
              tooltip: 'Lưu công việc',
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFa18cd1),
              Color(0xFFfbc2eb),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight, left: 16, right: 16, bottom: 16),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: EdgeInsets.symmetric(vertical: 20),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  // TODO: Disable Form nếu isFormReadOnly là true
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Trường Tiêu đề (có thể disable nếu isFormReadOnly)
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề công việc',
                          hintText: 'Nhập tiêu đề công việc',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.assignment),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tiêu đề không được bỏ trống';
                          }
                          return null;
                        },
                        // readOnly: isFormReadOnly, // Optional readOnly state
                      ),
                      SizedBox(height: 20),

                      // Trường Mô tả (có thể disable nếu isFormReadOnly)
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          hintText: 'Nhập mô tả công việc (tùy chọn)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        // readOnly: isFormReadOnly, // Optional readOnly state
                      ),
                      SizedBox(height: 20),
                      // Trường Ngày đến hạn (có thể disable onTap nếu isFormReadOnly)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _pickDueDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _dueDate == null
                                      ? 'Chọn ngày đến hạn'
                                      : 'Đến hạn: ${DateFormat('dd/MM/yyyy').format(_dueDate!)}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),

                              Icon(Icons.edit), // Giữ nguyên icon
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Mức độ ưu tiên (có thể disable nếu isFormReadOnly)
                      DropdownButtonFormField<int>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: 'Mức độ ưu tiên',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.priority_high),

                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Thấp')),
                          DropdownMenuItem(value: 2, child: Text('Trung bình')),
                          DropdownMenuItem(value: 3, child: Text('Cao')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _priority = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Vui lòng chọn mức độ ưu tiên';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Trạng thái (có thể disable nếu isFormReadOnly)
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.check_circle_outline),

                        ),
                        items: ['Cần làm', 'Đang tiến hành', 'Hoàn thành']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn trạng thái';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() => _status = value!),
                      ),
                      SizedBox(height: 20),

                      // Danh mục (có thể disable nếu isFormReadOnly)
                      TextFormField(
                        controller: _categoryController,
                        decoration: InputDecoration(
                          labelText: 'Danh mục',
                          hintText: 'Ví dụ: Công việc cá nhân, Dự án A',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Trường "GÁN CHO" - ÁP DỤNG LOGIC PHÂN QUYỀN UI (đã làm trước đó)
                      TextFormField(
                        controller: _assignedToController,
                        decoration: InputDecoration(
                          labelText: 'Gán cho (ID người dùng)',
                          // Thay đổi hint text dựa trên vai trò
                          hintText: isUserAdmin ? 'Nhập ID người dùng' : 'Chỉ có thể gán cho bản thân',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.person_add),
                          // THÊM: Vô hiệu hóa trường nếu không phải admin
                          fillColor: isUserAdmin ? null : Colors.grey.shade200, // Màu nền khác khi disabled
                          filled: !isUserAdmin, // Áp dụng màu nền khi disabled
                        ),
                        // THÊM: Đặt readOnly nếu không phải admin
                        readOnly: !isUserAdmin,
                      ),
                      SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tệp đính kèm:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: Icon(Icons.attach_file),
                        label: Text("Tải lên tệp đính kèm"),
                        onPressed: _pickAttachment,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      SizedBox(height: 10), // Giữ nguyên khoảng cách
                      // ... Hiển thị danh sách tệp đính kèm (nút xóa file có thể ẩn nếu isFormReadOnly)
                      if (_attachments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Chưa có tệp đính kèm nào.', style: TextStyle(fontStyle: FontStyle.italic)),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _attachments.map((file) {
                            String fileName = file.split('/').last;
                            if (fileName.length > 30) {
                              fileName = '${fileName.substring(0, 27)}...';
                            }
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                leading: Icon(Icons.insert_drive_file, color: Theme.of(context).primaryColor),
                                title: Text(fileName, overflow: TextOverflow.ellipsis),
                                // Nút xóa file đính kèm - có thể ẩn nếu isFormReadOnly
                                trailing:
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _removeAttachment(file),
                                  tooltip: 'Xóa tệp đính kèm',
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      SizedBox(height: 20), // Khoảng cách cuối form

                      // Nút Lưu/Cập nhật (đã được thêm vào AppBar)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}