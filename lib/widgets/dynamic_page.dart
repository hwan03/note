import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/sidebar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_font_picker/flutter_font_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:async';



class DynamicPage extends StatefulWidget {
  final String title;
  final Function(String updatedTitle, String updatedContent)? onUpdate;
  final Function(String newPageName, String? parent)? onAddPage; // 새 콜백 추가
  final VoidCallback? onDelete;


  const DynamicPage({
    required this.title,
    this.onUpdate,
    this.onAddPage,
    this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  _DynamicPageState createState() => _DynamicPageState();
}

class _DynamicPageState extends State<DynamicPage> {
  late Map<String, Map<String, dynamic>> pages={};
  late String _currentTitle; // 로컬 상태 변수 추가
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  late quill.QuillController _quillController;

  bool isEditing = false;
  bool isKeyboardVisible = false;
  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  bool isSidebarOpen = false;
  bool showCalendar = false;
  bool showTodoList = false;
  double textSize = 16.0;
  String selectedFont = 'Roboto';

  final List<Map<String, dynamic>> contentItems = [
    {'type': 'text', 'value': '', 'controller': TextEditingController(), 'focusNode': FocusNode()},
  ];
  int lastNumber = 0;

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Map<String, dynamic>> todoList = [];
  final TextEditingController _todoController = TextEditingController();

  TextStyle defaultStyle = GoogleFonts.roboto(fontSize: 16);
  TextStyle selectedStyle = GoogleFonts.roboto(fontSize: 16);
  TextSelection? _selection;

  final TextEditingController _controller = TextEditingController();

  void applyStyleToSelection() {
    final selection = _controller.selection;

    if (selection.isCollapsed) {
      // 선택된 텍스트가 없으면 스타일을 변경하지 않음
      return;
    }

    final text = _controller.text;

    final beforeSelection = text.substring(0, selection.start);
    final selectedText = text.substring(selection.start, selection.end);
    final afterSelection = text.substring(selection.end);

    setState(() {
      // 선택된 텍스트 스타일 변경
      _controller.text = beforeSelection + selectedText + afterSelection;
      _controller.selection = TextSelection(
        baseOffset: beforeSelection.length,
        extentOffset: beforeSelection.length + selectedText.length,
      );

      selectedStyle = GoogleFonts.getFont(
        selectedFont,
        fontSize: 16,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
      );
    });
  }
  bool isPagesLoaded = false;
  final FocusNode _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _quillController = quill.QuillController.basic();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // 포커스를 벗어났을 때 업데이트
        final newContent = _quillController.document.toPlainText().trim();
        final newTitle = _titleController.text.trim();
        _updatePage(newTitle, newContent);
      }
    });

    _loadPages();
    // QuillController에 리스너 추가 (내용 변경 시 저장)
    _quillController.addListener(() {
      final newContent = _quillController.document.toPlainText().trim();
      _updatePage(_currentTitle, newContent);
    });
  }

  TextStyle getTextStyle() {
    return GoogleFonts.getFont(
      selectedFont,
      fontSize: textSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
    );
  }
  void showFontPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("폰트 선택"),
          content: SizedBox(
            height: 400,
            child: FontPicker(
              initialFontFamily: selectedFont,
              onFontChanged: (newFont) {
                setState(() {
                  selectedFont = newFont.fontFamily ?? 'Roboto';
                  // QuillController에 폰트 스타일 적용
                  _quillController.formatSelection(
                    quill.Attribute.fromKeyValue(
                      'font',
                      selectedFont,
                    ),
                  );
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  void showTextStyleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("텍스트 스타일"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "텍스트 크기",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: textSize,
                min: 10,
                max: 40,
                divisions: 6,
                label: textSize.round().toString(),
                onChanged: (value) {
                  setState(() {
                    textSize = value;
                    // QuillController에 텍스트 크기 적용
                    _quillController.formatSelection(
                      quill.Attribute.fromKeyValue(
                        'size',
                        '${textSize.toInt()}px',
                      ),
                    );
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.format_bold),
                    color: isBold ? Colors.blue : Colors.black,
                    onPressed: () {
                      setState(() {
                        isBold = !isBold;
                        // QuillController에 Bold 스타일 적용
                        _quillController.formatSelection(
                          quill.Attribute.bold,
                        );
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.format_italic),
                    color: isItalic ? Colors.blue : Colors.black,
                    onPressed: () {
                      setState(() {
                        isItalic = !isItalic;
                        // QuillController에 Italic 스타일 적용
                        _quillController.formatSelection(
                          quill.Attribute.italic,
                        );
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.format_underline),
                    color: isUnderline ? Colors.blue : Colors.black,
                    onPressed: () {
                      setState(() {
                        isUnderline = !isUnderline;
                        // QuillController에 Underline 스타일 적용
                        _quillController.formatSelection(
                          quill.Attribute.underline,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }



  Future<void> _loadPages() async {
    final prefs = await SharedPreferences.getInstance();
    final pagesJson = prefs.getString('pages');

    if (pagesJson != null) {
      pages = Map<String, Map<String, dynamic>>.from(
        jsonDecode(pagesJson).map(
              (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
        ),
      );
    } else {
      pages = {widget.title: {'content': '', 'parent': null}};
    }

    // Delta 형식의 문서를 로드하여 Quill 문서로 변환
    final documentJson = prefs.getString(widget.title);
    if (documentJson != null) {
      final documentDelta = quill.Document.fromJson(jsonDecode(documentJson));
      _quillController = quill.QuillController(
        document: documentDelta,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      setState(() {
        _quillController = quill.QuillController.basic();
      });
    }

    // 제목 로드
    setState(() {
      _titleController.text = widget.title;
    });

    setState(() {
      isPagesLoaded = true; // 로드 완료 표시
    });
  }


  Future<void> _savePages() async {
    // 제목이 비어있는 경우 저장하지 않음
    if (!_titleController.text.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final newTitle = _titleController.text.trim();
    final newContent = _quillController.document.toPlainText().trim();

    // 제목이 변경되었을 때
    if (newTitle != _currentTitle) {
      final oldTitle = _currentTitle;

      // 기존 제목 데이터를 새 제목 데이터로 변경
      if (pages.containsKey(oldTitle)) {
        pages[newTitle] = pages.remove(oldTitle)!;
      }
      _currentTitle = newTitle;

      // 이전 제목 데이터를 SharedPreferences에서 제거
      await prefs.remove(oldTitle);
    }

    // 새 데이터 저장
    pages[newTitle]?['content'] = newContent;
    await prefs.setString('pages', jsonEncode(pages));
    await prefs.setString(newTitle, jsonEncode(_quillController.document.toDelta().toJson()));
 }




  Future<void> _updatePage(String newTitle, String newContent) async {
    final prefs = await SharedPreferences.getInstance();

    if (newTitle.isEmpty) return; // 제목이 비어 있으면 저장하지 않음

    if (newTitle != _currentTitle) {
      final oldTitle = _currentTitle;

      // 기존 데이터 업데이트 (맵의 순서를 유지)
      final updatedPages = <String, Map<String, dynamic>>{};
      pages.forEach((key, value) {
        if (key == oldTitle) {
          // 제목이 변경된 경우 새 키로 추가
          updatedPages[newTitle] = {...value, 'content': newContent};
        } else {
          // 기존 키는 그대로 유지
          updatedPages[key] = value;
        }
      });

      // 페이지 데이터 변경을 UI에 반영
      await Future(() {
        setState(() {
          pages = updatedPages;
        });
      });

      _currentTitle = newTitle;

      // SharedPreferences에서 이전 제목 제거
      await prefs.remove(oldTitle);
    } else {
      // 내용만 업데이트
      await Future(() {
        setState(() {
          pages[newTitle]?['content'] = newContent;
        });
      });
    }

    // SharedPreferences에 저장
    await prefs.setString('pages', jsonEncode(pages));
    await prefs.setString(newTitle, jsonEncode(_quillController.document.toDelta().toJson()));

    // 최종 상태 갱신
    setState(() {});
  }






  Future<void> _handleSaveAndExit() async {
    final newTitle = _titleController.text.trim(); // 제목 가져오기
    final newContent = _quillController.document.toPlainText().trim(); // 내용 가져오기

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('변경 사항 저장'),
          content: Text('변경 사항을 저장하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // 저장
              child: Text('예'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // 저장하지 않음
              child: Text('아니요'),
            ),

          ],
        );
      },
    );

    if (result == true) {
      if (newTitle.isNotEmpty) {
        // 제목과 내용을 함께 업데이트
        await _updatePage(newTitle, newContent);

        // JSON 변환 후 출력
        final pagesJson = jsonEncode(pages);
      }

      // 홈 화면으로 이동
      FocusScope.of(context).unfocus(); // 포커스 해제
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadPages();
        Navigator.popUntil(context, (route) => route.isFirst);
      });
    }
  }


  void _deletePage() async {
    final prefs = await SharedPreferences.getInstance();

    void _deleteWithChildren(String pageName) async {
      final prefs = await SharedPreferences.getInstance();

      // 자식 페이지들 찾기
      final children = pages.entries
          .where((entry) => entry.value['parent'] == pageName)
          .map((entry) => entry.key)
          .toList();

      // 자식 페이지들에 대해 재귀적으로 삭제
      for (final child in children) {
        _deleteWithChildren(child); // 자식 페이지 삭제 (재귀)
      }

      // 현재 페이지와 관련된 데이터 삭제
      setState(() {
        pages.forEach((key, value) {
          if (value['parent'] == pageName) {
            value['parent'] = null; // 부모 관계 초기화
          }
        });
        pages.remove(pageName); // 페이지 삭제
      });

      // SharedPreferences에서 삭제
      await prefs.remove(pageName); // 페이지 데이터 제거
      await prefs.remove('${pageName}_parent'); // 부모 관계 제거
      await prefs.setString('pages', jsonEncode(pages)); // 변경된 페이지 데이터 저장
    }


    setState(() {
      _deleteWithChildren(widget.title); // 현재 페이지와 모든 자식 페이지 삭제
    });

    // 삭제 후 남은 페이지 데이터를 SharedPreferences에 다시 저장
    await prefs.setString('pages', jsonEncode(pages));

    // 부모 콜백 호출
    widget.onDelete?.call();

    // 홈 화면으로 이동
    Navigator.popUntil(context, (route) => route.isFirst);
  }



  int _getPageDepth(String pageName) {
    int depth = 0;
    String? currentPage = pageName;

    // 부모를 따라가며 깊이를 계산
    while (currentPage != null && pages[currentPage]?['parent'] != null) {
      depth++;
      currentPage = pages[currentPage]?['parent'];
    }

    return depth;
  }

  void _clearInvalidParents() {
    final orphanedPages = <String>[]; // 삭제될 관계 없는 페이지들을 추적
    setState(() {
      pages.forEach((key, value) {
        if (value['parent'] != null && !pages.containsKey(value['parent'])) {
          orphanedPages.add(key); // 부모가 없는 페이지를 수집
        }
      });

      // 부모가 없는 페이지들의 parent를 제거
      for (final page in orphanedPages) {
        pages[page]?['parent'] = null;
      }
    });
  }

  void _addPage({String? parent}) {
    // 부모 페이지의 깊이 확인
    if (parent != null && _getPageDepth(parent) >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('페이지 깊이는 최대 2단계까지만 생성할 수 있습니다.')),
      );
      return;
    }



    String newPageName;

    // 숫자만 추출하고 정렬
    List<int> pageNumbers = pages.keys
        .where((key) => RegExp(r'^Page (\d+)$').hasMatch(key)) // "Page X" 형식 필터링
        .map((key) => int.parse(RegExp(r'^Page (\d+)$').firstMatch(key)!.group(1)!))
        .toList()
      ..sort();

    // 비어 있는 숫자 찾기
    int newNumber = 1;
    for (int i = 1; i <= pageNumbers.length + 1; i++) {
      if (!pageNumbers.contains(i)) {
        newNumber = i;
        break;
      }
    }

    newPageName = 'Page $newNumber';
// 페이지 생성 전 기존 parent 관계 초기화
    _clearInvalidParents();
    setState(() {
      pages[newPageName] = {'content': '', 'parent': parent};
    });

    // onAddPage 콜백 호출
    widget.onAddPage?.call(newPageName, parent);

    _savePages();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicPage(
          title: newPageName,
          onUpdate: (updatedTitle, updatedContent) async{
              if (updatedTitle != newPageName) {
                pages[updatedTitle] = pages.remove(newPageName)!;
              }
              pages[updatedTitle]?['content'] = updatedContent;
            await _savePages();
          },
          onDelete: () async{
              pages.remove(newPageName);
            await _savePages();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _navigateToPage(String pageName) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTitle = _titleController.text.trim();
    final currentContent = _quillController.document.toPlainText().trim();

    // 현재 페이지 상태 저장
    await _updatePage(currentTitle, currentContent);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicPage(
          title: pageName,
          onUpdate: (updatedTitle, updatedContent) async {
              if (updatedTitle != pageName) {
                final pageData = pages.remove(pageName);
                if (pageData != null) {
                  pageData['content'] = updatedContent;
                  pages = {updatedTitle: pageData, ...pages};
                }
              } else {
                pages[pageName]?['content'] = updatedContent;
              }
            await _savePages();
          },
          onDelete: () async {
            pages.remove(pageName);
            await _savePages();
            Navigator.pop(context);
          },
        ),
      ),
    ).then((_) async{
      _loadPages(); // 상태 재동기화
    });
  }


// 클래스 내부
  Timer? _debounce; // Debounce용 Timer
  Timer? _content_debounce;
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  Widget buildChecklist() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          itemCount: contentItems.length,
          itemBuilder: (context, index) {
            final item = contentItems[index];
            if (item['type'] == 'checklist') {
              return Row(
                children: [
                  Checkbox(
                    value: item['checked'],
                    onChanged: (value) {
                      setState(() {
                        item['checked'] = value!;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: item['controller'],
                      decoration: InputDecoration(hintText: '항목 입력'),
                      onChanged: (text) {
                        setState(() {
                          item['value'] = text;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => removeChecklistItem(index),
                  ),
                ],
              );
            }
            return Container();
          },
        ),
        ElevatedButton(
          onPressed: addChecklistItem,
          child: Text('체크리스트 추가'),
        ),
      ],
    );
  }

  void applyBulletPoint() {
    _quillController.formatSelection(quill.Attribute.ul);
  }

  void applyNumberedList() {
    _quillController.formatSelection(quill.Attribute.ol);
  }

  void insertCalendar() {
    final embedJson = {
      'insert': {'embed': 'calendar'}
    };
    final offset = _quillController.selection.baseOffset;
    _quillController.document.insert(offset, jsonEncode(embedJson));
  }

  void insertTodoList() {
    final embedJson = {
      'insert': {'embed': 'todo'}
    };
    final offset = _quillController.selection.baseOffset;
    _quillController.document.insert(offset, jsonEncode(embedJson));
  }
  /// 캘린더 Embed 렌더러
  Widget calendarEmbedBuilder(BuildContext context, quill.Embed embed, bool readOnly) {
    if (embed.value == 'calendar') {
      return TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: DateTime.now(),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return SizedBox.shrink(); // 기본값: 빈 위젯 반환
  }


  Widget customEmbedBuilder(BuildContext context, quill.Embed embed, bool readOnly) {
    if (embed.value == 'calendar') {
      return TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: DateTime.now(),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      );
    } else if (embed.value == 'todo') {
      return Column(
        children: [
          CheckboxListTile(
            title: Text('할 일 항목 1'),
            value: false,
            onChanged: readOnly ? null : (value) {},
          ),
          CheckboxListTile(
            title: Text('할 일 항목 2'),
            value: true,
            onChanged: readOnly ? null : (value) {},
          ),
        ],
      );
    }
    return Container(); // 기본값
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

  void insertBulletPoint() {
    final selection = _quillController.selection;

    // 선택된 텍스트에 Bullet 스타일 추가
    if (!selection.isCollapsed) {
      _quillController.formatSelection(quill.Attribute.ul);
    } else {
      final index = selection.baseOffset;
      _quillController.document.insert(index, '\n• '); // Bullet Point 추가
      _quillController.updateSelection(
        TextSelection.collapsed(offset: index + 2),
        quill.ChangeSource.local,
      );
    }
  }



  void insertNumberedList() {
    final selection = _quillController.selection;

    // 선택된 텍스트에 Numbered 스타일 추가
    if (!selection.isCollapsed) {
      _quillController.formatSelection(quill.Attribute.ol);
    } else {
      final index = selection.baseOffset;
      _quillController.document.insert(index, '\n1. '); // Numbered List 추가
      _quillController.updateSelection(
        TextSelection.collapsed(offset: index + 3),
        quill.ChangeSource.local,
      );
    }
  }

  void alignLeft() {
    _quillController.formatSelection(quill.Attribute.leftAlignment);
  }

  void alignCenter() {
    _quillController.formatSelection(quill.Attribute.centerAlignment);
  }

  void alignRight() {
    _quillController.formatSelection(quill.Attribute.rightAlignment);
  }

  void alignJustify() {
    _quillController.formatSelection(quill.Attribute.justifyAlignment);
  }

  final List<int> fontSizes = [12, 14, 16, 18, 20, 24, 30, 36];

  void changeTextSize(int size) {
    setState(() {
      textSize = size.toDouble();

      if (!_quillController.selection.isCollapsed) {
        _quillController.formatSelection(
          quill.Attribute.fromKeyValue('size', size.toString()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("텍스트를 선택해주세요.")),
        );
      }
    });
  }

  void showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('텍스트 크기 선택'),
          content: SizedBox(
            width: 300, // 다이얼로그 너비 조정
            height: 250, // 다이얼로그 높이 조정
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: fontSizes.length,
              itemBuilder: (BuildContext context, int index) {
                final size = fontSizes[index];
                return ListTile(
                  title: Text(
                    '$size px',
                    style: TextStyle(fontSize: size.toDouble()),
                  ),
                  onTap: () {
                    changeTextSize(size);
                    Navigator.of(context).pop(); // 선택 후 다이얼로그 닫기
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('취소'),
            ),
          ],
        );
      },
    );
  }


  void toggleCustomKeyboard() {
    setState(() {
      isKeyboardVisible = !isKeyboardVisible;
    });
  }



  void _applyStyle(quill.Attribute attribute) {
    final selection = _quillController.selection;
    if (selection.isCollapsed) {
      // 선택된 텍스트가 없으면 스타일을 추가하거나 제거하지 않음
      return;
    }

    if (_quillController.getSelectionStyle().containsKey(attribute.key)) {
      _quillController.formatSelection(quill.Attribute.clone(attribute, null));
    } else {
      _quillController.formatSelection(attribute);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isPagesLoaded) {
      return Center(child: CircularProgressIndicator()); // 로딩 화면 표시
    }
    return GestureDetector(
      onTap: () {
        // 화면의 아무 곳이나 클릭하면 저장
        FocusScope.of(context).unfocus(); // 포커스 해제
        _savePages(); // 변경사항 저장
      },
      child: Scaffold(
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
                      onPressed: _handleSaveAndExit
                  ),
                  backgroundColor: Colors.grey[200],

                  title: TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '제목을 입력하세요',
                    ),
                    style: TextStyle(color: Colors.black, fontSize: 18),
                    onChanged: (newTitle) {
                      if (_debounce?.isActive ?? false) _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        final currentContent = _quillController.document.toPlainText().trim();

                        if (newTitle.isNotEmpty) {
                          // 제목이 변경된 경우 새로운 제목과 현재 내용을 저장
                          _updatePage(newTitle.trim(), currentContent);
                        }
                      });
                    },
                    onSubmitted: (newTitle) {
                      final currentContent = _quillController.document.toPlainText().trim();
                      if (newTitle.isNotEmpty) {
                        // 제목 제출 시 내용도 함께 저장
                        _updatePage(newTitle.trim(), currentContent);
                      }
                    },
                  ),
                ),
                body: Row(
                  children: [
                    // Container (buildRecentPagesBar + QuillEditor)
                    Expanded(
                      flex: 4, // Container가 대부분의 공간을 차지
                      child: Container(
                        color: Colors.white, // 배경색을 흰색으로 설정
                        child: Column(
                          children: [
                            // Recent Pages Bar
                            buildRecentPagesBar(),
                            // Quill Editor
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: quill.QuillEditor(
                                  controller: _quillController,
                                  scrollController: ScrollController(),
                                  focusNode: _focusNode,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // NavigationBar
                    Container(
                      width: 60, // NavigationBar의 고정된 너비
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // NavigationBar 배경색
                        border: Border(
                          left: BorderSide(color: Colors.grey, width: 1), // QuillEditor와 구분하는 경계선
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.center, // NavigationBar의 아이콘을 가운데 정렬
                        child: SingleChildScrollView( // 아이콘이 많을 경우 스크롤 가능하도록 설정
                          child: buildNavigationBar(),
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
    );
  }

  Widget buildRecentPagesBar() {
    final ScrollController _scrollController = ScrollController();

    // 부모-자식 관계를 반영해 페이지를 계층적으로 정렬
    List<Widget> buildPageItems(String? parent, {int depth = 0}) {
      List<Widget> pageItems = [];

      // 현재 부모 아래의 자식들 필터링
      pages.forEach((pageName, pageData) {
        if (pageData['parent'] == parent) {
          final isActive = pageName == _currentTitle;

          pageItems.add(
            GestureDetector(
              onTap: () => _navigateToPage(pageName), // 전체 클릭 가능
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 0.2), // 각 항목 간 여백
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
                    // 깊이에 따라 '>' 기호 추가
                    if (depth > 0)
                      Text(
                        '▶' * depth + ' ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    GestureDetector(
                      onTap: () => _navigateToPage(pageName), // 페이지로 이동
                      child: Text(
                        pageName,
                        style: TextStyle(
                          color: isActive ? Colors.blue : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis, // 말줄임표 처리
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          // 자식 페이지도 재귀적으로 추가
          pageItems.addAll(buildPageItems(pageName, depth: depth + 1));
        }
      });

      return pageItems;
    }

    // 최상위 레벨 페이지(부모가 없는 페이지)부터 시작
    List<Widget> topLevelPages = buildPageItems(null);

    return Container(
      height: 40,
      color: Colors.grey[300],
      child: ListView(
        controller: _scrollController, // 스크롤 제어
        scrollDirection: Axis.horizontal, // 수평 스크롤
        children: topLevelPages,
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
              icon: Icon(Icons.format_bold),
              onPressed: () {
                setState(() {
                  isBold = !isBold;
                  _applyStyle(quill.Attribute.bold);
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.format_italic),
              onPressed: () {
                setState(() {
                  isItalic = !isItalic;
                  _applyStyle(quill.Attribute.italic);
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.format_underline),
              onPressed: () {
                setState(() {
                  isUnderline = !isUnderline;
                  _applyStyle(quill.Attribute.underline);
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.add_circle),
              onPressed: () => _addPage(parent: widget.title),
            ),
            IconButton(
              icon: Icon(Icons.format_align_left),
              onPressed: alignLeft,
            ),
            IconButton(
              icon: Icon(Icons.format_align_center),
              onPressed: alignCenter,
            ),
            IconButton(
              icon: Icon(Icons.format_align_right),
              onPressed: alignRight,
            ),
            IconButton(
              icon: Icon(Icons.format_align_justify),
              onPressed: alignJustify,
            ),
            IconButton(
              icon: Icon(Icons.format_size),
              onPressed: showFontSizeDialog, // 다이얼로그 호출
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
              icon: Icon(Icons.delete),
              onPressed: _deletePage,
            ),
          ],
        ),
      ),
    );
  }
}