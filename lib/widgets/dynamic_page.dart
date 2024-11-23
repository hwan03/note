import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/sidebar.dart';
// 페이지별 제목과 내용을 관리하는 맵 추가
Map<String, String> pageData = {
  "Page 1": "이것은 페이지 1의 초기 내용입니다.",
  "Page 2": "이것은 페이지 2의 초기 내용입니다.",
  "Page 3": "이것은 페이지 3의 초기 내용입니다.",
};

class DynamicPage extends StatefulWidget {
  final String title;
  final String content;
  final List<String> recentPages; // 최근 페이지 목록
  final Function(String, String) onUpdate;
  final Function() onDelete;

  DynamicPage({
    required this.title,
    required this.content,
    required this.recentPages,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  _DynamicPageState createState() => _DynamicPageState();
}

class _DynamicPageState extends State<DynamicPage> {
  bool isEditing = false;
  bool isKeyboardVisible = false;
  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  bool isSidebarOpen = false;
  bool showCalendar = false;
  bool showTodoList = false;
  double textSize = 16.0;
  late String pageTitle;
  late String pageContent;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode(); // 제목 입력 필드에 포커스 관리 추가
  final FocusNode _contentFocusNode = FocusNode();

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Map<String, dynamic>> todoList = [];
  final TextEditingController _todoController = TextEditingController();



  // 인라인 페이지 데이터 관리
  List<Map<String, String>> inlinePages = [];

  @override
  void initState() {
    super.initState();
    // 제목 포커스 해제 시 저장 처리
    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus) {
        _updatePageData();
      }
    });

    // 내용 포커스 해제 시 저장 처리
    _contentFocusNode.addListener(() {
      if (!_contentFocusNode.hasFocus) {
        _updatePageData();
      }
    });
    // 내용 포커스 해제 시 저장
    _contentFocusNode.addListener(() {
      if (!_contentFocusNode.hasFocus) {
        widget.onUpdate(pageTitle, pageContent);
      }
    });
    pageTitle = widget.title;
    pageContent = widget.content;
    _titleController.text = pageTitle;
    _contentController.text = pageContent;

    // 페이지 진입 시 사이드바 자동 접기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isSidebarOpen = false;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose(); // FocusNode 정리
    _contentFocusNode.dispose();
    _todoController.dispose();
    super.dispose();
  }
  void _updatePageData() {
    if (pageTitle.trim().isNotEmpty) {
      setState(() {
        pageData[pageTitle] = pageContent; // 제목과 내용 저장
      });
      widget.onUpdate(pageTitle, pageContent); // 기존 onUpdate 호출
     }
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

  void saveChanges() {
    if (pageTitle.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("제목을 입력하세요!")),
      );
      return;
    }

    setState(() {
      // 기존 제목이 있으면 내용만 업데이트, 없으면 새 항목 추가
      pageData[pageTitle] = pageContent;
});

    widget.onUpdate(pageTitle, pageContent);
  }



  /// 글머리 기호(`- `) 추가
  void insertBulletPoint() {
    final int cursorPos = _contentController.selection.base.offset;
    final String oldText = _contentController.text;
    final String newText = oldText.substring(0, cursorPos) + '- ' + oldText.substring(cursorPos);

    setState(() {
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: cursorPos + 2);
      pageContent = newText;
    });
  }

  /// 개요 번호(`1. `) 추가
  void insertNumberedList() {
    final int cursorPos = _contentController.selection.base.offset;
    final String oldText = _contentController.text;
    final String newText = oldText.substring(0, cursorPos) + '1. ' + oldText.substring(cursorPos);

    setState(() {
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: cursorPos + 3);
      pageContent = newText;
    });
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
              onPressed: toggleTodoList,
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: addInlinePage,
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
              onPressed: isEditing ? saveChanges : () => setState(() => isEditing = true),
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

  /// 인라인 페이지 추가 기능
  void addInlinePage() {
    final int cursorPos = _contentController.selection.base.offset;
    final String oldText = _contentController.text;
    final String newPageTitle = 'Inline Page ${inlinePages.length + 1}';

    inlinePages.add({'title': newPageTitle, 'content': ''});

    final String newText = oldText.substring(0, cursorPos) + '[$newPageTitle]\n' + oldText.substring(cursorPos);

    setState(() {
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: cursorPos + newPageTitle.length + 3);
      pageContent = newText;
    });
  }
  void navigateToInlinePage(String title) {
    final pageData = inlinePages.firstWhere((page) => page['title'] == title);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicPage(
          title: pageData['title']!, // 해당 인라인 페이지 제목
          content: pageData['content']!, // 해당 인라인 페이지 내용
          recentPages: inlinePages.map((page) => page['title']!).toList(), // 인라인 페이지들의 제목 리스트 전달
          onUpdate: (newTitle, newContent) {
            setState(() {
              pageData['title'] = newTitle;
              pageData['content'] = newContent;
            });
          },
          onDelete: () {
            setState(() {
              inlinePages.remove(pageData);
              Navigator.pop(context);
            });
          },
        ),
      ),
    );
  }

  void toggleCustomKeyboard() {
    setState(() {
      isKeyboardVisible = !isKeyboardVisible;
    });
  }

  void insertText(String text) {
    final int cursorPos = _contentController.selection.base.offset;
    final String oldText = _contentController.text;
    final String newText = oldText.substring(0, cursorPos) + text + oldText.substring(cursorPos);

    setState(() {
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: cursorPos + text.length);
    });
  }

  void deleteText() {
    final int cursorPos = _contentController.selection.base.offset;
    if (cursorPos > 0) {
      final String oldText = _contentController.text;
      final String newText = oldText.substring(0, cursorPos - 1) + oldText.substring(cursorPos);

      setState(() {
        _contentController.text = newText;
        _contentController.selection = TextSelection.collapsed(offset: cursorPos - 1);
      });
    }
  }
  Widget buildRecentPagesBar() {
    return Container(
      height: 50,
      color: Colors.grey[300],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.recentPages.length,
        itemBuilder: (context, index) {
          final pageName = widget.recentPages[index];
          return GestureDetector(
            onTap: () {
              if (pageName != pageTitle) {
                // 현재 페이지 데이터 저장
                saveChanges();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DynamicPage(
                      title: pageName,
                      content: _getContentForPage(pageName),
                      recentPages: widget.recentPages,
                      onUpdate: (newTitle, newContent) {
                        if (mounted) {
                          setState(() {
                            pageData[newTitle] = newContent;
                          });
                        }
                      },
                      onDelete: () {
                        if (mounted) {
                          setState(() {
                            pageData.remove(pageName);
                            Navigator.pop(context);
                          });
                        }
                      },
                    ),
                  ),
                ).then((_) {
                  // 이동 후 현재 상태 업데이트
                  if (!mounted) return;
                  setState(() {
                    pageTitle = pageName;
                    pageContent = _getContentForPage(pageName);
                    _titleController.text = pageTitle;
                    _contentController.text = pageContent;
                   });
                });
              }
            }
            ,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pageName == pageTitle ? Colors.blue[50] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Text(
                pageName,
                style: TextStyle(
                  color: pageName == pageTitle ? Colors.blue : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
// 페이지 제목을 기반으로 내용을 반환하는 함수
  String _getContentForPage(String pageName) {
    return pageData[pageName]!;
  }





  Widget buildContent() {
    final text = _contentController.text;
    final regex = RegExp(r'\[(Inline Page \d+)\]');
    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final pageTitle = match.group(1)!;
      spans.add(
        TextSpan(
          text: pageTitle,
          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return RichText(text: TextSpan(style: TextStyle(fontSize: textSize), children: spans));
  }

  Widget buildCustomKeyboard() {
    final List<String> keys = ['ㄱ', 'ㄴ', 'ㄷ', 'ㅏ', 'ㅑ', 'ㅓ', 'ㅕ', 'ㅗ', 'ㅛ', '⌫'];

    return Container(
      color: Colors.grey[300],
      padding: EdgeInsets.all(10),
      child: GridView.count(
        crossAxisCount: 5,
        childAspectRatio: 2,
        shrinkWrap: true,
        children: keys.map((key) {
          return ElevatedButton(
            onPressed: key == '⌫' ? deleteText : () => insertText(key),
            child: Text(key),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        // 화면 아무 곳이나 터치하면 포커스 해제
        onTap: () {
      FocusScope.of(context).unfocus(); // 모든 FocusNode 해제
    },
    behavior: HitTestBehavior.opaque, // 투명 영역도 터치 이벤트 감지
    child :Scaffold(
      body: Row(
        children: [
          Sidebar(),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.grey[200],
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Container(
                    color: Colors.grey[300],
                    height: 1,
                  ),
                ),
                title: TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode, // FocusNode 연결
                  onChanged: (value) {
                    setState(() {
                      pageTitle = value;
                    });
                  },
                  style: TextStyle(color: Colors.black, fontSize: 20),
                  decoration: InputDecoration(
                    hintText: '제목을 입력하세요',
                    border: InputBorder.none,
                  ),
                ),
              ),
              body: Column(
                children: [
                  buildRecentPagesBar(), // 앱바 아래 최근 페이지 이동 리스트 추가
                  Expanded(
                    child : Stack(
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (showCalendar) Expanded(child: buildCalendar()),
                              if (showTodoList) Expanded(child: buildTodoList()),
                              Expanded(
                                child: TextField(
                                  controller: _contentController,
                                  focusNode: _contentFocusNode, // 내용 FocusNode 연결
                                  onChanged: (value) {
                                    setState(() {
                                      pageContent = value; // 내용 상태 업데이트
                                    });
                                  },
                                  maxLines: null,
                                  style: TextStyle(fontSize: textSize),
                                  decoration: InputDecoration(
                                    hintText: "내용을 입력하세요",
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),

                              if (isKeyboardVisible) buildCustomKeyboard(),
                            ],
                          ),
                        ),
                        buildNavigationBar(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
    );
  }
}