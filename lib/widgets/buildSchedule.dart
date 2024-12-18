import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_flutter/state/scheduleState.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class BuildSchedule extends StatefulWidget {
  final ScheduleState scheduleState;
  final bool isHome;
  final scrollController;
  final positionsListener;
  final DateTime? selectedDate; // 선택된 날짜

  const BuildSchedule(
      {required this.scheduleState,
      this.isHome = false,
      this.scrollController,
      this.positionsListener,
      this.selectedDate,
      super.key});

  @override
  State<BuildSchedule> createState() => _BuildScheduleState();
}

class _BuildScheduleState extends State<BuildSchedule> {
  @override
  void initState() {
    super.initState();
    if (widget.isHome) {

      widget.scheduleState.loadData().then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToTodayOrNext();
        });
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // ScheduleState 구독
    final sortedDates = widget.scheduleState.dateIndex.keys.toList()..sort();

    if (widget.selectedDate != null &&
        !sortedDates
            .contains(widget.scheduleState.stripTime(widget.selectedDate!))) {
      sortedDates.add(widget.selectedDate!);
      sortedDates.sort();
    }

    // 선택된 날짜가 있고, 일정이 없으면 추가

    // 날짜별로 정렬된 이벤트
    if (sortedDates.isEmpty) {
      return Stack(children: [
        Center(
          child: Text(
            '일정이 없습니다.',
            style: TextStyle(
              fontSize: widget.isHome ? 14 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        if (!widget.isHome)
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
                widget.scheduleState
                    .createMode(selectedDate: DateTime.now()); // 이전 화면으로 전환
              },
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              // 클릭할 때 하이라이트 효과 제거
              splashColor: Colors.transparent, // 스플래시 효과 제거
            ),
          ),
      ]);
    }

    return Stack(
      children: [
        ScrollablePositionedList.builder(
          padding: widget.isHome
              ? EdgeInsets.fromLTRB(8, 0, 8, 0)
              : const EdgeInsets.all(16.0),
          itemCount:  sortedDates.length + (widget.isHome ? 0:1),
          itemBuilder: (context, dateIndex) {
            if (!widget.isHome && dateIndex == sortedDates.length) {
              return SizedBox(
                height: screenHeight * 0.8, // Stack의 절반 높이
              );
            }
            final date = sortedDates[dateIndex];
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
                          fontSize: widget.isHome ? 14 : 18,
                          fontWeight: widget.isHome
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (!widget.isHome)
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Colors.grey,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {});
                            widget.scheduleState.createMode(
                                selectedDate: date.add(Duration(hours: 9)));
                          },
                        ),
                    ],
                  ),
                ),

                ..._buildEventTilesForDate(date),
              ],
            );
          },
          itemScrollController: widget.scrollController,
          itemPositionsListener: widget.positionsListener,
        ),
        if (!widget.isHome) ...[
          Positioned(
            top: 0,
            right: 0,
            child: Theme(
              data: Theme.of(context).copyWith(
                hoverColor: Colors.transparent, // Hover 효과 제거
                highlightColor: Colors.transparent, // 강조 효과 제거
                splashColor: Colors.transparent, // 클릭 스플래시 효과 제거
              ),
              child: PopupMenuButton<String>(
                icon: Icon(Icons.bookmarks, color: Colors.grey),
                onSelected: (String value) {
                  final index = widget.scheduleState.tags
                      .indexWhere((tag) => tag['name'] == value);
                  // final isSelected = !selectedTags.contains(value);
                  // _onTagSelected(index, isSelected);
                },
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                itemBuilder: (BuildContext context) {
                  return widget.scheduleState.tags.map((tag) {
                    // final isSelected = selectedTags.contains(tag['name']);
                    return PopupMenuItem<String>(
                      value: tag['name'],
                      child: Row(
                        children: [
                          Checkbox(
                            value: true, // 임시로 true로 설정
                            onChanged: (bool? value) {
                              final index =
                                  widget.scheduleState.tags.indexOf(tag);
                              // _onTagSelected(index, value);
                            },
                          ),
                          CircleAvatar(
                            backgroundColor: tag['color'],
                            radius: 8,
                          ),
                          SizedBox(width: 8),
                          Text(tag['name']),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
            ),
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
                widget.scheduleState
                    .createMode(selectedDate: DateTime.now()); // 이전 화면으로 전환
              },
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              // 클릭할 때 하이라이트 효과 제거
              splashColor: Colors.transparent, // 스플래시 효과 제거
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildEventTilesForDate(DateTime date) {
    final eventIds = widget.scheduleState.getEventsForDay(date);
    if (eventIds.isEmpty) {
      // 해당 날짜에 일정이 없을 경우
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
          child: Text(
            "일정이 없습니다",
            style: TextStyle(
              fontSize: widget.isHome ? 12 : 16,
              color: Colors.grey,
            ),
          ),
        ),
      ];
    }

    return eventIds.map((eventId) {
      final event = widget.scheduleState.events[eventId];
      final eventStartDate = event?['startDate'];
      final eventEndDate = event?['endDate'];
      final adjustedStart =
          date.isAtSameMomentAs(widget.scheduleState.stripTime(eventStartDate))
              ? eventStartDate
              : DateTime(date.year, date.month, date.day, 0, 0);
      final adjustedEnd =
          date.isAtSameMomentAs(widget.scheduleState.stripTime(eventEndDate))
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
              children: [
                // 태그 색상 표시
                Container(
                  width: 8,
                  decoration: BoxDecoration(
                    color: event?['tag']['color'],
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
                              event?['title'],
                              style: TextStyle(
                                fontSize: widget.isHome ? 12 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Spacer(),
                            if (!widget.isHome) ...[
                              GestureDetector(
                              onTap: () {
                                  widget.scheduleState
                                      .editMode(eventId: eventId);
                                },
                                child: Container(
                                  padding: EdgeInsets.zero, // 여백 없음
                                  constraints: BoxConstraints(),
                                  child:Icon(
                                    Icons.edit,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (widget.scheduleState.events
                                      .containsKey(eventId)) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(
                                            '일정을 삭제하시겠습니까?',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 18),
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
                                                  widget.scheduleState
                                                      .deleteEvent(
                                                      eventId: eventId);
                                                });
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('확인'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  child: Icon(
                                    Icons.close_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        // 일정 설명
                        Text(
                          event?['description'] ?? '',
                          style: TextStyle(
                            fontSize: widget.isHome ? 10 : 14,
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
    }).toList();
  }


  void scrollToTodayOrNext() {
    if (!widget.isHome) return; // 홈이 아닌 경우 아무 작업도 하지 않음

    final scheduleState = widget.scheduleState;

    final today = scheduleState.stripTime(DateTime.now());
    final sortedDates = scheduleState.dateIndex.keys.toList()..sort();

    // 오늘 이후 가장 가까운 날짜 찾기
    DateTime? targetDate;
    for (final date in sortedDates) {
      if (!date.isBefore(today)) {
        targetDate = date;
        break;
      }
    }

    // 스크롤 실행
    if (targetDate != null) {
      final targetIndex = sortedDates.indexOf(targetDate);
      widget.scrollController.scrollTo(
        index: targetIndex,
        duration : Duration(milliseconds: 300 + (targetIndex * 10).clamp(0, 500)),
        curve: Curves.easeInOutCubic,
        alignment: 0.01, // 스크롤 위치 조정
      );
    }
  }

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
}
