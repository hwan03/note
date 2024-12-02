import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DynamicPage extends StatefulWidget {
  final String title;
  final String content;
  final List<String> recentPages; // 최근 페이지 목록
  final Map<String, List<Map<String, String>>> inlinePages;
  final Function(String) navigateToPage;
  final Function(String, String) onUpdate;
  final Function() onDelete;
  final String? parentPage; // 인라인 페이지 여부 확인
  final VoidCallback addNewPage; // 새 페이지 추가 콜백 추가

  DynamicPage({
    required this.title,
    required this.content,
    required this.recentPages,
    required this.inlinePages,
    required this.navigateToPage,
    required this.onUpdate,
    required this.onDelete,
    this.parentPage,
    required this.addNewPage, // 추가된 매개변수
  });

  @override
  _DynamicPageState createState() => _DynamicPageState();
}

class _DynamicPageState extends State<DynamicPage> {
  final List<Map<String, dynamic>> contentItems = [
    {
      'type': 'text',
      'value': '',
      'controller': TextEditingController(),
      'focusNode': FocusNode()
    },
  ];
  int lastNumber = 0;

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

  late List<String> recentPages;
  Map<String, Map<String, dynamic>> pages = {}; // 모든 페이지를 관리
  late Map<String, List<Map<String, String>>> inlinePages; // 내부 변수 선언

  // 텍스트 스타일 적용 함수
  // TextStyle _applyTextStyle() {
  //   return TextStyle(
  //     fontSize: textSize,
  //     fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
  //     fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
  //     decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
  //   );
  // }

  @override
  void initState() {
    super.initState();

    pageTitle = widget.title; // 페이지 제목 초기화
    pageContent = widget.content; // 페이지 내용 초기화
    _titleController.text = pageTitle; // 제목 텍스트 필드
    _contentController.text = pageContent; // 내용 텍스트 필드

    // 페이지 진입 시 사이드바 자동 접기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isSidebarOpen = false;
      });
    });

    inlinePages = Map.from(widget.inlinePages); // 초기화 시 복사
    _loadPages();
  }

  Future<void> _loadPages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPages = prefs.getString('pages');
    final savedInlinePages = prefs.getString('inlinePages'); // Inline Pages 로드

    if (savedPages != null) {
      setState(() {
        pages = Map<String, Map<String, dynamic>>.from(
          json.decode(savedPages).map(
                (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
          ),
        );
        inlinePages = Map<String, List<Map<String, String>>>.from(
          json.decode(savedInlinePages ?? '{}').map(
                (key, value) => MapEntry(key, List<Map<String, String>>.from(value)),
          ),
        ); // 인라인 페이지 로드
        recentPages = prefs.getStringList('recentPages') ?? [];
      });
    } else {
      recentPages = [];
      pages = {};
      inlinePages = {};
    }
  }
  void _updateRecentPages() {
    setState(() {
      recentPages.remove(pageTitle);
      recentPages.insert(0, pageTitle);
      if (recentPages.length > 10) recentPages.removeLast();
      _savePages();
    });
  }
  Future<void> _savePages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pages', json.encode(pages)); // 모든 페이지 데이터 저장
    await prefs.setString('inlinePages', json.encode(inlinePages)); // 인라인 페이지 저장
    await prefs.setStringList('recentPages', recentPages); // 최근 페이지 목록 저장
  }
  void _savePageData() {
    setState(() {
      pages[pageTitle] = {'content': pageContent, 'parent': widget.parentPage};
    });
    _savePages();
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

  void navigateToPage(String pageName) {
    FocusScope.of(context).unfocus();
    setState(() {
      pageTitle = pageName;
      pageContent = pages[pageName]?['content'] ??
          ''; // 데이터 없으면 기본값 처리 _titleController.text = pageTitle;
      _contentController.text = pageContent;
    });
    widget.navigateToPage(pageName);
    _savePageData(); // SharedPreferences에 저장
  }

  void _handleDoubleClick(FocusNode focusNode) {
    // 포커스가 이미 활성화된 상태에서 더블클릭하면 포커스 해제
    if (focusNode.hasFocus) {
      FocusScope.of(context).unfocus();
    } else {
      focusNode.requestFocus();
    }
  }

  void _updatePageContent(String content) {
    setState(() {
      pageContent = content;
    });
    _savePageData();
  }

  void _updatePageTitle(String newTitle) {
    if (newTitle.trim().isEmpty) return;
    setState(() {
      if (newTitle != pageTitle) {
        pages[newTitle] = pages.remove(pageTitle)!;
        pageTitle = newTitle;
      }
    });
    _savePages();
  }

  void _deletePage() {
    setState(() {
      pages.remove(pageTitle);
      recentPages.remove(pageTitle);
    });
    _savePages();
    Navigator.pop(context);
  }

  void _addTextItem() {
    setState(() {
      contentItems.add({
        'type': 'text',
        'controller': TextEditingController(),
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

  void deletePage(String pageName) {
    setState(() {
      widget.recentPages.remove(pageName); // 페이지를 최근 목록에서 삭제
      widget.onDelete(); // 상위 콜백 호출
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
                    decoration:
                        item['completed'] ? TextDecoration.lineThrough : null,
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
      pages[pageTitle]?['content'] = pageContent;
    });

    widget.onUpdate(pageTitle, pageContent);
  }

  /// 글머리 기호(`- `) 추가
  void insertBulletPoint() {
    final int cursorPos = _contentController.selection.base.offset;
    final String oldText = _contentController.text;
    final String newText =
        oldText.substring(0, cursorPos) + '- ' + oldText.substring(cursorPos);

    setState(() {
      _contentController.text = newText;
      _contentController.selection =
          TextSelection.collapsed(offset: cursorPos + 2);
      pageContent = newText;
    });
  }

  /// 개요 번호(`1. `) 추가
  void insertNumberedList() {
    final int cursorPos = _contentController.selection.base.offset;
    final String oldText = _contentController.text;

    lastNumber++;

    final String newText = oldText.substring(0, cursorPos) +
        '$lastNumber. ' +
        oldText.substring(cursorPos);

    setState(() {
      _contentController.text = newText;
      _contentController.selection =
          TextSelection.collapsed(offset: cursorPos + 3);
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
              onPressed: addChecklistItem,
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
              onPressed: isEditing
                  ? saveChanges
                  : () => setState(() => isEditing = true),
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

  void addInlinePage() {
    final inlinePageTitle = 'Inline Page ${(inlinePages[pageTitle]?.length ?? 0) + 1}';

    setState(() {
      inlinePages.putIfAbsent(pageTitle, () => []); // 부모 페이지에 인라인 페이지 초기화
      inlinePages[pageTitle]!.add({'title': inlinePageTitle, 'content': ''}); // 인라인 페이지 추가
    });

    _savePages(); // SharedPreferences에 저장
  }


  void navigateToInlinePage(String pageName) {
    final inlinePage = inlinePages[pageTitle]?.firstWhere(
          (page) => page['title'] == pageName,
      orElse: () => {'title': 'Unknown', 'content': 'No content'},
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicPage(
          title: inlinePage?['title'] ?? '',
          content: inlinePage?['content'] ?? '',
          recentPages: widget.recentPages,
          inlinePages: inlinePages,
          navigateToPage: navigateToInlinePage,
          onUpdate: (newTitle, newContent) {
            setState(() {
              final pageIndex = inlinePages[pageTitle]?.indexWhere((page) => page['title'] == pageName);
              if (pageIndex != null && pageIndex >= 0) {
                inlinePages[pageTitle]![pageIndex] = {'title': newTitle, 'content': newContent};
              }
            });
            _savePages();
          },
          onDelete: () {
            setState(() {
              inlinePages[pageTitle]?.removeWhere((page) => page['title'] == pageName);
            });
            _savePages();
            Navigator.pop(context);
          },
          addNewPage: widget.addNewPage,
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
    final String newText =
        oldText.substring(0, cursorPos) + text + oldText.substring(cursorPos);

    setState(() {
      _contentController.text = newText;
      _contentController.selection =
          TextSelection.collapsed(offset: cursorPos + text.length);
    });
  }

  void deleteText() {
    final int cursorPos = _contentController.selection.base.offset;
    if (cursorPos > 0) {
      final String oldText = _contentController.text;
      final String newText =
          oldText.substring(0, cursorPos - 1) + oldText.substring(cursorPos);

      setState(() {
        _contentController.text = newText;
        _contentController.selection =
            TextSelection.collapsed(offset: cursorPos - 1);
      });
    }
  }

  Widget buildRecentPagesBar() {
    return GestureDetector(
      // 페이지 리스트 영역 클릭 시 포커스 해제
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: 30,
        color: Colors.grey[300],
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.recentPages.length,
          itemBuilder: (context, index) {
            final pageName = widget.recentPages[index];
            return GestureDetector(
                onTap: () {
                  // 현재 포커스 해제 및 데이터 저장
                  FocusScope.of(context).unfocus();

                  // 다른 페이지로 이동
                  setState(() {
                    pageTitle = pageName;
                    pageContent =
                        pages[pageName]?['content'] ?? ''; // 없는 데이터는 공백 처리
                    _titleController.text = pageTitle;
                    _contentController.text = pageContent;
                  });
                  widget.navigateToPage(pageName);
                },
                child: Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 1), // 각 항목 간 여백
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: pageName == pageTitle
                          ? Colors.white
                          : Colors.blue[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                      ),
                      // border: Border.all(color: Colors.blueAccent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            pageName,
                            style: TextStyle(
                              color: pageName == pageTitle
                                  ? Colors.blue
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10, // 텍스트 크기
                            ),
                            overflow: TextOverflow.ellipsis, // 말줄임표 처리
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ));
          },
        ),
      ),
    );
  }

// 페이지 제목을 기반으로 내용을 반환하는 함수
  String _getContentForPage(String pageName) {
    return pageContent = pages[pageName]?['content'] ?? ''; // 없는 데이터는 공백 처리
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
          style: TextStyle(
              color: Colors.blue, decoration: TextDecoration.underline),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return RichText(
        text: TextSpan(style: TextStyle(fontSize: textSize), children: spans));
  }

  Widget buildCustomKeyboard() {
    final List<String> keys = [
      'ㄱ',
      'ㄴ',
      'ㄷ',
      'ㅏ',
      'ㅑ',
      'ㅓ',
      'ㅕ',
      'ㅗ',
      'ㅛ',
      '⌫'
    ];

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
        onTap: () => FocusScope.of(context).unfocus(), // 화면 클릭 시 모든 포커스 해제
        child: Scaffold(
          body: Row(
            children: [
              Sidebar(
                recentPages: widget.recentPages, // 전달
                inlinePages: widget.inlinePages, // 추가된 inlinePages 전달
                navigateToPage: (pageName) {
                  FocusScope.of(context).unfocus(); // 사이드바에서 페이지 이동 시 포커스 해제
                  setState(() {
                    // 페이지 제목과 내용을 갱신
                    pageTitle = pageName;
                    pageContent = pageContent =
                        pages[pageName]?['content'] ?? ''; // 없는 데이터는 공백 처리
                    _titleController.text = pageTitle;
                    _contentController.text = pageContent;
                  });
                  widget.navigateToPage(pageName);
                },
                addNewPage: widget.addNewPage,
              ),
              Expanded(
                child: Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        // 홈으로 이동
                        FocusScope.of(context)
                            .unfocus(); // 앱바에서 뒤로가기 버튼 누르면 포커스 해제
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    ),
                    backgroundColor: Colors.grey[200],
                    bottom: PreferredSize(
                      preferredSize: Size.fromHeight(1),
                      child: Container(
                        color: Colors.grey[300],
                        height: 1,
                      ),
                    ),
                    title: GestureDetector(
                      onTap: () => _handleDoubleClick(_titleFocusNode),
                      // 더블클릭으로 포커스 해제

                      child: TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        onChanged: (value) => _updatePageTitle(value),
                        onEditingComplete: () {
                          // 제목 수정 완료 시 데이터 업데이트
                          FocusScope.of(context).unfocus(); // 포커스 해제
                        },
                        style: TextStyle(color: Colors.black, fontSize: 20),
                        decoration: InputDecoration(
                          hintText: '제목을 입력하세요',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  body: GestureDetector(
                    // 본문 영역에서 다른 곳 클릭 시 포커스 해제
                    onTap: () => FocusScope.of(context).unfocus(),
                    // 다른 영역 클릭 시 모든 포커스 해제
                    child: Column(
                      children: [
                        buildRecentPagesBar(), // 앱바 아래 최근 페이지 이동 리스트 추가
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleDoubleClick(_contentFocusNode),
                            // 더블클릭으로 포커스 해제
                            child: Stack(
                              children: [
                                Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      if (showCalendar)
                                        Expanded(child: buildCalendar()),
                                      if (showTodoList)
                                        Expanded(child: buildTodoList()),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                              text: widget.content),
                                          focusNode: _contentFocusNode,
                                          // 내용 FocusNode 연결
                                          onChanged: (value) =>
                                              _updatePageContent(value),
                                          onEditingComplete: () {
                                            FocusScope.of(context)
                                                .unfocus(); // 본문 포커스 해제
                                          },
                                          maxLines: null,
                                          style: TextStyle(
                                            fontSize: textSize,
                                            fontWeight: isBold
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontStyle: isItalic
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                            decoration: isUnderline
                                                ? TextDecoration.underline
                                                : TextDecoration.none,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: "내용을 입력하세요",
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                      if (isKeyboardVisible)
                                        buildCustomKeyboard(),
                                    ],
                                  ),
                                ),
                                buildNavigationBar(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
