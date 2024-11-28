import 'package:flutter/material.dart';




  Widget build(BuildContext context) {
  // 날짜별로 정렬된 이벤트
  final sortedDates = dateIndex.keys.toList()..sort();
  return Stack(
    children: [
      ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sortedDates.length,
        itemBuilder: (context, dateIndex) {
          final date = sortedDates[dateIndex];
          final events = getEventsForDay(date); // 해당 날짜의 이벤트 목록 가져오기

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
                date.isAtSameMomentAs(stripTime(eventStartDate))
                    ? eventStartDate
                    : DateTime(date.year, date.month, date.day, 0, 0);
                final adjustedEnd =
                date.isAtSameMomentAs(stripTime(eventEndDate))
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
                                          events.indexOf(event);
                                          if (eventIndex != -1) {
                                            deleteEvent(eventIndex);
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
