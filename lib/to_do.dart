import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // JSON 변환용
import 'widgets/sidebar.dart'; // Sidebar import

class ToDoPage extends StatefulWidget {
  @override
  _ToDoPageState createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
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

  @override
  void initState() {
    super.initState();
    _loadSections(); // 상태 로드
  }

  Future<void> _loadSections() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedSections = prefs.getString('sections');
    if (savedSections != null) {
      setState(() {
        sections = List<Map<String, dynamic>>.from(
          json.decode(savedSections).map((section) => {
            'title': section['title'],
            'items': List<Map<String, dynamic>>.from(section['items'])
          }),
        );
      });
    }
  }

  Future<void> _saveSections() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('sections', json.encode(sections));
  }

  double _calculateProgress(List<Map<String, dynamic>> items) {
    final total = items.length;
    final checkedCount = items.where((item) => item['checked'] == true).length;
    return total == 0 ? 0 : checkedCount / total;
  }

  double _calculateOverallProgress() {
    int totalItems = 0;
    int totalChecked = 0;

    for (final section in sections) {
      final items = section['items'] as List<Map<String, dynamic>>;
      totalItems += items.length;
      totalChecked += items.where((item) => item['checked'] == true).length;
    }

    return totalItems == 0 ? 0 : totalChecked / totalItems;
  }

  @override
  Widget build(BuildContext context) {
    final overallProgress = _calculateOverallProgress(); // 전체 이행률 계산

    return Scaffold(
      body: Row(
        children: [
          Sidebar(), // Sidebar widget 사용
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '성과 관리 편람',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '2024 성과관리편람 개인이행항목',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // 전체 이행률 표시 부분
                  Row(
                    children: [
                      Text(
                        '전체 이행률: ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: overallProgress,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: overallProgress > 0.7
                                      ? Colors.green
                                      : overallProgress > 0.3
                                      ? Colors.orange
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Center(
                                child: Text(
                                  '${(overallProgress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // 흰색 글씨
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // 스크롤 가능한 전체 컨텐츠
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 이행률 요약 블록
                          Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFF2F1EE)),
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '이행률 요약',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                ...sections.map((section) {
                                  final progress = _calculateProgress(section['items']);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            section['title'],
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 5,
                                          child: Stack(
                                            children: [
                                              Container(
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                              ),
                                              FractionallySizedBox(
                                                widthFactor: progress,
                                                child: Container(
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: progress > 0.7
                                                        ? Colors.green
                                                        : progress > 0.3
                                                        ? Colors.orange
                                                        : Colors.red,
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 0,
                                                left: 0,
                                                right: 0,
                                                bottom: 0,
                                                child: Center(
                                                  child: Text(
                                                    '${(progress * 100).toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),

                          // 체크리스트 섹션
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFF2F1EE)),
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sections.map((section) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      section['title'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    ...section['items'].map<Widget>((item) {
                                      return CheckboxListTile(
                                        title: Text(item['label']),
                                        value: item['checked'],
                                        onChanged: (value) {
                                          setState(() {
                                            item['checked'] = value;
                                          });
                                          _saveSections();
                                        },
                                      );
                                    }).toList(),
                                    SizedBox(height: 10),
                                    Divider(color: Color(0xFFF2F1EE)), // 구분선 추가
                                    SizedBox(height: 10),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
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
}