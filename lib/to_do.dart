import 'package:flutter/material.dart';
import 'widgets/sidebar.dart'; // Sidebar import

class ToDoPage extends StatefulWidget {
  @override
  _ToDoPageState createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  final List<Map<String, dynamic>> sections = [
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

  double _calculateProgress(List<Map<String, dynamic>> items) {
    final total = items.length;
    final checkedCount = items.where((item) => item['checked'] == true).length;
    return total == 0 ? 0 : checkedCount / total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(), // Sidebar widget 사용
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white, // 전체 배경색 흰색으로 설정
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
                  Expanded(
                    child: ListView.builder(
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        final section = sections[index];
                        final progress = _calculateProgress(section['items']);
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            // color: Colors.grey[200],
                            border: Border.all(color: Color(0xFFF2F1EE)),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      section['title'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ...List.generate(
                                      section['items'].length,
                                          (itemIndex) {
                                        final item =
                                        section['items'][itemIndex];
                                        return CheckboxListTile(
                                          title: Text(item['label']),
                                          value: item['checked'],
                                          onChanged: (value) {
                                            setState(() {
                                              item['checked'] = value;
                                            });
                                          },
                                          controlAffinity:
                                          ListTileControlAffinity.leading,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '진행률',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Stack(
                                      children: [
                                        Container(
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                            BorderRadius.circular(10),
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
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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