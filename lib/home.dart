import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_flutter/widgets/dynamic_page.dart';
import 'package:new_flutter/widgets/sidebar.dart';
import 'widgets/todo_data.dart';
import 'widgets/summary_chart.dart';

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

  List<String> recentPages = []; // 최근 페이지 목록
  Map<String, String> pageContents = {}; // 페이지 제목과 내용의 Map 선언
  Map<String, List<Map<String, String>>> inlinePages = {}; // 각 페이지별 인라인 페이지 관리
  int pageCounter = 1; // 페이지 숫자 관리
  ScrollController _recentPagesController = ScrollController();

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

  void addNewPage() {
    setState(() {
      final newPageName = 'Page $pageCounter';
      pageCounter++;
      recentPages.insert(0, newPageName);
      pageContents[newPageName] = '';
      inlinePages[newPageName] = []; // 새 페이지에 대한 인라인 페이지 초기화
    });
    navigateToPage(recentPages.first); // 새 페이지로 이동
  }

  //setState(() {
  //       recentPages.add(pageName);
  //     });
  //
  // import 'package:flutter/material.dart';
  //
  // void main() {
  //   runApp(MyApp());
  // } 이거로 하면 최근 페이지부터 나오는거 아님

  void addInlinePage(String parentPage) {
    final inlinePageTitle = 'Inline Page ${inlinePages[parentPage]?.length ??
        0 + 1}';
    setState(() {
      inlinePages[parentPage]?.add({'title': inlinePageTitle, 'content': ''});
    });
  }

  // 페이지 제목 수정 시 최근 페이지 목록과 동기화
  void updatePage(String oldTitle, String newTitle, String newContent) {
    setState(() {
      pageContents.remove(oldTitle); // 기존 제목 제거
      pageContents[newTitle] = newContent; // 새 제목과 내용 추가

      int index = recentPages.indexOf(oldTitle);
      if (index != -1) {
        recentPages[index] = newTitle; // 최근 페이지에서 제목 변경
      }

      // 인라인 페이지 제목도 동기화
      inlinePages[newTitle] = inlinePages.remove(oldTitle) ?? [];
    });
  }


// 페이지 삭제
  void deletePage(String pageName) {
    setState(() {
      pageContents.remove(pageName); // 해당 페이지 내용 제거
      recentPages.remove(pageName); // 해당 페이지를 최근 페이지에서 제거
      inlinePages.remove(pageName); // 해당 페이지의 인라인 페이지 삭제
    });
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void navigateToPage(String pageName) {
    FocusScope.of(context).unfocus(); // 현재 페이지 포커스 해제 및 데이터 저장
    setState(() {
      if (!pageContents.containsKey(pageName)) {
        pageContents[pageName] = ''; // 새 페이지 내용 초기화
      }
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DynamicPage(
              title: pageName,
              content: pageContents[pageName] ?? '',
              recentPages: recentPages,
              inlinePages: {
                pageName: (inlinePages[pageName] as List<
                    Map<String, String>>?) ?? [],
              },
              // 데이터 타입 변환
              navigateToPage: navigateToPage,
              onUpdate: (newTitle, newContent) {
                setState(() {
                  final index = recentPages.indexOf(pageName);
                  if (index != -1) recentPages[index] = newTitle;
                  pageContents.remove(pageName);
                  pageContents[newTitle] = newContent;

                  // 인라인 페이지 제목 동기화
                  inlinePages[newTitle] = inlinePages.remove(pageName) ?? [];
                });
              },
              onDelete: () => deletePage(pageName),
              addNewPage: addNewPage, // addNewPage 추가
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
            recentPages: recentPages,
            inlinePages: inlinePages,
            navigateToPage: navigateToPage,
            addNewPage: addNewPage,
          ),
          // Main Content
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
                      itemCount: recentPages.length,
                      itemBuilder: (context, index) {
                        final pageName = recentPages[index];
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
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recentPages[index],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
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
}