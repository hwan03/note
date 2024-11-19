import 'package:flutter/material.dart';
import 'package:new_flutter/widgets/sidebar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  final TextEditingController _detailsController = TextEditingController();
  DateTime _selectedStartDateTime = DateTime.now();
  DateTime _selectedEndDateTime = DateTime.now();

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
                            Text('일정 태그'),
                            Column(
                              children: List.generate(_tags.length, (index) {
                                return Row(
                                  children: [
                                    Checkbox(
                                      value: _selectedTags[index],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedTags[index] = value ?? false;
                                        });
                                      },
                                    ),
                                    _buildColorCircle(
                                        color: _tags[index]['color']),
                                    SizedBox(width: 8),
                                    Text(_tags[index]['name']),
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

//   Future<void> _selectDate(BuildContext context, bool isStart) async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: isStart ? _startDate : _endDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//     if (pickedDate != null) {
//       setState(() {
//         if (isStart) {
//           _startDate = pickedDate;
//         } else {
//           _endDate = pickedDate;
//         }
//       });
//     }
//   }
// }
//

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
}

class ArrowClipper extends CustomClipper<Path> {

  ArrowClipper();

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 30, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 30, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
