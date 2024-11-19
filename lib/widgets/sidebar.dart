import 'package:flutter/material.dart';
import '../widgets/dynamic_page.dart';
import '../to_do.dart';

class Sidebar extends StatefulWidget {
  final Function(String) addNewPageCallback; // 콜백 추가
  const Sidebar({
    this.addNewPageCallback = _defaultAddNewPageCallback, // 기본값 설정
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
    widget.addNewPageCallback(newPageName);
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

    // 최근 페이지 목록도 업데이트
    widget.addNewPageCallback(newTitle); // 제목이 변경되면 홈 화면의 목록도 업데이트
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
          onUpdate: (newTitle, newContent) {
            updatePageTitle(pageName, newTitle); // 페이지 제목 수정
            pageContents[newTitle] = newContent; // 내용 수정
          },
          onDelete: () {
            deletePage(pageName); // 페이지 삭제
            Navigator.pop(context);
          },
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
              // 홈으로 이동 (이 부분은 이미 구현이 되어 있어 변경 없음)
            },
          ),
          _buildSidebarItem(
            icon: Icons.search,
            label: '검색',
          ),
          _buildSidebarItem(
            icon: Icons.calendar_today,
            label: '달력',
          ),
          _buildSidebarItem(
            icon: Icons.checklist,
            label: '성과 관리 편람',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ToDoPage()),
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
            onTap: addNewPage, // 새 페이지 추가 로직 호출
          ),
          Divider(),
          // 최근 페이지 목록을 최대 5개까지만 표시
          Container(
            height: 300,
            child: ListView.builder(
              itemCount: pageNames.length > 5 ? 5 : pageNames.length,
              itemBuilder: (context, index) {
                return _buildSidebarItem(
                  icon: Icons.description_outlined,
                  label: pageNames[index],
                  onTap: () => navigateToPage(pageNames[index]),
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