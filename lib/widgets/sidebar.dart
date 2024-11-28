import 'package:flutter/material.dart';
import '../calender.dart';
import '../home.dart';
import '../widgets/dynamic_page.dart';
import '../to_do.dart';
import '../search.dart';

class Sidebar extends StatefulWidget {
  final List<String> recentPages; // 상위에서 전달받는 페이지 리스트
  final Map<String, List<Map<String, String>>> inlinePages;
  final Function(String) navigateToPage; // 페이지 이동 콜백
  final VoidCallback addNewPage; // 새 페이지 추가 콜백

  const Sidebar({
    required this.recentPages,
    required this.inlinePages,
    required this.navigateToPage,
    required this.addNewPage,
    Key? key,
  }) : super(key: key);

  static void _defaultAddNewPageCallback(String pageName) {
    // 기본 동작: 아무 작업도 하지 않음
  }
  @override
  _SidebarState createState() => _SidebarState();
}

// 페이지별로 인라인 페이지를 표시하기 위한 상태 관리
Map<String, bool> _expandedPages = {};

class _SidebarState extends State<Sidebar> {
  bool isSidebarOpen = true;
  List<String> pageNames = []; // 동적으로 추가된 페이지 이름 목록
  Map<String, String> pageContents = {}; // 페이지 제목과 내용 관리
  int pageCounter = 1; // 페이지 숫자 관리

  void addNewPage() {
    String newPageName = 'Page $pageCounter';
    pageCounter++;
    setState(() {
      pageNames.insert(0, newPageName);
      pageContents[newPageName] = "기본 내용입니다."; // 새 페이지에 기본 내용 추가
      widget.inlinePages[newPageName] = []; // 새 페이지의 인라인 페이지 초기화

    });
  }
  // 페이지 제목 수정
  void updatePageTitle(String oldTitle, String newTitle) {
    setState(() {
      // 페이지 이름과 내용을 업데이트
      int index = pageNames.indexOf(oldTitle);
      if (index != -1) {
        pageNames[index] = newTitle; // 제목 업데이트
        pageContents[newTitle] = pageContents[oldTitle] ?? '기본 내용입니다.'; // 내용 유지
        pageContents.remove(oldTitle); // 이전 제목 삭제
        widget.inlinePages[newTitle] = widget.inlinePages[oldTitle] ?? []; // 인라인 페이지 이동
        widget.inlinePages.remove(oldTitle); // 이전 인라인 페이지 제거
      }
    });
  }

  void deletePage(String pageName) {
    setState(() {
      pageNames.remove(pageName);
      pageContents.remove(pageName);
      widget.inlinePages.remove(pageName); // 해당 페이지의 인라인 페이지 삭제
    });
  }

  void _toggleSidebar() {
    setState(() {
      isSidebarOpen = !isSidebarOpen;
    });
  }
  // setState(() {
  //   pageNames.add(newPageName); // 페이지 이름 추가
  // });

  // void updatePage(String pageName, String newTitle, String newContent) {
  //   setState(() {
  //     // 제목 또는 내용을 업데이트
  //     if (pageContents.containsKey(pageName)) {
  //       pageContents[pageName] = newContent;
  //     }
  //
  //     // 제목 변경 시 순서도 업데이트
  //     if (pageNames.contains(pageName)) {
  //       int index = pageNames.indexOf(pageName);
  //       pageNames[index] = newTitle;
  //     }
  //   });
  // }
  void navigateToPage(String pageName) {
    // 페이지에 해당하는 인라인 페이지 데이터를 안전하게 가져오기
    final inlinePageData = widget.inlinePages.containsKey(pageName)
        ? widget.inlinePages[pageName]
        : {}; // 키가 없을 경우 빈 Map으로 대체

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicPage(
          title: pageName,
          content: pageContents[pageName] ?? '내용 없음',
          recentPages: pageNames, // recentPages 추가 (Sidebar의 pageNames 사용)
          inlinePages: inlinePageData as Map<String, List<Map<String, String>>>, // 명시적으로 타입 캐스팅
          navigateToPage: navigateToPage, // 페이지 간 이동 콜백 전달
          onUpdate: (newTitle, newContent) {
            updatePageTitle(pageName, newTitle); // 페이지 제목 수정
            pageContents[newTitle] = newContent; // 내용 수정
          },
          onDelete: () {
            deletePage(pageName); // 페이지 삭제
            Navigator.pop(context);
          },
          addNewPage: widget.addNewPage, // addNewPage 추가
        ),
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    for (var page in widget.recentPages) {
      _expandedPages[page] = true;
    }
  }



  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: isSidebarOpen ? 200 : 70,
      color: Color(0xFFF5F5F3),
      child: Column(
        children: [
          SizedBox(height: 10),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(isSidebarOpen ? Icons.chevron_left : Icons.chevron_right),
              onPressed: () {
                _toggleSidebar();
              },
            ),
          ),
          _buildSidebarItem(
            icon: Icons.home_outlined,
            label: '홈',
            onTap: () {
              // 홈 버튼 클릭 시 HomeScreen으로 이동
              Navigator.popUntil(context, (route) => route.isFirst); // 스택을 초기화하고 첫 화면으로 돌아감);
            },
          ),
          _buildSidebarItem(
            icon: Icons.search,
            label: '검색',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SearchPage(
                      recentPages: widget.recentPages,
                      inlinePages: widget.inlinePages,
                      navigateToPage: widget.navigateToPage,
                      addNewPage: widget.addNewPage,
                )),
              );
            },
          ),
          _buildSidebarItem(
            icon: Icons.calendar_today,
            label: '달력',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarPage(
                  recentPages: widget.recentPages,
                  inlinePages: widget.inlinePages,
                  navigateToPage: widget.navigateToPage,
                  addNewPage: widget.addNewPage,
                )),
              );
            },
          ),
          // 홈 버튼 클릭 시 캘린더 페이지로 이동
          _buildSidebarItem(
            icon: Icons.checklist,
            label: '성과 관리 편람',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ToDoPage(
                  recentPages: widget.recentPages,
                  inlinePages: widget.inlinePages,
                  navigateToPage: widget.navigateToPage,
                  addNewPage: widget.addNewPage,
                )),
              );
            },
          ),
          _buildSidebarItem(
            icon: Icons.language,
            label: '대외 웹사이트',
          ),
          _buildSidebarItem(
            icon: Icons.add,
            label: '새 페이지',
            onTap: widget.addNewPage, // 새 페이지 추가 로직 호출
          ),
          Divider(),
          Container(
            height: 300,
            child: ListView.builder(
              itemCount: widget.recentPages.length,
              itemBuilder: (context, index) {
                final pageName = widget.recentPages[index];
                final inlinePages = widget.inlinePages[pageName] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Icon(Icons.description_outlined, color: Color(0xFF91918E)),
                      title: isSidebarOpen ? Text(pageName) : null,
                      onTap: () => widget.navigateToPage(pageName),
                      trailing: isSidebarOpen && inlinePages.isNotEmpty
                          ? IconButton(
                        icon: Icon(
                          _expandedPages[pageName] ?? true
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        onPressed: () {
                          setState(() {
                            _expandedPages[pageName] = !_expandedPages[pageName]!;
                          });
                        },
                      )
                          : null,
                    ),
                    if (_expandedPages[pageName] ?? true && inlinePages.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(left: 16.0),
                        child: Column(
                          children: inlinePages.map((inlinePage) {
                            return ListTile(
                              leading: Icon(
                                Icons.subdirectory_arrow_right,
                                color: Color(0xFF91918E),
                              ),
                              title: isSidebarOpen ? Text(inlinePage['title'] ?? '') : null,
                              onTap: () {
                                widget.navigateToPage(inlinePage['title']!);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Spacer(), // 기존 Spacer 유지
          _buildSidebarItem(
            icon: Icons.delete,
            label: '휴지통',
          ),
          _buildSidebarItem(
            icon: Icons.settings,
            label: '설정',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF91918E)),
      title: isSidebarOpen ? Text(label) : null,
      onTap: onTap,
    );
  }
}