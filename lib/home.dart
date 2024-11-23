import 'package:flutter/material.dart';
import 'package:new_flutter/widgets/dynamic_page.dart';
import 'package:new_flutter/widgets/sidebar.dart';

void main() {
  runApp(MyApp());
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
  List<String> recentPages = []; // 최근 페이지 목록
  Map<String, String> pageContents = {}; // 페이지 제목과 내용의 Map 선언
  int pageCounter = 1; // 페이지 숫자 관리
  ScrollController _recentPagesController = ScrollController();

  void addNewPage() {
    setState(() {
      final newPageName = 'Page $pageCounter';
      pageCounter++;
      recentPages.insert(0, newPageName);
      pageContents[newPageName] = '새 페이지의 내용입니다.';
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

  // 페이지 제목 수정 시 최근 페이지 목록과 동기화
  void updatePage(String oldTitle, String newTitle, String newContent) {
    setState(() {
      pageContents.remove(oldTitle); // 기존 제목 제거
      pageContents[newTitle] = newContent; // 새 제목과 내용 추가

      int index = recentPages.indexOf(oldTitle);
      if (index != -1) {
        recentPages[index] = newTitle; // 최근 페이지에서 제목 변경
      }
    });
  }

  // 페이지 삭제
  void deletePage(String pageName) {
    setState(() {
      pageContents.remove(pageName); // 해당 페이지 내용 제거
      recentPages.remove(pageName); // 해당 페이지를 최근 페이지에서 제거
    });
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void navigateToPage(String pageName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicPage(
          title: pageName,
          content: pageContents[pageName] ?? '내용 없음',
          recentPages: recentPages,
          navigateToPage: navigateToPage,
          onUpdate: (newTitle, newContent) {
            setState(() {
              final index = recentPages.indexOf(pageName);
              if (index != -1) recentPages[index] = newTitle;
              pageContents.remove(pageName);
              pageContents[newTitle] = newContent;
            });
          },
          onDelete:() => deletePage(pageName),
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
                                  border: Border.all(color: Color(0xFFF2F1EE)),
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
                            child: Center(
                              child: Text('성과 내용 없음'),
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
    return Container(
      child: Stack(
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
      ),
    );
  }
}