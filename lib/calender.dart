import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:new_flutter/widgets/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert'; // JSON 인코딩/디코딩을 위해 필요

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
    return Theme(
      data: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      child: Scaffold(
        body: CalendarScreen(
          recentPages: widget.recentPages,
          navigateToPage: widget.navigateToPage,
          addNewPage: widget.addNewPage,
        ),
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
  bool _isCreatingEvent = false; // true: 일정 작성 화면, false: 예정된 일정 화면
  bool _isEditing = false;

  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedStartDateTime = DateTime.now();
  DateTime _selectedEndDateTime = DateTime.now();
  Map<String, dynamic>? _selectedTag; // 선택된 태그를 저장
  Map<String, dynamic>? _editingEvent; // 수정 중인 이벤트를 저장하는 변수

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

  late List<Map<String, dynamic>> _tags = [
    {"name": "업무", "color": Color(0xFFFFC1C1)},
  ];

  List<Map<String, dynamic>> _getEventsForDay(DateTime date) {
    final strippedDate = _stripTime(date);
    if (_dateIndex[strippedDate] != null) {
      return _dateIndex[strippedDate]!.map((index) => _events[index]).toList();
    }
    return [];
  }

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
              minimumDate: isStart ? null : _selectedStartDateTime,
              // endTime 제한
              onDateTimeChanged: (DateTime newDate) {
                setState(() {
                  if (isStart) {
                    _selectedStartDateTime = newDate;

                    // endTime도 자동으로 startTime 이후로 설정
                    if (_selectedEndDateTime.isBefore(newDate)) {
                      _selectedEndDateTime =
                          newDate.add(const Duration(hours: 1));
                    }
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
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDate = selectedDay;
                                  _focusedDate = focusedDay;
                                  // print('Events for $selectedDay: ${_getEventsForDay(selectedDay)}');
                                });
                              },
                              onPageChanged: (focusedDay) {
                                // 페이지가 변경되었을 때 호출
                                setState(() {
                                  _focusedDate = focusedDay; // 연/월 업데이트
                                });
                              },
                              eventLoader: (day) => _getEventsForDay(day),
                              // 이벤트 로드 설정
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, date, events) {
                                  // print('Date: $date, Events: $events');
                                  final limitedEvents =
                                      (events as List<Map<String, dynamic>>)
                                          .take(4)
                                          .toList();
                                  if (events.isNotEmpty) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: (limitedEvents).map((event) {
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
                      child: _isCreatingEvent
                          ? _buildEventEditor()
                          : _buildSchedule(context),
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

  /// 예정된 일정 화면
  Widget _buildSchedule(BuildContext context) {
    // 날짜별로 정렬된 이벤트
    final sortedDates = _dateIndex.keys.toList()..sort();
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sortedDates.length,
          itemBuilder: (context, dateIndex) {
            final date = sortedDates[dateIndex];
            final events = _getEventsForDay(date); // 해당 날짜의 이벤트 목록 가져오기

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${date.year}년 ${date.month}월 ${date.day}일 (${_getWeekday(date)})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {});
                          createMode(
                              selectedDate: date.add(Duration(hours: 9)));
                        },
                      ),
                    ],
                  ),
                ),
                // 해당 날짜의 이벤트 목록
                ...events.map((event) {
                  final eventStartDate = event['startDate'];
                  final eventEndDate = event['endDate'];
                  final adjustedStart =
                      date.isAtSameMomentAs(_stripTime(eventStartDate))
                          ? eventStartDate
                          : DateTime(date.year, date.month, date.day, 0, 0);
                  final adjustedEnd =
                      date.isAtSameMomentAs(_stripTime(eventEndDate))
                          ? eventEndDate
                          : DateTime(date.year, date.month, date.day, 23, 59);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [ // 태그 색상 표시q
                            Container(
                              width: 8,
                              decoration: BoxDecoration(
                                color: event['tag']['color'],
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 일정 제목
                                    Row(
                                      children: [
                                        Text(
                                          event['title'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Spacer(),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            editMode(selectedEvent: event);
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          // 클릭할 때 하이라이트 효과 제거
                                          splashColor:
                                          Colors.transparent, // 스플래시 효과 제거
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close_outlined,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            int eventIndex =
                                            _events.indexOf(event);
                                            if (eventIndex != -1) {
                                              _deleteEvent(eventIndex);
                                            }
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          // 클릭할 때 하이라이트 효과 제거
                                          splashColor:
                                          Colors.transparent, // 스플래시 효과 제거
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    // 일정 설명
                                    Text(
                                      event['description'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    // 시작 시간 - 종료 시간
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 14, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          '${_formatTime(adjustedStart)} - ${_formatTime(adjustedEnd)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        Positioned(
          bottom: -10,
          right: -10,
          child: IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: Colors.grey,
              size: 30,
            ),
            onPressed: () {
              createMode(selectedDate: DateTime.now()); // 이전 화면으로 전환
            },
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            // 클릭할 때 하이라이트 효과 제거
            splashColor: Colors.transparent, // 스플래시 효과 제거
          ),
        ),
      ],
    );
  }

// 요일을 반환하는 함수
  String _getWeekday(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

// 시간 포맷팅 함수
  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildEventEditor() {
    return Stack(children: [
      Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 일정 제목
            Row(
              children: [
                GestureDetector(
                  onDoubleTap: () =>
                      _changeTagColor(_tags.indexOf(_selectedTag!)),
                  child: CircleAvatar(
                    backgroundColor: _selectedTag != null
                        ? _selectedTag!['color']
                        : Colors.grey,
                    radius: 8,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    maxLength: 20,
                    maxLines: 1,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.add_outlined, color: Colors.black),
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
                          backgroundColor: _tags[index]['color'], radius: 8),
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
                      onPressed:
                          _tags.length > 1 ? () => _deleteTag(index) : null,
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
                maxLength: 70,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: InputDecoration(
                  labelText: '상세 내용',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 16),
            // 작성 완료 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_selectedStartDateTime != null &&
                        _selectedEndDateTime != null &&
                        _selectedTag != null &&
                        _titleController.text.isNotEmpty) {
                      if (_isEditing) {
                        // 수정 모드일 경우
                        _editEvent(
                          eventIndex: _events.indexOf(_editingEvent!),
                          startDate: _selectedStartDateTime,
                          endDate: _selectedEndDateTime,
                          title: _titleController.text,
                          description: _descriptionController.text,
                          tag: _selectedTag!,
                        );
                      } else {
                        // 작성 모드일 경우
                        _addEvent(
                          startDate: _selectedStartDateTime,
                          endDate: _selectedEndDateTime,
                          title: _titleController.text,
                          description: _descriptionController.text,
                          tag: _selectedTag!,
                        );
                      }

                      // 필드 초기화 및 화면 전환
                      _titleController.clear();
                      _descriptionController.clear();
                      _toggleScreen();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('모든 필드를 입력해주세요!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.grey[200],
                    // 텍스트 색상 (검정)
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    // 버튼 크기 조정
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // 적당히 둥근 모서리
                    ),
                    elevation: 1, // 낮은 그림자 효과
                  ),
                  child: Text(
                    '작성 완료',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500, // 중간 굵기
                      color: Colors.black, // 텍스트 색상
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      Positioned(
        top: -10,
        right: -10,
        child: IconButton(
          icon: Icon(Icons.close, color: Colors.grey),
          onPressed: () {
            _titleController.clear();
            _descriptionController.clear();
            _toggleScreen(); // 이전 화면으로 전환
          },
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          // 클릭할 때 하이라이트 효과 제거
          splashColor: Colors.transparent, // 스플래시 효과 제거
        ),
      ),
    ]);
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
      // 날짜 인덱스 업데이트
      _updateIndex(
          startDate: startDate,
          endDate: endDate,
          eventIndex: _events.length - 1,
          isAdding: true);

      // 이벤트 리스트 정렬
      _sortEvents();
    });
    _saveData();
  }

  void _deleteEvent(int eventIndex) {
    setState(() {
      // 이벤트 삭제 전에 날짜 인덱스에서 제거
      final eventToDelete = _events[eventIndex];
      _updateIndex(
        startDate: eventToDelete['startDate'],
        endDate: eventToDelete['endDate'],
        eventIndex: eventIndex,
        isAdding: false,
      );

      // 이벤트 삭제
      _events.removeAt(eventIndex);

      // 날짜 인덱스 정리: 비어 있는 날짜 제거 및 인덱스 재정렬
      _dateIndex.forEach((date, indices) {
        _dateIndex[date] = indices
            .where((index) => index != eventIndex)
            .map((index) => index > eventIndex ? index - 1 : index)
            .toList();
      });
      _dateIndex.removeWhere((_, indices) => indices.isEmpty);
    });

    _saveData();
  }

  void _editEvent({
    required int eventIndex,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> tag,
  }) {
    final updatedEvent = {
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'tag': tag,
    };

    setState(() {
      // 기존 날짜 인덱스에서 이벤트 제거
      final oldEvent = _events[eventIndex];
      _updateIndex(
          startDate: oldEvent['startDate'],
          endDate: oldEvent['endDate'],
          eventIndex: eventIndex,
          isAdding: false);
      // 이벤트 리스트 수정
      _events[eventIndex] = updatedEvent;
      // 새로운 날짜 인덱스에 이벤트 추가
      _updateIndex(
          startDate: startDate,
          endDate: endDate,
          eventIndex: eventIndex,
          isAdding: true);

      // 이벤트 리스트 정렬
      _sortEvents();
    });

    _saveData();
  }

  void _updateIndex({
    required DateTime startDate,
    required DateTime endDate,
    required int eventIndex,
    bool isAdding = true,
  }) {
    // 시작 날짜부터 종료 날짜까지 인덱스를 업데이트합니다.
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final strippedDate = _stripTime(currentDate);

      if (isAdding) {
        // 이벤트 추가 시, 날짜에 해당 이벤트 인덱스를 추가
        if (_dateIndex[strippedDate] == null) {
          _dateIndex[strippedDate] = [];
        }
        _dateIndex[strippedDate]!.add(eventIndex);
      } else {
        // 이벤트 삭제 시, 날짜에서 해당 이벤트 인덱스를 제거
        _dateIndex[strippedDate]?.remove(eventIndex);
        if (_dateIndex[strippedDate]?.isEmpty ?? true) {
          _dateIndex.remove(strippedDate);
        }
      }

      currentDate = currentDate.add(Duration(days: 1));
    }
  }

  void editMode({required Map<String, dynamic> selectedEvent}) {
    setState(() {
      _isEditing = true;
      _editingEvent = selectedEvent;
      // 수정 모드로 넘어갈 때 초기값 설정
      _selectedStartDateTime = _editingEvent?['startDate'];
      _selectedEndDateTime = _editingEvent?['endDate'];
      _titleController.text = _editingEvent?['title'];
      _descriptionController.text = _editingEvent?['description'] ?? '';
      _selectedTag = _editingEvent?['tag'];

      _toggleScreen();
    });
  }

  void createMode({required DateTime selectedDate}) {
    setState(() {
      _isEditing = false; // 작성 모드로 설정

      // 작성 모드로 넘어갈 때 초기값 설정
      _selectedStartDateTime = selectedDate;
      _selectedEndDateTime = selectedDate.add(Duration(hours: 1));
      _titleController.clear();
      _descriptionController.clear();
      _selectedTag = _tags[0];
      _toggleScreen();
    });
  }

  void _toggleScreen() {
    setState(() {
      _isCreatingEvent = !_isCreatingEvent;
    });
  }

  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _sortEvents() {
    _events.sort((a, b) => a['startDate'].compareTo(b['startDate']));
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
