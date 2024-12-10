import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:new_flutter/state/scheduleState.dart';
import 'package:new_flutter/widgets/buildSchedule.dart';
import 'package:new_flutter/widgets/sidebar.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CalendarPage extends StatefulWidget {
  final Map<String, Map<String, dynamic>> pages; // 페이지 데이터
  final Function(String) navigateToPage; // 페이지 이동 함수
  final VoidCallback addNewPage; // 새 페이지 추가 함수

  const CalendarPage({
    required this.pages,
    required this.navigateToPage,
    required this.addNewPage,
    Key? key,
  }) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      child: Scaffold(
        body: CalendarScreen(
          pages: widget.pages,
          navigateToPage: widget.navigateToPage,
          addNewPage: widget.addNewPage,
        ),
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> pages; // 추가
  final Function(String) navigateToPage;
  final VoidCallback addNewPage;

  const CalendarScreen({
    required this.pages,
    required this.navigateToPage,
    required this.addNewPage,
    Key? key,
  }) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final scheduleState = Provider.of<ScheduleState>(context, listen: false);

    await scheduleState.loadData();

    // 태그 초기화 확인
    for (var tag in scheduleState.tags) {
      if (!scheduleState.tagEventIndex.containsKey(tag['name'])) {
        scheduleState.tagEventIndex[tag['name']] = [];
      }
    }

    scheduleState.notifyListeners(); // 상태 변경 알림
  }

  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  final scrollController = ItemScrollController();

  Future<void> _showCustomDateTimePicker(
      BuildContext context, bool isStart) async {
    final scheduleState = context.read<ScheduleState>(); // 한 번 호출

    DateTime tempDate = isStart
        ? scheduleState.selectedStartDateTime
        : scheduleState.selectedEndDateTime;
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
              minimumDate: isStart ? null : scheduleState.selectedStartDateTime,
              // endTime 제한
              onDateTimeChanged: (DateTime newDate) {
                setState(() {
                  if (isStart) {
                    scheduleState.selectedStartDateTime = newDate;

                    // endTime도 자동으로 startTime 이후로 설정
                    if (scheduleState.selectedEndDateTime.isBefore(newDate)) {
                      scheduleState.selectedEndDateTime =
                          newDate.add(const Duration(hours: 1));
                    }
                  } else {
                    scheduleState.selectedEndDateTime = newDate;
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
  void dispose() {
    // ScrollController는 수명 주기가 끝날 때 반드시 dispose 해야 메모리 누수를 방지할 수 있습니다.
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = Provider.of<ScheduleState>(context, listen: true);

    return Scaffold(
      resizeToAvoidBottomInset: false, // 키보드가 올라와도 기본 크기 유지
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Sidebar(
            pages: widget.pages,
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
                                  scrollToDate(selectedDay);
                                  // 해당 날짜로 스크롤
                                });
                              },
                              onPageChanged: (focusedDay) {
                                // 페이지가 변경되었을 때 호출
                                setState(() {
                                  _focusedDate = focusedDay; // 연/월 업데이트
                                });
                              },
                              eventLoader: (day) {
                                // 이벤트 ID 리스트를 가져옴
                                final eventIds =
                                    scheduleState.getEventsForDay(day);

                                // ID 리스트를 통해 실제 이벤트 객체 리스트로 변환
                                return eventIds
                                    .map((id) => scheduleState.events[id]!)
                                    .toList();
                              },
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
                  // ₩ 작성 영역
                  Expanded(
                    flex: 5,
                    child: _buildLabeledBox(
                      label: '일정',
                      child: scheduleState.isCreatingEvent
                          ? _buildEventEditor()
                          : BuildSchedule(
                              scheduleState: scheduleState,
                              scrollController: scrollController,
                              selectedDate: _selectedDate,
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

  void scrollToDate(DateTime date) {
    final scheduleState = context.read<ScheduleState>();
    final sortedDates = scheduleState.dateIndex.keys.toList()..sort();
    final strippedDate = scheduleState.stripTime(date);

    if (!sortedDates.contains(strippedDate)) {
      sortedDates.add(strippedDate);
      sortedDates.sort();
    }

    // 선택된 날짜의 인덱스 계산ㄴㄴ
    final targetIndex = sortedDates.indexOf(strippedDate);

    // 스크롤 실행
    if (scrollController.isAttached) {
      scrollController.scrollTo(
        index: targetIndex,
        duration:
            Duration(milliseconds: 300 + (targetIndex * 10).clamp(0, 500)),
        curve: Curves.easeInOutCubic,
        alignment: 0.01,
      );
    }
  }

  /// 예정된 일정 화면

  Widget _buildEventEditor() {
    final scheduleState = context.read<ScheduleState>();

    return Stack(children: [
      Padding(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 일정 제목
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onDoubleTap: scheduleState.isEditing
                              ? null
                              : () => changeTagColorDiaglog(scheduleState.tags
                                  .indexOf(scheduleState.selectedTag!)),
                          child: CircleAvatar(
                            backgroundColor:
                                scheduleState.selectedTag!['color'],
                            radius: 8,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: scheduleState.titleController,
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
                    SizedBox(height: 12),
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
                              selectedDateTime:
                                  scheduleState.selectedStartDateTime,
                              color: Colors.blue,
                              isStart: true,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildDateTimePickerField(
                              context,
                              color: Color(0xFF91918E),
                              selectedDateTime:
                                  scheduleState.selectedEndDateTime,
                              isStart: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "일정 태그",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        // if(!scheduleState.isEditing)
                        GestureDetector(
                          onTap: scheduleState.tags.length < 4
                              ? scheduleState.addTag
                              : null,
                          child: Container(
                            width: 48, // 원하는 너비
                            height: 48, // 원하는 높이
                            alignment: Alignment.center, // 아이콘 정렬
                            child: Icon(
                              Icons.add_outlined,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children:
                          List.generate(scheduleState.tags.length, (index) {
                        return Row(
                          children: [
                            SizedBox(
                              height: 34,
                              child: Radio<Map<String, dynamic>>(
                                value: scheduleState.tags[index],
                                // 현재 태그 데이터
                                groupValue: scheduleState.selectedTag,
                                // 선택된 태그
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (Map<String, dynamic>? value) {
                                  setState(() {
                                    scheduleState.selectedTag =
                                        value; // 선택된 태그 저장
                                  });
                                },
                              ),
                            ),
                            GestureDetector(
                              onDoubleTap: scheduleState.isEditing
                                  ? null
                                  : () => changeTagColorDiaglog(index),
                              child: CircleAvatar(
                                  backgroundColor: scheduleState.tags[index]
                                      ['color'],
                                  radius: 8),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onDoubleTap: scheduleState.isEditing
                                    ? null
                                    : () => editTagNameDialog(index),
                                child: Text(
                                  scheduleState.tags[index]['name'],
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            if (!scheduleState.isEditing)
                              GestureDetector(
                                  onTap: scheduleState.tags.length > 1
                                      ? () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(
                                                  '해당 태그를 삭제하시겠습니까?\n일정이 삭제됩니다!',
                                                  textAlign: TextAlign
                                                      .center, // 텍스트 가운데 정렬
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop(); // 팝업 닫기
                                                    },
                                                    child: Text('취소'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        scheduleState.deleteTag(
                                                            index); // 태그 삭제 함수 호출
                                                      });
                                                      Navigator.of(context)
                                                          .pop(); // 팝업 닫기
                                                    },
                                                    child: Text('확인'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      : null,
                                  child: Container(
                                    width: 48, // 원하는 너비
                                    height: 48, // 원하는 높이

                                    alignment: Alignment.center, // 아이콘 정렬

                                    child:
                                        Icon(Icons.close, color: Colors.grey),
                                  )),
                          ],
                        );
                      }),
                    ),
                    SizedBox(height: 12),
                    // 상세 일정 작성
                    Expanded(
                      child: TextField(
                        controller: scheduleState.descriptionController,
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
                    SizedBox(height: 8),
                    // 작성 완료 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (scheduleState.selectedStartDateTime != null &&
                                scheduleState.selectedEndDateTime != null &&
                                scheduleState.selectedTag != null &&
                                scheduleState.titleController.text.isNotEmpty) {
                              if (scheduleState.isEditing) {
                                // 수정 모드일 경우
                                scheduleState.editEvent(
                                  eventId: scheduleState.editingEventId,
                                  startDate:
                                      scheduleState.selectedStartDateTime,
                                  endDate: scheduleState.selectedEndDateTime,
                                  title: scheduleState.titleController.text,
                                  description:
                                      scheduleState.descriptionController.text,
                                  tag: scheduleState.selectedTag!,
                                );
                              } else {
                                // 작성 모드일 경우
                                scheduleState.addEvent(
                                  startDate:
                                      scheduleState.selectedStartDateTime,
                                  endDate: scheduleState.selectedEndDateTime,
                                  title: scheduleState.titleController.text,
                                  description:
                                      scheduleState.descriptionController.text,
                                  tag: scheduleState.selectedTag!,
                                );
                              }
                              // 필드 초기화 및 화면 전환
                              scheduleState.titleController.clear();
                              scheduleState.descriptionController.clear();
                              scheduleState.toggleScreen(); // 이전 화면으로 전환
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
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            // 버튼 크기 조정
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // 적당히 둥근 모서리
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
            ),
          );
        }),
      ),
      Positioned(
        top: -10,
        right: -10,
        child: IconButton(
          icon: Icon(Icons.close, color: Colors.grey),
          onPressed: () {
            scheduleState.titleController.clear();
            scheduleState.descriptionController.clear();
            scheduleState.toggleScreen(); // 이전 화면으로 전환
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

  void editTagNameDialog(int index) {
    final scheduleState = context.read<ScheduleState>();
    final TextEditingController editingController = TextEditingController();
    editingController.text = scheduleState.tags[index]['name'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('태그 이름 수정'),
          content: TextField(
            controller: editingController,
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
                try {
                  scheduleState.editTagName(
                    index: index,
                    newName: editingController.text.trim(),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void changeTagColorDiaglog(int index) {
    final scheduleState = Provider.of<ScheduleState>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("태그 색상 변경"),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: scheduleState.tags[index]['color'],
              onColorChanged: (color) {
                scheduleState.changeTagColor(index, color);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
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
