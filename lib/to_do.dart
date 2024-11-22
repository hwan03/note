import 'package:flutter/material.dart';
import 'widgets/todo_data.dart'; // ToDoData 클래스 임포트
import 'widgets/sidebar.dart'; // Sidebar import
import 'widgets/summary_chart.dart'; // SummarySection import

class ToDoPage extends StatefulWidget {
  @override
  _ToDoPageState createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  final ToDoData toDoData = ToDoData(); // ToDoData 인스턴스 생성

  @override
  void initState() {
    super.initState();
    _initializeData(); // 데이터 초기화
  }

  Future<void> _initializeData() async {
    await toDoData.loadSections(); // 저장된 데이터 불러오기
    setState(() {}); // 화면 갱신
  }

  @override
  Widget build(BuildContext context) {
    final overallProgress = toDoData.calculateOverallProgress(); // 전체 이행률 계산

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
                                SummaryChart(toDoData: toDoData)
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
                              children: toDoData.sections.map((section) {
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
                                          toDoData.saveSections(); // 변경 사항 저장
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