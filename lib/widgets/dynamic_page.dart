import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/sidebar.dart';

// 페이지별 제목과 내용을 관리하는 맵 추가
Map<String, String> pageData = {
};

class DynamicPage extends StatefulWidget {
  final String title;
  final String content;
  final List<String> recentPages; // 최근 페이지 목록

  final Function(String) navigateToPage;
  final Function(String, String) onUpdate; // 페이지 업데이트 함수
  final Function() onDelete; // 페이지 삭제 함수
  final VoidCallback addNewPage; // 새 페이지 추가 콜백 추가

  DynamicPage({
    required this.title,
    required this.content,
    required this.recentPages,
    required this.navigateToPage,
    required this.onUpdate,
    required this.onDelete,
    required this.addNewPage, // 추가된 매개변수
  });
  @override
  _DynamicPageState createState() => _DynamicPageState();
}

class _DynamicPageState extends State<DynamicPage> {
  final List<Map<String, dynamic>> contentItems = [
    {'type': 'text', 'value': '', 'controller': TextEditingController(), 'focusNode': FocusNode()},
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

  // 인라인 페이지 데이터 관리
  List<Map<String, String>> inlinePages = [];

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
    // 제목 포커스 해제 시 저장 처리
    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus) {
        _updatePageData();
      }
    });

    // 내용 포커스 해제 시 저장 처리   @@@ 중복 코드 삭제할 것
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

  void _handleDoubleClick(FocusNode focusNode) {
    // 포커스가 이미 활성화된 상태에서 더블클릭하면 포커스 해제
    if (focusNode.hasFocus) {
      FocusScope.of(context).unfocus();
    } else {
      focusNode.requestFocus();
    }
  }

  void _updatePageData() {
    if (pageTitle.trim().isNotEmpty) {
      setState(() {
        // 제목 변경 시 기존 데이터 갱신
        if (widget.title != pageTitle) {
          final existingContent = pageData.remove(widget.title); // 기존 제목 데이터 제거
          pageData[pageTitle] = existingContent ?? pageContent; // 새 제목으로 데이터 이동

          // recentPages에서도 제목 변경
          final pageIndex = widget.recentPages.indexOf(widget.title);
          if (pageIndex != -1) {
            widget.recentPages[pageIndex] = pageTitle;
          }
        } else {
          // 제목이 같으면 내용만 업데이트
          pageData[pageTitle] = pageContent;
        }
      });
      widget.onUpdate(pageTitle, pageContent); // 데이터 저장
    }
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

    lastNumber++;

    final String newText = oldText.substring(0, cursorPos) + '$lastNumber. ' + oldText.substring(cursorPos);

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
          navigateToPage: (pageName) {
            // 페이지 이동 처리
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DynamicPage(
                  title: pageName,
                  content: pageData[pageName] ?? '내용 없음',
                  recentPages: widget.recentPages,
                  navigateToPage: widget.navigateToPage,
                  onUpdate: widget.onUpdate,
                  onDelete: widget.onDelete,
                  addNewPage: widget.addNewPage,
                ),
              ),
            );
          },
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
          addNewPage: widget.addNewPage, // 필수 매개변수 전달
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
    return GestureDetector(
      // 페이지 리스트 영역 클릭 시 포커스 해제
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child:Container(
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
                  _updatePageData(); // 현재 페이지 데이터 저장

                  // 다른 페이지로 이동
                  setState(() {
                    pageTitle = pageName;
                    pageContent = pageData[pageName] ?? ''; // 없는 데이터는 공백 처리
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
                      color: pageName == pageTitle ? Colors.white : Colors.blue[50],
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
                              color: pageName == pageTitle ? Colors.blue : Colors.black,
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
                )
            );
          },
        ),
      ),
    );
  }
// 페이지 제목을 기반으로 내용을 반환하는 함수
  String _getContentForPage(String pageName) {
    return pageData[pageName]!;
  }

  Widget buildContent() {
    TextStyle textStyle = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
    );

    return SingleChildScrollView(
      child: Text(
        _contentController.text,
        style: textStyle,
      ),
    );
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

  // Widget _buildContentItem(Map<String, dynamic> item, int index) {
  //   if (item['type'] == 'text') {
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 4.0),
  //       child: TextField(
  //         controller: item['controller'],
  //         decoration: InputDecoration(
  //           hintText: '텍스트를 입력하세요',
  //           border: InputBorder.none,
  //         ),
  //         onEditingComplete: () {
  //           setState(() {
  //             FocusScope.of(context).unfocus();
  //           });
  //         },
  //       ),
  //     );
  //   } else if (item['type'] == 'checklist') {
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 4.0),
  //       child: Row(
  //         children: [
  //           Checkbox(
  //             value: item['isChecked'],
  //             onChanged: (value) {
  //               setState(() {
  //                 item['isChecked'] = value!;
  //               });
  //             },
  //           ),
  //           Expanded(
  //             child: TextField(
  //               controller: item['controller'],
  //               decoration: InputDecoration(
  //                 hintText: '체크리스트 항목을 입력하세요',
  //                 border: InputBorder.none,
  //               ),
  //               onEditingComplete: () {
  //                 setState(() {
  //                   FocusScope.of(context).unfocus();
  //                 });
  //               },
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  //   return SizedBox.shrink();
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 화면 아무 곳이나 터치하면 포커스 해제
        onTap: () => FocusScope.of(context).unfocus(), // 화면 클릭 시 모든 포커스 해제
        child :Scaffold(
          body: Row(
            children: [
              Sidebar(
                recentPages: widget.recentPages, // 전달
                navigateToPage:(pageName) {
                  FocusScope.of(context).unfocus(); // 사이드바에서 페이지 이동 시 포커스 해제
                  setState(() {
                    // 페이지 제목과 내용을 갱신
                    pageTitle = pageName;
                    pageContent = pageData[pageName] ?? '';
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
                        FocusScope.of(context).unfocus(); // 앱바에서 뒤로가기 버튼 누르면 포커스 해제
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
                      onTap: () => _handleDoubleClick(_titleFocusNode), // 더블클릭으로 포커스 해제

                      child: TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        onChanged: (value) {
                          setState(() {
                            pageTitle = value;
                          });
                        },
                        onEditingComplete: () {
                          _updatePageData(); // 제목 수정 완료 시 데이터 업데이트
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
                  body: Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          // 본문 영역에서 다른 곳 클릭 시 포커스 해제
                          onTap: () {
                            // FocusScope.of(context).unfocus(); // 모든 포커스 해제
                            _addTextItem(); // 클릭 시 기본적으로 텍스트 추가
                          }, // 다른 영역 클릭 시 모든 포커스 해제
                          child: Column(
                            children: [
                              buildRecentPagesBar(), // 앱바 아래 최근 페이지 이동 리스트 추가
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _handleDoubleClick(_contentFocusNode), // 더블클릭으로 포커스 해제
                                  child: Stack(
                                    children: [
                                      Container(
                                        color: Colors.white,
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          children: [
                                            if (showCalendar) Expanded(child: buildCalendar()),
                                            if (showTodoList) Expanded(child: buildTodoList()),
                                            Expanded(
                                              child: ListView.builder(
                                                itemCount: contentItems.length, // contentItems는 텍스트와 체크리스트를 관리하는 리스트
                                                itemBuilder: (context, index) {
                                                  final item = contentItems[index];
                                                  if (item['type'] == 'text') {
                                                    // 텍스트 항목
                                                    return TextField(
                                                      controller: item['controller'],
                                                      focusNode: item['focusNode'],
                                                      onChanged: (value) {
                                                        setState(() {
                                                          item['value'] = value;
                                                        });
                                                      },
                                                      onEditingComplete: () {
                                                        _updatePageData(); // 텍스트 편집 완료 시 데이터 업데이트
                                                        FocusScope.of(context).unfocus();
                                                      },
                                                      maxLines: null,
                                                      style: TextStyle(
                                                        fontSize: textSize,
                                                        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                                                        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                                                        decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
                                                      ),
                                                      decoration: InputDecoration(
                                                        hintText: "내용을 입력하세요",
                                                        border: InputBorder.none,
                                                      ),
                                                    );
                                                  } else if (item['type'] == 'checklist') {
                                                    // 체크리스트 항목
                                                    return Row(
                                                      children: [
                                                        Checkbox(
                                                          value: item['checked'],
                                                          onChanged: (value) {
                                                            setState(() {
                                                              item['checked'] = value;
                                                            });
                                                          },
                                                        ),
                                                        Expanded(
                                                          child: TextField(
                                                            controller: item['controller'],
                                                            focusNode: item['focusNode'],
                                                            onChanged: (value) {
                                                              setState(() {
                                                                item['value'] = value;
                                                              });
                                                            },
                                                            onEditingComplete: () {
                                                              _updatePageData();
                                                              FocusScope.of(context).unfocus();
                                                            },
                                                            maxLines: 1,
                                                            decoration: InputDecoration(
                                                              hintText: "항목 입력",
                                                              border: InputBorder.none,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }
                                                  return Container(); // 기타 항목은 빈 컨테이너
                                                },
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
                              ),
                            ],
                          ),
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