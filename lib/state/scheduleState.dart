import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ScheduleState extends ChangeNotifier {
  final uuid = Uuid();

  Map<String, Map<String, dynamic>> events = {};
  Map<DateTime, List<String>> dateIndex = {
    // DateTime(2024, 11, 11): ["uuid-1234"], // 첫 번째 이벤트
    // DateTime(2024, 11, 12): ["uuid-1234"],
    // DateTime(2024, 11, 13): ["uuid-1234"],
  };
  late List<Map<String, dynamic>> tags = [
    {"name": "업무", "color": Color(0xFFFFC1C1)},
  ];
  Map<String, List<String>> tagEventIndex = {};

  bool isEditing = false;
  bool isCreatingEvent = false; // true: 일정 작성 화면, false: 예정된 일정 화면

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime selectedStartDateTime = DateTime.now();
  DateTime selectedEndDateTime = DateTime.now();
  Map<String, dynamic>? selectedTag; // 선택된 태그를 저장
  late String editingEventId;
  int selectedTagIndex = 0; // 현재 선택된 태그 인덱스

  void addEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> tag,
  }) {
    final String newId = uuid.v4();
    final newEvent = {
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'tag': tag,
    };
    events[newId] = newEvent;
    // 태그-이벤트 매핑 업데이트

    // 날짜 인덱스 업데이트
    updateIndex(
      startDate: startDate,
      endDate: endDate,
      eventId: newId,
      tagName: tag["name"],
      isAdding: true,
    );
    saveData();
    notifyListeners();
  }

  void deleteEvent({required String eventId}) {
    // 이벤트 삭제 전에 날짜 인덱스에서 먼저 제거
    final eventToDelete = events[eventId];
    updateIndex(
        startDate: eventToDelete?["startDate"],
        endDate: eventToDelete?["endDate"],
        eventId: eventId,
        tagName: eventToDelete?["tag"]["name"],
        isAdding: false);
    // 이벤트 삭제


    events.remove(eventId);

    saveData();
    notifyListeners();
  }

  void editEvent({
    required String eventId,
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
    // 기존 날짜 인덱스에서 이벤트 제거
    var oldEvent = events[eventId];
    updateIndex(
        startDate: oldEvent?["startDate"],
        endDate: oldEvent?["endDate"],
        eventId: eventId,
        tagName: oldEvent?["tag"]["name"],
        isAdding: false);
    events[eventId] = updatedEvent;
    updateIndex(
        startDate: startDate,
        endDate: endDate,
        eventId: eventId,
        tagName: tag["name"],
        isAdding: true);
    // 새로운 날짜 인덱스에 이벤트 추가
    saveData();
    notifyListeners();
  }

  void updateIndex({
    required DateTime startDate,
    required DateTime endDate,
    required String eventId,
    required String tagName,
    required bool isAdding,
  }) {
    print("Before updateIndex - dateIndex: $dateIndex");
    print("Before updateIndex - tagEventIndex: $tagEventIndex");

    // 시작 날짜부터 종료 날짜까지 인덱스를 업데이트합니다.
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final strippedDate = stripTime(currentDate);

      if (isAdding) {
        // 이벤트 추가 시, 날짜에 해당 이벤트 인덱스를 추가
        if (dateIndex[strippedDate] == null) {
          dateIndex[strippedDate] = [];
        }
        dateIndex[strippedDate]!.add(eventId);
        //태그인덱스에서 id 추가
        if (tagEventIndex.containsKey(tagName)) {
          tagEventIndex[tagName]!.add(eventId);
        }
      } else {
        // 이벤트 삭제 시, 날짜에서 해당 이벤트 인덱스를 제거
        dateIndex[strippedDate]?.remove(eventId);
        if (dateIndex[strippedDate]?.isEmpty ?? true) {
          dateIndex.remove(strippedDate);
        }
        // 태그인덱스 에서 id 삭제
        if (tagEventIndex.containsKey(tagName)) {
          tagEventIndex[tagName]?.remove(eventId);
        }


      }

      currentDate = currentDate.add(Duration(days: 1));
    }
    print("after updateIndex - dateIndex: $dateIndex");
    print("after updateIndex - tagEventIndex: $tagEventIndex");

  }

  List<String> getEventsForDay(DateTime date) {
    final strippedDate = stripTime(date);
    if (dateIndex[strippedDate] != null) {
      // 날짜 인덱스에서 이벤트 ID를 통해 이벤트 정보를 가져옵니다.
      return dateIndex[strippedDate]!.toList();
    }
    return [];
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    // 이벤트와 날짜 인덱스를 JSON으로 변환
    final eventData = events.map((id, event) => MapEntry(
          id,
          {
            'title': event['title'],
            'description': event['description'],
            'startDate': event['startDate'].toIso8601String(),
            'endDate': event['endDate'].toIso8601String(),
            'tag': {
              'name': event['tag']['name'],
              'color': event['tag']['color'].value,
            },
          },
        ));

    final dateIndexData = dateIndex
        .map((date, indices) => MapEntry(date.toIso8601String(), indices));

    final tagData = tags
        .map((tag) => {
              'name': tag['name'],
              'color': tag['color'].value,
            })
        .toList();

    final tagEventIndexData = tagEventIndex.map((tagName, eventIds) {
      return MapEntry(tagName, eventIds);
    });

    await prefs.setString('events', jsonEncode(eventData));
    await prefs.setString('dateIndex', jsonEncode(dateIndexData));
    await prefs.setString('tags', jsonEncode(tagData));
    await prefs.setString('tagEventIndex', jsonEncode(tagEventIndexData));
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final eventData = prefs.getString('events');
    final dateIndexData = prefs.getString('dateIndex');
    final tagData = prefs.getString('tags');
    final tagEventIndexData = prefs.getString('tagEventIndex');

    if (eventData != null) {
      events = (jsonDecode(eventData) as Map<String, dynamic>).map(
            (id, event) =>
            MapEntry(
              id,
              {
                'title': event['title'],
                'description': event['description'],
                'startDate': DateTime.parse(event['startDate']),
                'endDate': DateTime.parse(event['endDate']),
                'tag': {
                  'name': event['tag']['name'],
                  'color': Color(event['tag']['color']),
                },
              },
            ),
      );

      if (dateIndexData != null) {
        dateIndex = (jsonDecode(dateIndexData) as Map<String, dynamic>).map(
              (key, value) {
            return MapEntry(DateTime.parse(key), List<String>.from(value));
          },
        );
      }

      if (tagData != null) {
        tags = (jsonDecode(tagData) as List<dynamic>).map((tag) {
          return {
            'name': tag['name'],
            'color': Color(tag['color']),
          };
        }).toList();
      }

      if (tagEventIndexData != null) {
        tagEventIndex = (jsonDecode(tagEventIndexData) as Map<String, dynamic>)
            .map((tagName, eventIds) {
          return MapEntry(tagName, List<String>.from(eventIds));
        });
      }else{
        for (var tag in tags) {
          if (!tagEventIndex.containsKey(tag['name'])) {
            tagEventIndex[tag['name']] = [];
          }
        }
      }
    }
  }

  DateTime stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void createMode({required DateTime selectedDate}) {
    isEditing = false; // 작성 모드로 설정

    // 작성 모드로 넘어갈 때 초기값 설정
    selectedStartDateTime = selectedDate;
    selectedEndDateTime = selectedDate.add(Duration(hours: 1));
    titleController.clear();
    descriptionController.clear();
    selectedTag = tags[0];
    toggleScreen();
    notifyListeners(); // 상태 변경 알림
  }

  void editMode({required String eventId}) {
    isEditing = true;
    editingEventId = eventId;
    final editingEvent = events[editingEventId];
    // 수정 모드로 넘어갈 때 초기값 설정
    selectedStartDateTime = editingEvent?['startDate'];
    selectedEndDateTime = editingEvent?['endDate'];
    titleController.text = editingEvent?['title'];
    descriptionController.text = editingEvent?['description'] ?? '';
    selectedTag = tags.firstWhere(
          (tag) => tag['name'] == editingEvent?['tag']['name'],
      orElse: () => tags[0],
    );
    toggleScreen();
    notifyListeners(); // 상태 변경 알림
  }

  void editTagName({
    required int index,
    required String newName,
  }) {
    final oldName = tags[index]['name'];
    // 유효성 검사
    if (newName.isEmpty) {
      throw Exception('태그 이름을 입력해주세요!');
    } else if(oldName == newName) {
      return;
    } else if (tags.any((tag) => tag['name'] == newName)) {
      throw Exception('이미 존재하는 태그 이름입니다!');
    }

    // 태그 이름 업데이트
    tags[index]['name'] = newName;

    // 관련 이벤트 업데이트
    for (var event in events.values) {
      if (event['tag']['name'] == oldName) {
        event['tag']['name'] = newName;
      }
    }
    // tagEventIndex 최신화
    if (tagEventIndex.containsKey(oldName)) {
      tagEventIndex[newName] = tagEventIndex.remove(oldName)!;
    }

    saveData(); // 데이터 저장
    notifyListeners(); // 상태 변경 알림
  }

  void changeTagColor(int index,Color newColor) {
    // 태그 색상 변경
    tags[index]['color'] = newColor;

    // 해당 태그와 연결된 이벤트 색상 업데이트
    for (var event in events.values) {
      if (event['tag']['name'] == tags[index]['name']) {
        event['tag']['color'] = newColor;
      }
    }

    saveData(); // 데이터 저장
    notifyListeners(); // 상태 변경 알림

  }

  void addTag() {
    int newIndex = 1;
    String newTagName;

    // 새로운 태그 이름이 기존 태그와 겹치지 않도록 찾기
    do {
      newTagName = "태그 $newIndex";
      newIndex++;
    } while (tags.any((tag) => tag['name'] == newTagName));

    // 중복되지 않는 태그 이름으로 새로운 태그 추가
    tags.add({
      "name": newTagName,
      "color": Colors.grey, // 기본 색상
    });

    // tagEventIndex에 새로운 태그 추가
    tagEventIndex[newTagName] = [];
    notifyListeners(); // 상태 변경 알림
  }

  void deleteTag(int index) {
    final tagName = tags[index]["name"];

    tags.removeAt(index);

    // 선택된 태그가 삭제된 경우 처리
    if (selectedTag != null && selectedTag!["name"] == tagName) {
      selectedTag = tags[0] ; // 첫 번째 태그로 설정 (또는 null)
    }

    // 태그 인덱스 업데이트
    if (selectedTagIndex == index) {
      selectedTagIndex = 0;
    } else if (selectedTagIndex > index) {
      selectedTagIndex--;
    }
    // 태그와 연결된 모든 이벤트 삭제
    if (tagEventIndex.containsKey(tagName)) {
      final eventIds = List<String>.from(tagEventIndex[tagName]!); // 복사본 생성
      for (String eventId in eventIds) {
        if (events.containsKey(eventId)) {
          deleteEvent(eventId: eventId);
        }
      }
      tagEventIndex.remove(tagName);
    }
    saveData(); // 데이터 저장
    notifyListeners(); // 상태 변경 알림
  }

  void toggleScreen() {
    isCreatingEvent = !isCreatingEvent;
    notifyListeners(); // 상태 변경 알림
  }
}
