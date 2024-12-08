import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_flutter/state/scheduleState.dart';

class BuildSchedule extends StatefulWidget {
  final ScheduleState scheduleState;
  final bool isHome;
  const BuildSchedule({required this.scheduleState, this.isHome = false ,Key? key}) : super(key: key);

  @override
  State<BuildSchedule> createState() => _BuildScheduleState();
}

class _BuildScheduleState extends State<BuildSchedule> {
  @override
  Widget build(BuildContext context) {
    // ScheduleState 구독
    final sortedDates = widget.scheduleState.dateIndex.keys.toList()
      ..sort();
    // 날짜별로 정렬된 이벤트
    if (sortedDates.isEmpty) {
      return Stack(children: [
        Center(
          child: Text(
            '일정이 없습니다.',
            style: TextStyle(
              fontSize: widget.isHome? 14 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        if(!widget.isHome)
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
                widget.scheduleState.createMode(selectedDate: DateTime.now()); // 이전 화면으로 전환
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
        ListView.builder(
          padding: widget.isHome? EdgeInsets.fromLTRB(8,0,8,0) : const EdgeInsets.all(16.0),
          itemCount: sortedDates.length,
          itemBuilder: (context, dateIndex) {
            final date = sortedDates[dateIndex];
            final eventIds = widget.scheduleState.getEventsForDay(date); // 해당 날짜의 이벤트 id 목록 가져오기
            final events = eventIds.map((id) => widget.scheduleState.events[id]).toList();

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
                        '${date.year}년 ${date.month}월 ${date
                            .day}일 (${_getWeekday(date)})',
                        style: TextStyle(
                          fontSize: widget.isHome ? 14:  18,
                          fontWeight: widget.isHome ? FontWeight.normal: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if(!widget.isHome)
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
                // 해당 날짜의 이벤트 목록
                ...eventIds
                    .asMap()
                    .entries
                    .map((entry) {
                  final int index = entry.key;
                  final String eventId = entry.value;
                  final event = events[index];

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
                            // 태그 색상 표시q
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
                                            fontSize: widget.isHome ? 12 :  16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Spacer(),
                                        if(!widget.isHome) ...[
                                          IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            widget.scheduleState.editMode(eventId: eventId);
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
                                              if (widget.scheduleState.events.containsKey(eventId)) {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                        '일정을 삭제하시겠습니까?',
                                                        textAlign:
                                                        TextAlign.center,
                                                        style: TextStyle(
                                                            fontSize: 18),
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
                                                              widget.scheduleState.deleteEvent(eventId: eventId); // 이벤트 삭제 함수 호출
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
                                          '${_formatTime(
                                              adjustedStart)} - ${_formatTime(
                                              adjustedEnd)}',
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
        if(!widget.isHome) ...[
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
                  final index = widget.scheduleState.tags.indexWhere((tag) => tag['name'] == value);
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
                              final index = widget.scheduleState.tags.indexOf(tag);
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
                widget.scheduleState.createMode(selectedDate: DateTime.now()); // 이전 화면으로 전환
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


