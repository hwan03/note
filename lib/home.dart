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
          jsonDecode(storedPages).map(
              (key, value) => MapEntry(key, Map<String, dynamic>.from(value))),
        );
      });
    }
  }

  Future<void> _savePages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pages', jsonEncode(pages));
    setState(() {}); // 저장 후 상태를 강제로 다시 반영
  }

  void addNewPage({String? parent}) async {
    String newPageName;

    // 숫자만 추출하고 정렬
    List<int> pageNumbers = pages.keys
        .where(
            (key) => RegExp(r'^Page (\d+)$').hasMatch(key)) // "Page X" 형식 필터링
        .map((key) =>
            int.parse(RegExp(r'^Page (\d+)$').firstMatch(key)!.group(1)!))
        .toList()
      ..sort();

    // 비어 있는 숫자 찾기
    int? missingNumber;
    for (int i = 1; i <= pageNumbers.length; i++) {
      if (!pageNumbers.contains(i)) {
        missingNumber = i;
        break;
      }
    }

    // 비어 있는 숫자가 있으면 사용, 없으면 다음 숫자로 설정
    if (missingNumber != null) {
      newPageName = 'Page $missingNumber';
    } else {
      newPageName = 'Page ${pageNumbers.isEmpty ? 1 : pageNumbers.last + 1}';
    }

    setState(() {
      pages[newPageName] = {'content': '', 'parent': parent};
    });

    // 비동기 저장
    await _savePages();

    _navigateToPage(newPageName);
  }

  void _updatePage(String oldTitle, String newTitle, String content) {
    setState(() {
      if (oldTitle != newTitle) {
        pages.forEach((key, value) {
          if (value['parent'] == oldTitle) {
            value['parent'] = newTitle;
          }
        });
        pages[newTitle] = pages.remove(oldTitle)!;
      }
      pages[newTitle]!['content'] = content;
    });
    _savePages();
  }

  void _deletePage(String title) {
    void _deleteWithChildren(String pageName) {
      final children = pages.entries
          .where((entry) => entry.value['parent'] == pageName)
          .map((entry) => entry.key)
          .toList();
      for (final child in children) {
        _deleteWithChildren(child);
      }
      pages.remove(pageName);
    }

    setState(() {
      _deleteWithChildren(title);
    });
    _savePages();
  }

  void _navigateToPage(String pageName) {
    setState(() {
      // 해당 페이지를 목록의 맨 앞으로 이동
      final pageData = pages.remove(pageName);
      if (pageData != null) {
        pages = {pageName: pageData, ...pages};
      }
    });
    _savePages().then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DynamicPage(
            title: pageName,
            onUpdate: (updatedTitle, updatedContent) {
              setState(() {
                if (updatedTitle != pageName) {
                  // 제목 변경 반영 및 순서 업데이트
                  final pageData = pages.remove(pageName);
                  if (pageData != null) {
                    pageData['content'] = updatedContent;
                    pages = {
                      updatedTitle: pageData,
                      ...pages,
                    };
                  }
                } else {
                  // 내용만 업데이트
                  pages[pageName]!['content'] = updatedContent;

                  // 페이지를 최근으로 이동
                  final pageData = pages.remove(pageName);
                  if (pageData != null) {
                    pages = {pageName: pageData, ...pages};
                  }
                }
              });
              _savePages(); // 변경 저장
            },
            onDelete: () {
              _deletePage(pageName);
              Navigator.pop(context); // 페이지 삭제 후 뒤로 이동
            },
            onAddPage: (newPageName, parent) {
              addNewPage(parent: parent);
            },
          ),
        ),
      );
    });
  }
  String _getCurrentDateWithDay() {
    final DateTime now = DateTime.now();
    const List<String> weekdays = [
      '일', '월', '화', '수', '목', '금', '토'
    ];
    final String dayName = weekdays[now.weekday % 7]; // 요일 가져오기

    return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} ($dayName)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            pages: pages,
            navigateToPage: _navigateToPage,
            addNewPage: addNewPage,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _buildLabeledBox(
                label: '최근 페이지',
                child: SizedBox(
                  height: 300, // 고정된 높이 설정

                  child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),

                      //밑에거하면 인라인 페이지도 홈 목록에 다 나옴
                      itemCount: pages.length.clamp(0, 4),
                      itemBuilder: (context, index) {
                        String pageName = pages.keys.toList()[index];

                        return GestureDetector(
                          onTap: () => _navigateToPage(pageName), // 페이지 선택 시 이동
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
                                    border:
                                        Border.all(color: Color(0xFFF2F1EE)),
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15)),
                                    color: Color(0xFFF2F1EE),
                                  ),
                                  alignment: Alignment.bottomLeft,
                                  child: Icon(
                                    Icons.description_outlined,
                                    size: 40,
                                    color: Color(0xFF91918E),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pageName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          _getCurrentDateWithDay(), // 현재 날짜와 시간을 표시
                                        ),
                        ]),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ),SizedBox(height: 20),
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
