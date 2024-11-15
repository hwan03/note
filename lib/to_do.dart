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
      'items': ['청렴·윤리', '인권(갑질)', '노무역량 강화', '개인정보보호']
    },
    {
      'title': '삶의 질 제고 노력',
      'items': ['휴가(저축+연차) 50%이상 사용', '보상휴가(전체) 70%이상 사용', '보상휴가(금년도 발생) 100%이상 사용', '유연근무 9주 이상 사용']
    },
    {
      'title': '사회공헌 노력',
      'items': ['봉사활동 4시간 이상']
    },
    {
      'title': 'PC보안 강화',
      'items': ['사이버보안진단의 날 [내PC 지킴이] 종합점수 100점 유지']
    },
    {
      'title': '건강관리 노력',
      'items': ['건강검진 수검']
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(), // Sidebar widget 사용
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
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
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                                    (itemIndex) => CheckboxListTile(
                                  title: Text(section['items'][itemIndex]),
                                  value: false,
                                  onChanged: (value) {},
                                  controlAffinity:
                                  ListTileControlAffinity.leading,
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