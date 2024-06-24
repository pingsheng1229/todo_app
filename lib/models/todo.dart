class Todo {
  String id;
  String title;
  String description;
  DateTime dueDate;
  bool isCompleted;
  bool isPinned;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.isPinned = false,
  });
}
