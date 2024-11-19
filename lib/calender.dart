import 'package:flutter/material.dart';
import 'package:new_flutter/widgets/sidebar.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tablet Calendar & Schedule',
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
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final List<Map<String, dynamic>> _tags = [
    {"name": "태그 1", "color": Color(0xFFFFC1C1)},
    {"name": "태그 2", "color": Color(0xFFB3D9FF)},
    {"name": "태그 3", "color": Color(0xFFC1FFD7)},
  ];
  final List<bool> _selectedTags = [false, false, false];

  final Map<DateTime, List<String>> _events = {
    DateTime(2024, 11, 11): ['태그 1'],
    DateTime(2024, 11, 12): ['태그 2'],
  };

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
            flex: 5,
            child: _buildLabeledBox(
              label: '달력',
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                eventLoader: (day) => _events[day] ?? [],
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.map((e) {
                          final tagIndex =
                              _tags.indexWhere((tag) => tag['name'] == e);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildColorCircle(
                                color: _tags[tagIndex]['color']),
                          );
                        }).toList(),
                      );
                    }
                    return null;
                  },
                ),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: '시작 날짜',
                              hintText:
                                  '${_startDate.year}-${_startDate.month}-${_startDate.day}',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: '종료 날짜',
                              hintText:
                                  '${_endDate.year}-${_endDate.month}-${_endDate.day}',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
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
                            _buildColorCircle(color: _tags[index]['color']),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }
}
