import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:new_flutter/state/scheduleState.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'widgets/todo_data.dart';
import 'widgets/summary_chart.dart';
import 'package:new_flutter/widgets/buildSchedule.dart';
import 'widgets/sidebar.dart';
import 'widgets/dynamic_page.dart';
import 'package:flutter/services.dart'; // Orientation 설정에 필요

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 바인딩 초기화
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ToDoData()),
          ChangeNotifierProvider(create: (context) => ScheduleState()),
        ],
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      locale: Locale('ko', 'KR'), // 한국어 설정
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ko', 'KR'), // 한국어 지원
        Locale('en', 'US'), // 기본 영어
      ],
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
    _loadPages();
    final scheduleState = context.read<ScheduleState>(); // 한 번 호출
    scheduleState.loadData();
    // 앱 시작 시 저장된 데이터 불러오기
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

  void _deletePage(String title) async{
    final prefs = await SharedPreferences.getInstance();

    void _deleteWithChildren(String pageName) async {
      final prefs = await SharedPreferences.getInstance();

      // 자식 페이지들 찾기
      final children = pages.entries
          .where((entry) => entry.value['parent'] == pageName)
          .map((entry) => entry.key)
          .toList();

      // 자식 페이지들에 대해 재귀적으로 삭제
      for (final child in children) {
        _deleteWithChildren(child); // 자식 페이지 삭제 (재귀)
      }

      // 현재 페이지와 관련된 데이터 삭제
      setState(() {
        pages.forEach((key, value) {
          if (value['parent'] == pageName) {
            value['parent'] = null; // 부모 관계 초기화
          }
        });
        pages.remove(pageName); // 페이지 삭제
      });

      // SharedPreferences에서 삭제
      await prefs.remove(pageName); // 페이지 데이터 제거
      await prefs.remove('${pageName}_parent'); // 부모 관계 제거
      await prefs.setString('pages', jsonEncode(pages)); // 변경된 페이지 데이터 저장
    }


    setState(() {
      _deleteWithChildren(title); // 부모와 자식 페이지 모두 삭제
      pages = Map<String, Map<String, dynamic>>.from(pages); // 상태 갱신
    });
    // SharedPreferences에 갱신된 pages 저장
    await prefs.setString('pages', jsonEncode(pages));

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
                    pages = {updatedTitle: pageData, ...pages,};
                  }
                } else {
                  // 내용만 업데이트
                  pages[pageName]?['content'] = updatedContent;

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
              setState(() {
      pages.remove(pageName);
      });
      _savePages();
      },
            onAddPage: (newPageName, parent) {
              addNewPage(parent: parent);
            },
          ),
        ),
      ).then((_) => _loadPages());;
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
    final scheduleState = Provider.of<ScheduleState>(context, listen: true);
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
                SizedBox(
                  height: 300, // 고정된 높이 설정

                  child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),

                      //밑에거하면 인라인 페이지도 홈 목록에 다 나옴
                    itemCount: pages.entries
                        .where((entry) => entry.value['parent'] == null)
                        .length
                        .clamp(0, 4), // 부모 페이지만 표시
                    itemBuilder: (context, index) {
                      final filteredPages = pages.entries
                          .where((entry) => entry.value['parent'] == null) // 부모가 없는 페이지만 필터링
                          .toList();
                      String pageName = filteredPages[index].key;
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
                            child: BuildSchedule(scheduleState: scheduleState,isHome: true,
                              scrollController: ItemScrollController(),
                            )
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