import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ToDoData {
  List<Map<String, dynamic>> sections = [
    {
      'title': '사이버 교육수강',
      'items': [
        {'label': '청렴·윤리', 'checked': false},
        {'label': '인권(갑질)', 'checked': false},
        {'label': '노무역량 강화', 'checked': false},
        {'label': '개인정보보호', 'checked': false},
      ]
    },
    {
      'title': '삶의 질 제고 노력',
      'items': [
        {'label': '휴가(저축+연차) 50%이상 사용', 'checked': false},
        {'label': '보상휴가(전체) 70%이상 사용', 'checked': false},
        {'label': '보상휴가(금년도 발생) 100%이상 사용', 'checked': false},
        {'label': '유연근무 9주 이상 사용', 'checked': false},
      ]
    },
    {
      'title': '사회공헌 노력',
      'items': [
        {'label': '봉사활동 4시간 이상', 'checked': false},
      ]
    },
    {
      'title': 'PC보안 강화',
      'items': [
        {'label': '사이버보안진단의 날 [내PC 지킴이] 종합점수 100점 유지', 'checked': false},
      ]
    },
    {
      'title': '건강관리 노력',
      'items': [
        {'label': '건강검진 수검', 'checked': false},
      ]
    },
  ];

  // 상태 로드
  Future<void> loadSections() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedSections = prefs.getString('sections');
    if (savedSections != null) {
      sections = List<Map<String, dynamic>>.from(
        json.decode(savedSections).map((section) => {
          'title': section['title'],
          'items': List<Map<String, dynamic>>.from(section['items'])
        }),
      );
    }
  }

  // 상태 저장
  Future<void> saveSections() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('sections', json.encode(sections));
  }

  // 항목별 비율 계산
  double calculateProgress(List<Map<String, dynamic>> items) {
    final total = items.length;
    final checkedCount = items.where((item) => item['checked'] == true).length;
    return total == 0 ? 0 : checkedCount / total;
  }

  // 전체 진행률 계산
  double calculateOverallProgress() {
    int totalItems = 0;
    int totalChecked = 0;

    for (final section in sections) {
      final items = section['items'] as List<Map<String, dynamic>>;
      totalItems += items.length;
      totalChecked += items.where((item) => item['checked'] == true).length;
    }

    return totalItems == 0 ? 0 : totalChecked / totalItems;
  }
}