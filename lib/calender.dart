import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:new_flutter/widgets/sidebar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class CalendarPage extends StatefulWidget {
  final List<String> recentPages;
  final Function(String) navigateToPage;
  final VoidCallback addNewPage;

  const CalendarPage({
    required this.recentPages,
    required this.navigateToPage,
    required this.addNewPage,
    Key? key,
  }) : super(key: key);


  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<String> recentPages = ['Page 1', 'Page 2']; // 더미 데이터
  int pageCounter = 3; // 새 페이지 번호 관리

  void navigateToPage(String pageName) {
    // 페이지 이동 처리
    print('Navigating to $pageName'); // 실제 페이지 이동 로직 대신 로그 출력
    widget.navigateToPage(pageName);
  }

  void addNewPage() {
    // 새 페이지 추가
    setState(() {
      final newPageName = 'Page $pageCounter';
      pageCounter++;
      recentPages.insert(0, newPageName);
    });
    widget.addNewPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tablet Calendar & Schedule',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('ko'),
      // 한국어로 고정
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('ko', ''), // Korean, no country code
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: CalendarScreen(
        recentPages: widget.recentPages, // 전달
        navigateToPage: widget.navigateToPage, // 전달
        addNewPage: widget.addNewPage, // 전달
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final List<String> recentPages;
  final Function(String) navigateToPage;
  final VoidCallback addNewPage;

  const CalendarScreen({
    required this.recentPages,
    required this.navigateToPage,
    required this.addNewPage,
    Key? key,
  }) : super(key: key);
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  DateTime _selectedStartDateTime = DateTime.now();
  DateTime _selectedEndDateTime = DateTime.now();
  int _selectedTagIndex = 0; // 현재 선택된 태그 인덱스
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    DateTime(2024, 11, 11): [
      {"name": "태그 1", "color": Color(0xFFFFC1C1)},
      {"name": "태그 2", "color": Color(0xFFB3D9FF)},
    ],
    DateTime(2024, 11, 12): [
      {"name": "태그 3", "color": Color(0xFFC1FFD7)},
    ],
  };
  final List<Map<String, dynamic>> _tags = [
    {"name": "태그 1", "color": Color(0xFFFFC1C1)},
    {"name": "태그 2", "color": Color(0xFFB3D9FF)},
    {"name": "태그 3", "color": Color(0xFFC1FFD7)},
  ];
  final List<bool> _selectedTags = [false, false, false];

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  Future<void> _showCustomDateTimePicker(
      BuildContext context, bool isStart) async {
    DateTime tempDate = isStart ? _selectedStartDateTime : _selectedEndDateTime;
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFFF5F5F3),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 250,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(color: Colors.black),
              ),
            ),
            child: CupertinoDatePicker(
              backgroundColor: Color(0xFFF5F5F3),
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: tempDate,
              use24hFormat: true,
              onDateTimeChanged: (DateTime newDate) {
                setState(() {
                  if (isStart) {
                    _selectedStartDateTime = newDate;
                  } else {
                    _selectedEndDateTime = newDate;
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDate = DateTime(
        _focusedDate.year,
        _focusedDate.month + offset,
        1,
      );
    });
  }

  void _changeYear(int offset) {
    setState(() {
      _focusedDate = DateTime(
        _focusedDate.year + offset,
        _focusedDate.month,
        1,
      );
    });
  }

  //
  // final List<bool> _selectedTags = [false, false, false];
  //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Sidebar(
            recentPages: widget.recentPages,
            navigateToPage: widget.navigateToPage,
            addNewPage: widget.addNewPage,
          ),
          // Main Content
          // 달력 영역
          Expanded(
            flex: 10, // 메인 컨텐츠 부분의 총 비율 설정
            child: Padding(
              padding: const EdgeInsets.all(16.0), // 달력과 일정 영역에만 간격 추가
              child: Row(
                children: [
                  // 달력 영역
                  Expanded(
                    flex: 5,
                    child: _buildLabeledBox(
                      label: '달력',
                      child: Column(
                        children: [
                          // 새로운 연월 조정 UI
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.chevron_left),
                                    onPressed: () => _changeMonth(-1),
                                  ),
                                  Text(
                                    '${_focusedDate.month}월',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.chevron_right),
                                    onPressed: () => _changeMonth(1),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.chevron_left),
                                    onPressed: () => _changeYear(-1),
                                  ),
                                  Text(
                                    '${_focusedDate.year}년',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.chevron_right),
                                    onPressed: () => _changeYear(1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8), // 버튼과 달력 간 간격
                          Expanded(
                            child: TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDate,
                              selectedDayPredicate: (day) =>
                                  isSameDay(_selectedDate, day),
                              eventLoader: (day) => _events[day] ?? [],
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDate = selectedDay;
                                  _focusedDate = focusedDay;
                                });
                              },
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, date, events) {
                                  if (events.isNotEmpty) {
                                    return Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: events.map((e) {
                                        final tagIndex = _tags.indexWhere(
                                                (tag) => tag['name'] == e);
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 2),
                                          child: _buildColorCircle(
                                              color: _tags[tagIndex]['color']),
                                        );
                                      }).toList(),
                                    );
                                  }
                                  return null;
                                },
                              ),
                              headerVisible: false,
                              rowHeight: 100,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16), // 달력과 일정 영역 간 간격
                  // 일정 작성 영역
                  Expanded(
                    flex: 5,
                    child: _buildLabeledBox(
                      label: '일정',
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 일정 제목
                            Row(
                              children: [
                                _buildColorCircle(color: _tags[0]["color"]),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _titleController,
                                    decoration: InputDecoration(
                                      labelText: '일정 제목',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            // 시작 날짜와 종료 날짜
                            Container(
                              height:100,

                              decoration: BoxDecoration(
                                color: Color(0xFF91918E),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildDateTimePickerField(
                                      context,
                                      selectedDateTime: _selectedStartDateTime,
                                      color: Colors.blue,
                                      isStart: true,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildDateTimePickerField(
                                      context,
                                      color: Color(0xFF91918E),
                                      selectedDateTime: _selectedEndDateTime,
                                      isStart: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            // 태그 리스트
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "일정 태그",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_outlined, color:Colors.black),
                                  onPressed: _tags.length < 5 ? _addTag : null,
                                ),
                              ],
                            ),
                            Column(
                              children: List.generate(_tags.length, (index) {
                                return Row(
                                  children: [
                                    Radio<int>(
                                      value: index, // 현재 라디오 버튼의 값
                                      groupValue: _selectedTagIndex, // 선택된 값
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedTagIndex = value!;
                                        });
                                      },
                                    ),
                                    GestureDetector(
                                      onDoubleTap: () => _changeTagColor(index),
                                      child: CircleAvatar(
                                          backgroundColor: _tags[index]['color'],
                                          radius: 8
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onDoubleTap: () => _editTagName(context, index),
                                        child: Text(
                                          _tags[index]['name'],
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close, color: Colors.grey),
                                      onPressed: _tags.length > 1 ? () => _deleteTag(index) : null,
                                    ),
                                  ],
                                );
                              }),
                            ),
                            SizedBox(height: 24),
                            // 상세 일정 작성
                            Expanded(
                              child: TextField(
                                controller: _detailsController,
                                maxLines: null,
                                expands: true,
                                decoration: InputDecoration(
                                  labelText: '일정 상세 내용',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            // 작성 완료 버튼
                            ElevatedButton(
                              onPressed: () {
                                // 작성 완료 처리
                              },
                              child: Text('작성 완료'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledBox({
    required String label,
    required Widget child,
  }) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFF2F1EE)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 16,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorCircle({required Color color}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
  // 텍스트 필드 편집 컨트롤러
  final TextEditingController _editingController = TextEditingController();

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }



  Widget _buildDateTimePickerField(
      BuildContext context, {
        required DateTime selectedDateTime,
        required bool isStart,
        required Color color,
      }) {
    return Stack(
      children: [
        ClipPath(
          clipper: isStart ? ArrowClipper() : null,
          child: Container(
              width: double.infinity, // 부모의 너비를 가득 채움
              color: color,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                mainAxisAlignment: MainAxisAlignment.center, // 세로 가운데 정렬
                children: [
                  Text(
                    '${selectedDateTime.month} 월 ${selectedDateTime.day} 일\n'
                        '${selectedDateTime.hour}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              )),
        ),
        Positioned.fill(
          child: ClipPath(
            clipper: isStart ? ArrowClipper() : null,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showCustomDateTimePicker(context, isStart),
                splashColor: Colors.white24, // 클릭 시 효과
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _editTagName(BuildContext context, int index) {
    _editingController.text = _tags[index]['name']; // 기존 태그 이름을 텍스트 필드에 설정
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('태그 이름 수정'),
          content: TextField(
            controller: _editingController,
            decoration: InputDecoration(hintText: '새로운 태그 이름'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tags[index]['name'] = _editingController.text;
                });
                Navigator.of(context).pop();
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _changeTagColor(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("태그 색상 변경"),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _tags[index]['color'],
              onColorChanged: (color) {
                setState(() {
                  _tags[index]['color'] = color;
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }


  void _addTag() {
    setState(() {
      int newIndex = _tags.length + 1;
      _tags.add({
        "name": "태그 $newIndex",
        "color": Colors.grey, // 기본 색상
      });
    });
  }

  void _deleteTag(int index) {
    setState(() {
      _tags.removeAt(index);
      if (_selectedTagIndex == index) {
        _selectedTagIndex = 0;
      } else if (_selectedTagIndex > index) {
        _selectedTagIndex--;
      }
    });
  }
}


class ArrowClipper extends CustomClipper<Path> {

  ArrowClipper();

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 20, 0);
    path.lineTo(size.width , size.height / 2);
    path.lineTo(size.width - 20, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
