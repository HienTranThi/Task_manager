import 'dart:convert';

class Task {
  String? id;
  String title;
  String? description;
  String status;
  int priority;
  DateTime? dueDate;
  DateTime createdAt;
  DateTime updatedAt;
  String? assignedTo;
  String createdBy;
  String? category;
  List<String>? attachments;
  bool completed;

  Task({
    this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    required this.createdBy,
    this.category,
    this.attachments,
    required this.completed,
  });

  // Phương thức chuyển đổi đối tượng Task thành Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'category': category,
      'attachments': attachments != null ? attachments!.join(',') : null, // Lưu danh sách dưới dạng chuỗi
      'completed': completed ? 1 : 0, // Lưu bool dưới dạng int (thường dùng trong SQLite)
    };
  }

  // Factory method tạo đối tượng Task từ Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString(),
      title: map['title'],
      description: map['description'],
      status: map['status'],
      priority: map['priority'],
      // Xử lý DateTime có thể null
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      assignedTo: map['assignedTo'],
      createdBy: map['createdBy'],
      category: map['category'],
      attachments: map['attachments'] != null
          ? (map['attachments'] is String
          ? map['attachments'].split(',')
          : List<String>.from(map['attachments']))
          : null,
      // Chuyển đổi int (0 hoặc 1) sang bool
      completed: map['completed'] == 1,
    );
  }

  // Phương thức chuyển đổi đối tượng Task thành chuỗi JSON
  String toJSON() {
    return jsonEncode(toMap());
  }

  // Factory method tạo đối tượng Task từ chuỗi JSON
  factory Task.fromJSON(String json) {
    Map<String, dynamic> map = jsonDecode(json);
    return Task.fromMap(map);
  }

  // Phương thức tạo bản sao (copy) của đối tượng Task
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    int? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedTo,
    String? createdBy,
    String? category,
    List<String>? attachments,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      category: category ?? this.category,
      attachments: attachments ?? this.attachments,
      completed: completed ?? this.completed,
    );
  }

  // Phương thức biểu diễn chuỗi của đối tượng Task
  @override
  String toString() {
    return 'Task{id: $id, title: $title, status: $status, priority: $priority, dueDate: $dueDate, assignedTo: $assignedTo, createdBy: $createdBy, completed: $completed}';
  }
}