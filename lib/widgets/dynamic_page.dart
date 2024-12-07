import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/sidebar.dart';

class DynamicPage extends StatefulWidget {
  final String title;
  final Function(String updatedTitle, String updatedContent)? onUpdate;
  final VoidCallback? onDelete;


  const DynamicPage({
    required this.title,
    this.onUpdate,
    this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  _DynamicPageState createState() => _DynamicPageState();
}

class _DynamicPageState extends State<DynamicPage> {
  late Map<String, Map<String, dynamic>> pages;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool isEditing = false;
  bool isKeyboardVisible = false;
  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  bool isSidebarOpen = false;
  bool showCalendar = false;
  bool showTodoList = false;
  double textSize = 16.0;

  final List<Map<String, dynamic>> contentItems = [
    {'type': 'text', 'value': '', 'controller': TextEditingController(), 'focusNode': FocusNode()},
  ];
  int lastNumber = 0;

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Map<String, dynamic>> todoList = [];
  final TextEditingController _todoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPages = prefs.getString('pages');

    if (storedPages != null) {
      setState(() {
        pages = Map<String, Map<String, dynamic>>.from(
          jsonDecode(storedPages).map((key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value))),
        );
      });
    } else {
      setState(() {
        pages = {widget.title: {'content': '', 'parent': null}};
      });
    }

    _titleController.text = widget.title;
    _contentController.text = pages[widget.title]?['content'] ?? '';
  }

  Future<void> _savePages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pages', jsonEncode(pages));
  }

  void _updatePage(String newTitle, String newContent) {
    final oldTitle = widget.title;

    setState(() {
      if (newTitle != oldTitle) {
        pages[newTitle] = pages.remove(oldTitle)!;
      }
      pages[newTitle]?['content'] = newContent;
    });

    _savePages();

    // onUpdate 콜백 호출
    widget.onUpdate?.call(newTitle, newContent);
  }

  void _deletePage() {
    setState(() {
      pages.remove(widget.title);
    });

    _savePages();

    // onDelete 콜백 호출
    widget.onDelete?.call();
    Navigator.pop(context);
  }

  void _addPage({String? parent}) {
    final String newPageName = 'Page ${pages.length + 1}';

    setState(() {
      // 새 페이지를 추가하며 부모 정보를 현재 페이지로 설정
      pages[newPageName] = {'content': '', 'parent': parent};
    });

    _savePages(); // 변경 사항 저장

    // 새로 생성된 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicPage(
          title: newPageName,
          onUpdate: (updatedTitle, updatedContent) {
            setState(() {
              if (updatedTitle != newPageName) {
                pages[updatedTitle] = pages.remove(newPageName)!;
              }
              pages[updatedTitle]?['content'] = updatedContent;
            });
            _savePages();
          },
          onDelete: () {
            setState(() {
              pages.remove(newPageName);
            });
            _savePages();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }


  void _navigateToPage(String pageName) {
    // 현재 페이지를 저장하고 새로운 페이지로 이동
    _updatePage(_titleController.text, _contentController.text); // 현재 페이지 저장

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicPage(
          title: pageName,
          onUpdate: (updatedTitle, updatedContent) {
            setState(() {
              if (updatedTitle != pageName) {
                pages[updatedTitle] = pages.remove(pageName)!;
              }
              pages[updatedTitle]?['content'] = updatedContent;
            });
            _savePages(); // 변경 사항 저장
          },
          onDelete: () {
            setState(() {
              pages.remove(pageName);
            });
            _savePages(); // 삭제 후 저장
            Navigator.pop(context);
          },
        ),
      ),
    );
  }


  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addTextField(Offset position) {
    setState(() {
      contentItems.add({
        'type': 'textField',
        'position': position,
      });
    });
  }

  // 체크리스트 추가 메서드
  void addChecklistItem() {
    setState(() {
      contentItems.add({
        'type': 'checklist',
        'value': '',
        'checked': false,
        'controller': TextEditingController(),
        'focusNode': FocusNode(),
      });
    });
  }

  void removeChecklistItem(int index) {
    setState(() {
      contentItems.removeAt(index);
    });
  }

  void addTodoItem() {
    if (_todoController.text.isEmpty) return;
    setState(() {
      todoList.add({'task': _todoController.text, 'completed': false});
      _todoController.clear();
    });
  }

  void toggleTodoItem(int index) {
    setState(() {
      todoList[index]['completed'] = !todoList[index]['completed'];
    });
  }

  void deleteTodoItem(int index) {
    setState(() {
      todoList.removeAt(index);
    });
  }
  Widget buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget buildTodoList() {
    return Column(
      children: [
        TextField(
          controller: _todoController,
          decoration: InputDecoration(
            hintText: '새로운 할 일 추가',
            suffixIcon: IconButton(
              icon: Icon(Icons.add),
              onPressed: addTodoItem,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: todoList.length,
            itemBuilder: (context, index) {
              final item = todoList[index];
              return ListTile(
                leading: Checkbox(
                  value: item['completed'],
                  onChanged: (value) => toggleTodoItem(index),
                ),
                title: Text(
                  item['task'],
                  style: TextStyle(
                    decoration: item['completed'] ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => deleteTodoItem(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void toggleCalendar() {
    setState(() {
      showCalendar = !showCalendar;
      showTodoList = false;
    });
  }

  void toggleTodoList() {
    setState(() {
      showTodoList = !showTodoList;
      showCalendar = false;
    });
  }

  void toggleEditMode() {
    setState(() {
      isEditing = true;
    });
  }

  void insertBulletPoint() {
    final int cursorPos = _contentController.selection.base.offset; // 커서 위치 가져오기
    final String oldText = _contentController.text; // 기존 텍스트 가져오기

    // 새로운 텍스트 생성
    final String newText = oldText.substring(0, cursorPos) + '- ' + oldText.substring(cursorPos);

    setState(() {
      _contentController.text = newText; // 텍스트 업데이트
      _contentController.selection = TextSelection.collapsed(offset: cursorPos + 2); // 커서 위치 이동
    });

    _updatePage(_titleController.text, _contentController.text); // 페이지 데이터 저장
  }

  void insertNumberedList() {
    final int cursorPos = _contentController.selection.base.offset; // 커서 위치 가져오기
    final String oldText = _contentController.text; // 기존 텍스트 가져오기

    lastNumber++; // 번호 증가
    // 새로운 텍스트 생성
    final String newText = oldText.substring(0, cursorPos) + '$lastNumber. ' + oldText.substring(cursorPos);

    setState(() {
      _contentController.text = newText; // 텍스트 업데이트
      _contentController.selection = TextSelection.collapsed(offset: cursorPos + 3); // 커서 위치 이동
    });

    _updatePage(_titleController.text, _contentController.text); // 페이지 데이터 저장
  }


  void toggleBold() {
    setState(() {
      isBold = !isBold;
    });
  }

  void toggleItalic() {
    setState(() {
      isItalic = !isItalic;
    });
  }

  void toggleUnderline() {
    setState(() {
      isUnderline = !isUnderline;
    });
  }

  /// 텍스트 크기 변경 함수
  void changeTextSize(double size) {
    setState(() {
      textSize = size;
    });
  }

  void toggleCustomKeyboard() {
    setState(() {
      isKeyboardVisible = !isKeyboardVisible;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            pages: pages,
            navigateToPage: _navigateToPage,
            addNewPage: () => _addPage(parent: null),
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    // 홈으로 이동
                    FocusScope.of(context).unfocus(); // 앱바에서 뒤로가기 버튼 누르면 포커스 해제
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
                title: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '제목을 입력하세요',
                  ),
                  style: TextStyle(color: Colors.black, fontSize: 18),
                  onSubmitted: (newTitle) {
                    _updatePage(newTitle, _contentController.text);
                  },
                ),
                actions: [
                  IconButton(icon: Icon(Icons.format_bold), onPressed: toggleBold),
                  IconButton(icon: Icon(Icons.format_italic), onPressed: toggleItalic),
                  IconButton(icon: Icon(Icons.format_underline), onPressed: toggleUnderline),
                ],
                backgroundColor: Colors.grey[200],
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Container(
                    color: Colors.grey[300],
                    height: 1,
                  ),
                ),
              ),
              body: Column(
                  children: [
                    buildRecentPagesBar(),
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: '내용을 입력하세요',
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          fontSize: textSize,
                          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                          decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
                        ),
                        onChanged: (value) {
                          _updatePage(_titleController.text, value);
                        },
                      ),
                    ),
                    buildNavigationBar(),
                  ],
                ),

              ),
            ),
        ],
      ),
    );
  }

  Widget buildRecentPagesBar() {
    return Container(
      height: 40,
      color: Colors.grey[300],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pages.keys.length, // pages의 키 개수로 목록 길이 설정
        itemBuilder: (context, index) {
          final pageName = pages.keys.elementAt(index); // pages의 키를 가져옴
          final isActive = pageName == widget.title;

          return Expanded(
              child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1), // 각 항목 간 여백
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.blue[50],
          borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
          ),
          ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _navigateToPage(pageName), // 페이지로 이동
                  child: Text(
                    pageName,
                    style: TextStyle(
                      color: isActive ? Colors.blue : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis, // 말줄임표 처리
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pages.remove(pageName); // X 버튼 눌렀을 때만 삭제
                    });
                    _savePages(); // 상태 저장
                  },
                  child: const Icon(Icons.close, size: 16, color: Colors.black),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }


  Widget buildNavigationBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 60,
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: toggleCalendar,
            ),
            IconButton(
              icon: Icon(Icons.checklist),
              onPressed: addChecklistItem,
            ),
            IconButton(
              icon: Icon(Icons.add_circle),
              onPressed: () => _addPage(parent: widget.title),
            ),
            IconButton(
              icon: Icon(Icons.format_size),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('텍스트 크기 조절'),
                  content: Slider(
                    value: textSize,
                    min: 10,
                    max: 40,
                    divisions: 6,
                    label: textSize.round().toString(),
                    onChanged: changeTextSize,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('확인'),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.format_bold),
              onPressed: toggleBold,
              color: isBold ? Colors.blue : Colors.black,
            ),
            IconButton(
              icon: Icon(Icons.format_italic),
              onPressed: toggleItalic,
              color: isItalic ? Colors.blue : Colors.black,
            ),
            IconButton(
              icon: Icon(Icons.format_underline),
              onPressed: toggleUnderline,
              color: isUnderline ? Colors.blue : Colors.black,
            ),
            IconButton(
              icon: Icon(Icons.format_list_bulleted),
              onPressed: insertBulletPoint,
            ),
            IconButton(
              icon: Icon(Icons.format_list_numbered),
              onPressed: insertNumberedList,
            ),
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit),
              onPressed: isEditing ? _savePages : () => setState(() => isEditing = true),
            ),
            IconButton(
              icon: Icon(Icons.keyboard),
              onPressed: toggleCustomKeyboard,
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }


}



