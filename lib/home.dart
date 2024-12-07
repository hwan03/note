import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'widgets/todo_data.dart';
import 'widgets/summary_chart.dart';
import 'widgets/sidebar.dart';
import 'widgets/dynamic_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ToDoData(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ToDoData toDoData = ToDoData(); // ToDoData 인스턴스 생성

  Map<String, Map<String, dynamic>> pages = {
    'Home': {'content': 'Welcome to Home', 'parent': null},
  };


  @override
  void initState() {
    super.initState();
    _loadPages(); // 앱 시작 시 저장된 데이터 불러오기
  }

  Future<void> _loadPages() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPages = prefs.getString('pages');

    if (storedPages != null) {
      setState(() {
        pages = Map<String, Map<String, dynamic>>.from(
          jsonDecode(storedPages).map((key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value))),
        );
      });
    }
  }

  Future<void> _savePages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pages', jsonEncode(pages));
  }

  void addNewPage() {
    final newPageName = 'Page ${pages.length + 1}';
    setState(() {
      pages[newPageName] = {'content': '', 'parent': null};
      _savePages(); // 상태를 저장
      print('새 페이지 추가: $newPageName'); // 디버깅 출력
    });
    navigateToPage(newPageName);

  }


  void navigateToPage(String pageName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DynamicPage(
              title: pageName,
              onUpdate: (updatedTitle, updatedContent) {
                setState(() {
                  if (updatedTitle != pageName) {
                    pages[updatedTitle] = pages.remove(pageName)!;
                  }
                  pages[updatedTitle]?['content'] = updatedContent;
                });
                _savePages(); // 변경 사항 저장
              },
              onDelete: () {
                setState(() {
                  pages.remove(pageName);
                });
                _savePages(); // 삭제 후 저장
                Navigator.pop(context);
              },
            ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            pages: pages,
            navigateToPage: navigateToPage,
            addNewPage: addNewPage,
          )
          ,
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('최근 페이지',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  SizedBox(height: 10),
                  Expanded(
                    flex: 2,
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: pages.keys.length,
                      itemBuilder: (context, index) {
                        final pageName = pages.keys.toList()[index];
                        return GestureDetector(
                          onTap: () => navigateToPage(pageName), // 페이지 선택 시 이동
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFF2F1EE)),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            // padding: EdgeInsets.all(8),
                            // padding: E
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Color(0xFFF2F1EE)),
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15)),
                                    color: Color(0xFFF2F1EE),
                                  ),
                                  alignment: Alignment.bottomLeft,
                                  child: Icon(Icons.description_outlined,
                                    size: 40, color: Color(0xFF91918E),),

                                ),
                                Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pageName,
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text('2024.01.15'),
                                      ]),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // 성과 관리 편람
                        Expanded(
                          child: _buildLabeledBox(
                            label: '성과 관리 편람',
                            child: Container(
                              margin: EdgeInsets.only(bottom: 16), // 추가된 부분
                              padding: EdgeInsets.all(16), // 추가된 부분
                              child: Center(
                                child: SummaryChart(
                                    toDoData: context.watch<ToDoData>()),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildLabeledBox(
                            label: '일정',
                            child: ListView.builder(
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: const [
                                      Expanded(
                                        flex: 2,
                                        child: Text('월요일 11월 6일',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500)),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text('○○ 미팅'),
                                            Text('9AM',
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildLabeledBox({required String label, required Widget child}) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFF2F1EE)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.only(top: 24),
          child: child,
        ),
        Positioned(
          left: 16,
          top: 0,
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }
}




