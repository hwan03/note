import 'package:flutter/material.dart';

class EventTag {
  final String name;
  final Color color;

  EventTag({
    required this.name,
    required this.color,
  });

  // 팩토리 생성자를 추가해 Map 데이터를 클래스로 변환할 수 있음
  factory EventTag.fromMap(Map<String, dynamic> map) {
    return EventTag(
      name: map['name'],
      color: map['color'],
    );
  }

  // Map으로 변환하는 메서드 (JSON 변환 시 유용)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
    };
  }
}

class Event {
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final EventTag tag;

  Event({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.tag,
  });

  // 팩토리 생성자를 추가해 Map 데이터를 클래스로 변환할 수 있음
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      title: map['title'],
      description: map['description'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      tag: EventTag.fromMap(map['tag']),
    );
  }

  // Map으로 변환하는 메서드
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'tag': tag.toMap(),
    };
  }
}

final List<Event> events = [
  Event(
    title: '회의',
    description: '프로젝트 진행 회의',
    startDate: DateTime(2024, 11, 11),
    endDate: DateTime(2024, 11, 13),
    tag: EventTag(name: '업무', color: Color(0xFFFFC1C1)),
  ),
];


class CalendarState {
  ValueNotifier<DateTime> selectedDate = ValueNotifier(DateTime.now());
  ValueNotifier<List<Event>> events = ValueNotifier([]);

  void addEvent(Event event) {
    events.value = [...events.value, event];
  }

  List<Event> getEventsForDay(DateTime day) {
    final strippedDate = DateTime(day.year, day.month, day.day);
    return events.value.where((event) {
      final eventDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      return eventDate == strippedDate;
    }).toList();
  }
}

final CalendarState calendarState = CalendarState();
