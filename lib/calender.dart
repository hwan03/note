import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:new_flutter/widgets/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert'; // JSON 인코딩/디코딩을 위해 필요

class CalenderPage extends StatefulWidget {
  const CalenderPage({super.key});

  @override
  _CalenderPageState createState() => _CalenderPageState();
}

class _CalenderPageState extends State<CalenderPage> {
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
      home: CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedStartDateTime = DateTime.now();
  DateTime _selectedEndDateTime = DateTime.now();
  Map<String, dynamic>? _selectedTag; // 선택된 태그를 저장

  int _selectedTagIndex = 0; // 현재 선택된 태그 인덱스

  List<Map<String, dynamic>> _events = [
    {
      'title': '회의',
      'description': '프로젝트 진행 회의',
      'startDate': DateTime(2024, 11, 11),
      'endDate': DateTime(2024, 11, 13),
      'tag': {'name': '업무', 'color': Color(0xFFFFC1C1)},
    },
  ];

  Map<DateTime, List<int>> _dateIndex = {
    DateTime(2024, 11, 11): [0], // 첫 번째 이벤트
    DateTime(2024, 11, 12): [0],
    DateTime(2024, 11, 13): [0],
  };

  List<Map<String, dynamic>> _getEventsForDay(DateTime date) {
    final strippedDate = _stripTime(date);
    if (_dateIndex[strippedDate] != null) {
      return _dateIndex[strippedDate]!.map((index) => _events[index]).toList();
    }
    return [];
  }

  late List<Map<String, dynamic>> _tags = [
    {"name": "업무", "color": Color(0xFFFFC1C1)},
  ];

  // List<Map<String, dynamic>> _getEventsForDay(DateTime date) {
  //   if (_dateIndex[date] != null) {
  //     return _dateIndex[date]!.map((index) => _events[index]).toList();
  //   }
  //   return [];
  // }

  // List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
  //   return _events[day] ?? [];
  // }

  @override
  @override
  void initState() {
    super.initState();
    _loadData();
    if (_tags.isNotEmpty) {
      _selectedTag = _tags[0]; // 첫 번째 태그를 기본 선택
    }

    // print('Initial _events: $_events');
    // print('Initial _dateIndex: $_dateIndex');
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
          Sidebar(),
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
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDate = selectedDay;
                                  _focusedDate = focusedDay;
                                  // print('Events for $selectedDay: ${_getEventsForDay(selectedDay)}');
                                });
                              },
                              eventLoader: (day) => _getEventsForDay(day),
                              // 이벤트 로드 설정
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, date, events) {
                                  // print('Date: $date, Events: $events');
                                  print(
                                      'Events for $date: $events'); // 디버깅 메시지 추가

                                  if (events.isNotEmpty) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children:
                                          (events as List<Map<String, dynamic>>)
                                              .map((event) {
                                        if (event['tag'] != null) {
                                          // t

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            child: _buildColorCircle(
                                                color: event['tag']['color'],
                                                size: 8),
                                          );
                                        }
                                        return SizedBox(); // tag가 null인 경우 빈 공간으로 처리
                                      }).toList(),
                                    );
                                  }
                                  return null; // 이벤트가 없는 경우 null 반환
                                },
                              ),
                              headerVisible: false,
                              rowHeight: 100,
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(),
                                todayTextStyle: TextStyle(color: Colors.black),
                                weekendTextStyle: TextStyle(color: Colors.red),
                                selectedDecoration: BoxDecoration(),
                                selectedTextStyle:
                                    TextStyle(color: Colors.black),
                              ),
                            ),
                          )
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
                                GestureDetector(
                                  onDoubleTap: () => _changeTagColor(
                                      _tags.indexOf(_selectedTag!)),
                                  child: CircleAvatar(
                                    backgroundColor: _selectedTag != null
                                        ? _selectedTag!['color'] : Colors.grey,
                                    radius: 8,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _titleController,
                                    decoration: InputDecoration(
                                      labelText: '제목',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            // 시작 날짜와 종료 날짜
                            Container(
                              height: 100,
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
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_outlined,
                                      color: Colors.black),
                                  onPressed: _tags.length < 5 ? _addTag : null,
                                ),
                              ],
                            ),
                            Column(
                              children: List.generate(_tags.length, (index) {
                                return Row(
                                  children: [
                                    Radio<Map<String, dynamic>>(
                                      value: _tags[index], // 현재 태그 데이터
                                      groupValue: _selectedTag, // 선택된 태그
                                      onChanged: (Map<String, dynamic>? value) {
                                        setState(() {
                                          _selectedTag = value; // 선택된 태그 저장
                                        });
                                      },
                                    ),
                                    GestureDetector(
                                      onDoubleTap: () => _changeTagColor(index),
                                      child: CircleAvatar(
                                          backgroundColor: _tags[index]
                                              ['color'],
                                          radius: 8),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onDoubleTap: () =>
                                            _editTagName(context, index),
                                        child: Text(
                                          _tags[index]['name'],
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.close, color: Colors.grey),
                                      onPressed: _tags.length > 1
                                          ? () => _deleteTag(index)
                                          : null,
                                    ),
                                  ],
                                );
                              }),
                            ),
                            SizedBox(height: 24),
                            // 상세 일정 작성
                            Expanded(
                              child: TextField(
                                controller: _descriptionController,
                                maxLines: null,
                                expands: true,
                                decoration: InputDecoration(
                                  labelText: '상세 내용',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            // 작성 완료 버튼
                            ElevatedButton(
                              onPressed: () {
                                // print(_selectedStartDateTime.toString());
                                // print(_selectedEndDateTime.toString());
                                if (_selectedStartDateTime != null &&
                                    _selectedEndDateTime != null &&
                                    _selectedTag != null &&
                                    _titleController.text.isNotEmpty) {
                                  _addEvent(
                                    startDate: _selectedStartDateTime!,
                                    endDate: _selectedEndDateTime!,
                                    title: _titleController.text,
                                    description: _descriptionController.text,
                                    tag: _selectedTag!,
                                  );

                                  _titleController.clear();
                                  _descriptionController.clear();

                                  setState(() {
                                    _selectedTag = null;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('모든 필드를 입력해주세요!')),
                                  );
                                }
                              },
                              child: Text('작성 완료'),
                            )
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

  Widget _buildColorCircle({
    required Color color,
    double size = 16,
  }) {
    return Container(
      width: size,
      height: size,
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
                  String oldName = _tags[index]['name'];
                  String newName = _editingController.text;

                  _tags[index]['name'] = newName;

                  // _events 업데이트
                  for (var event in _events) {
                    if (event['tag']['name'] == oldName) {
                      event['tag']['name'] = newName;
                    }
                  }
                });
                _saveData(); // 저장
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

                  // _events 업데이트
                  for (var event in _events) {
                    if (event['tag']['name'] == _tags[index]['name']) {
                      event['tag']['color'] = color;
                    }
                  }
                });
                _saveData(); // 저장
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

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 모든 저장 데이터를 삭제

    // 이벤트와 날짜 인덱스를 JSON으로 변환
    final eventData = _events
        .map((event) => {
              'title': event['title'],
              'description': event['description'],
              'startDate': event['startDate'].toIso8601String(),
              'endDate': event['endDate'].toIso8601String(),
              'tag': {
                'name': event['tag']['name'],
                'color': event['tag']['color'].value,
              },
            })
        .toList();

    final dateIndexData = _dateIndex
        .map((date, indices) => MapEntry(date.toIso8601String(), indices));

    await prefs.setString('events', jsonEncode(eventData));
    await prefs.setString('dateIndex', jsonEncode(dateIndexData));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final eventData = prefs.getString('events');
    final dateIndexData = prefs.getString('dateIndex');

    if (eventData != null) {
      setState(() {
        _events = (jsonDecode(eventData) as List<dynamic>).map((event) {
          return {
            'title': event['title'],
            'description': event['description'],
            'startDate': DateTime.parse(event['startDate']),
            'endDate': DateTime.parse(event['endDate']),
            'tag': {
              'name': event['tag']['name'],
              'color': Color(event['tag']['color']), // 정수에서 Color 객체로 복원
            },
          };
        }).toList();
      });
    }

    if (dateIndexData != null) {
      setState(() {
        _dateIndex = (jsonDecode(dateIndexData) as Map<String, dynamic>).map(
          (key, value) {
            return MapEntry(DateTime.parse(key), List<int>.from(value));
          },
        );
      });
    }
  }

  void _addEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> tag,
  }) {
    final newEvent = {
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'tag': tag,
    };

    setState(() {
      // 이벤트 리스트에 추가
      _events.add(newEvent);
      int eventIndex = _events.length - 1;

      // 날짜 인덱스 업데이트

      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        final strippedDate = _stripTime(currentDate);
        if (_dateIndex[strippedDate] == null) {
          _dateIndex[strippedDate] = [];
        }
        _dateIndex[strippedDate]!.add(eventIndex);
        currentDate = currentDate.add(Duration(days: 1));
      }
    });

    _saveData();
  }

  void _deleteEvent(int eventIndex) {
    setState(() {
      // 이벤트 삭제
      _events.removeAt(eventIndex);

      // 날짜 인덱스 업데이트
      _dateIndex.forEach((date, indices) {
        indices.remove(eventIndex);
      });

      // 날짜 인덱스 정리: 비어 있는 날짜 제거 및 인덱스 재정렬
      _dateIndex.removeWhere((_, indices) => indices.isEmpty);
      _dateIndex.forEach((date, indices) {
        _dateIndex[date] = indices
            .map((index) => index > eventIndex ? index - 1 : index)
            .toList();
      });
    });

    _saveData();
  }

  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 20, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 20, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
