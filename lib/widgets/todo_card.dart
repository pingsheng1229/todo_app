import 'package:flutter/material.dart';
import '../models/todo.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;

  TodoCard({required this.todo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(todo.title),
        subtitle: Text(todo.description),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            // 刪除事項的邏輯
          },
        ),
        onTap: () {
          // 編輯事項的邏輯
        },
      ),
    );
  }
}
