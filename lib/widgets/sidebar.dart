import 'package:flutter/material.dart';
import '../calender.dart';
import '../home.dart';
import '../widgets/dynamic_page.dart';
import '../to_do.dart';
import '../search.dart';

class Sidebar extends StatefulWidget {
  final List<String> recentPages; // 상위에서 전달받는 페이지 리스트
  final Function(String) navigateToPage; // 페이지 이동 콜백
  final VoidCallback addNewPage; // 새 페이지 추가 콜백

  const Sidebar({
    required this.recentPages,
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
      }
    });
  }

  void deletePage(String pageName) {
    setState(() {
      pageNames.remove(pageName);
      pageContents.remove(pageName);
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicPage(
          title: pageName,
          content: pageContents[pageName] ?? '내용 없음',
          recentPages: pageNames, // recentPages 추가 (Sidebar의 pageNames 사용)
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
              // 현재 Navigator 스택을 모두 pop
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop(); // 현재 스택에서 pop
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              }
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
          // 최근 페이지 목록을 최대 5개까지만 표시
          Container(
            height: 300,
            child: ListView.builder(
              itemCount: widget.recentPages.length,
              itemBuilder: (context, index) {
                final pageName = widget.recentPages[index];
                return _buildSidebarItem(
                  icon: Icons.description_outlined,
                  label: pageName,
                  onTap: () => widget.navigateToPage(pageName),
                );
              },
            ),
          ),
          Spacer(),
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