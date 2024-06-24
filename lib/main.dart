import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeData _themeData;

  ThemeNotifier(this._themeData);

  ThemeData getTheme() => _themeData;

  void setTheme(ThemeData themeData) async {
    _themeData = themeData;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _themeData == ThemeData.dark());
  }
}

void main() {
  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(ThemeData.light()),
      child: const TodoApp(),
    ),
  );
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeNotifier themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'Todo List',
      theme: themeNotifier.getTheme(),
      home: const TodoList(),
    );
  }
}
class TodoSearchDelegate extends SearchDelegate<String> {
  final List<String> todoItems;

  TodoSearchDelegate(this.todoItems);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = todoItems.where((item) => item.contains(query)).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index]),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? todoItems
        : todoItems.where((item) => item.contains(query)).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  TodoListState createState() => TodoListState();
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeNotifier themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Settings Page',
              style: TextStyle(fontSize: 20),
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: themeNotifier.getTheme() == ThemeData.dark(),
              onChanged: (value) {
                themeNotifier.setTheme(value ? ThemeData.dark() : ThemeData.light());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TodoListState extends State<TodoList> {
  final List<String> _todoItems = [];
  late SharedPreferences _prefs;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _textEditingController = TextEditingController();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    List<String>? savedItems = _prefs.getStringList('todoItems');
    if (savedItems != null) {
      setState(() {
        _todoItems.addAll(savedItems);
      });
    }
  }

  void _saveItems() {
    _prefs.setStringList('todoItems', _todoItems);
  }

  void _addTodoItem(String task, DateTime dueDate, Duration reminder) {
    if (task.isNotEmpty) {
      final currentTime = DateTime.now();
      final timestamp = currentTime.toIso8601String();
      final dueDateString = dueDate.toIso8601String();
      final reminderString = reminder.inMinutes.toString();
      final todoItem = '$task - $timestamp - $dueDateString - $reminderString';

      setState(() {
        _todoItems.add(todoItem);
        _saveItems();
      });
    }
  }

  void _editTodoItem(int index, String newTask, DateTime newDueDate, Duration reminder) {
    final item = _todoItems[index];
    final parts = item.split(' - ');
    if (parts.length >= 4) {
      final timestamp = parts[1];
      final updatedItem = '$newTask - $timestamp - ${newDueDate.toIso8601String()} - ${reminder.inMinutes.toString()}';
      setState(() {
        _todoItems[index] = updatedItem;
        _saveItems();
      });
    }
  }

  void _removeTodoItem(int index) {
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _todoItems.removeAt(index);
        _saveItems();
      });
    });
  }

  void _promptAddTodoItem() {
    DateTime? selectedDate;
    Duration reminder = Duration.zero;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textEditingController,
                autofocus: true,
                onSubmitted: (val) {
                  Navigator.of(context).pop();
                  _addTodoItem(val, selectedDate ?? DateTime.now(), reminder);
                  _textEditingController.clear();
                },
              ),
              ListTile(
                title: Text('Due Date: ${selectedDate != null ? selectedDate?.toLocal().toString().substring(0, 16) : 'Select Date'}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (pickedDate != null && pickedTime != null) {
                    setState(() {
                      selectedDate = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  }
                },
              ),
              ListTile(
                title: Text('Reminder: ${reminder.inMinutes} minutes before'),
                trailing: const Icon(Icons.alarm),
                onTap: () async {
                  final pickedDuration = await showDurationPicker(
                    context: context,
                    initialDuration: reminder,
                  );
                  if (pickedDuration != null) {
                    setState(() {
                      reminder = pickedDuration;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                _addTodoItem(_textEditingController.text, selectedDate ?? DateTime.now(), reminder);
                _textEditingController.clear();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _textEditingController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  void _editTodoItemDialog(int index) {
    final item = _todoItems[index];
    final parts = item.split(' - ');
    final taskText = parts.first.replaceFirst('[Completed] ', '');

    DateTime? selectedDate;
    if (parts.length >= 3) {
      selectedDate = DateTime.parse(parts[2]);
    }
    Duration reminder = Duration.zero;
    if (parts.length >= 4) {
      reminder = Duration(minutes: int.parse(parts[3]));
    }

    _textEditingController.text = taskText;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textEditingController,
                autofocus: true,
                onSubmitted: (val) {
                  Navigator.of(context).pop();
                  _editTodoItem(index, val, selectedDate ?? DateTime.now(), reminder);
                  _textEditingController.clear();
                },
              ),
              ListTile(
                title: Text('Due Date: ${selectedDate != null ? selectedDate?.toLocal().toString().substring(0, 16) : 'Select Date'}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (pickedDate != null && pickedTime != null) {
                    setState(() {
                      selectedDate = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  }
                },
              ),
              ListTile(
                title: Text('Reminder: ${reminder.inMinutes} minutes before'),
                trailing: const Icon(Icons.alarm),
                onTap: () async {
                  final pickedDuration = await showDurationPicker(
                    context: context,
                    initialDuration: reminder,
                  );
                  if (pickedDuration != null) {
                    setState(() {
                      reminder = pickedDuration;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                _editTodoItem(index, _textEditingController.text, selectedDate ?? DateTime.now(), reminder);
                Navigator.of(context).pop();
                _textEditingController.clear();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _textEditingController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodoList() {
    return ListView.builder(
      itemCount: _todoItems.length,
      itemBuilder: (context, index) {
        final item = _todoItems[index];
        final parts = item.split(' - ');
        final isCompleted = item.startsWith('[Completed] ');

        final dueDateString = parts.length > 2 ? DateTime.parse(parts[2]).toLocal().toString().substring(0, 16) : 'Unknown';
        final reminderString = parts.length > 3 ? parts[3] : '0';

        return Dismissible(
          key: Key(item),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              _removeTodoItem(index);
            } else if (direction == DismissDirection.startToEnd) {
              setState(() {
                _todoItems[index] = '[Completed] ${item.replaceFirst('[Completed] ', '')}';
                _saveItems();
              });
            }
          },
          background: Container(
            color: Colors.green,
            alignment: Alignment.centerRight,
            child: const Icon(Icons.check),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            child: const Icon(Icons.delete),
          ),
          child: ListTile(
            title: RichText(
              text: TextSpan(
                children: [
                  if (isCompleted)
                    const WidgetSpan(
                      child: Icon(Icons.check, color: Colors.red, size: 20),
                    ),
                  TextSpan(
                    text: isCompleted
                        ? ' ${item.split(' - ').first.replaceFirst('[Completed] ', '')}'
                        : item.split(' - ').first,
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            subtitle: item.contains(' - ')
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created at: ${DateTime.parse(parts[1]).toLocal().toString().substring(0, 16)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Due Date: $dueDateString',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Reminder: $reminderString minutes before',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            )
                : const Text(
              'Created at: Unknown',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              _editTodoItemDialog(index);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _promptAddTodoItem,
          ),
        ],
      ),
      body: _buildTodoList(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Menu'),
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () {
          showSearch(
            context: context,
            delegate: TodoSearchDelegate(_todoItems),
          );
        },
      ),
    );
  }
}

Future<Duration?> showDurationPicker({
  required BuildContext context,
  required Duration initialDuration,
}) async {
  int hours = initialDuration.inHours;
  int minutes = initialDuration.inMinutes % 60;

  return showDialog<Duration>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Select Reminder Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: NumberPicker(
                    minValue: 0,
                    maxValue: 23,
                    value: hours,
                    onChanged: (value) => hours = value,
                  ),
                ),
                const Text('hours'),
                Expanded(
                  child: NumberPicker(
                    minValue: 0,
                    maxValue: 59,
                    value: minutes,
                    onChanged: (value) => minutes = value,
                  ),
                ),
                const Text('minutes'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(Duration(hours: hours, minutes: minutes)),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

class NumberPicker extends StatelessWidget {
  final int minValue;
  final int maxValue;
  final int value;
  final ValueChanged<int> onChanged;

  const NumberPicker({
    required this.minValue,
    required this.maxValue,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 50,
        perspective: 0.003,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            return Center(
              child: Text(
                '$index',
                style: const TextStyle(fontSize: 24),
              ),
            );
          },
          childCount: maxValue - minValue + 1,
        ),
      ),
    );
  }
}
