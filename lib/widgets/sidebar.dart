import 'package:flutter/material.dart';
import '../calender.dart';
import '../home.dart';
import '../widgets/dynamic_page.dart';
import '../to_do.dart';
import '../search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    setState(() {
      final newPageName = 'Page ${pageCounter++}';
      pageNames.insert(0, newPageName);
      pageContents[newPageName] = "기본 내용입니다.";
      widget.inlinePages[newPageName] = [];

      if (!widget.recentPages.contains(newPageName)) {
        widget.recentPages.insert(0, newPageName);
      }
    });
    _savePages(); // SharedPreferences에 저장
    navigateToPage(pageNames.first);
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
        widget.inlinePages[newTitle] = widget.inlinePages.remove(oldTitle) ?? []; // 인라인 페이지 이동
      }
    });
    _savePages();
  }

  void deletePage(String pageName) {
    setState(() {
      pageNames.remove(pageName);
      pageContents.remove(pageName);
      widget.inlinePages.remove(pageName); // 해당 페이지의 인라인 페이지 삭제
    });
    _savePages(); // SharedPreferences에 저장
  }

  void _toggleSidebar() {
    setState(() {
      isSidebarOpen = !isSidebarOpen;
    });
  }

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
          recentPages: widget.recentPages,
          inlinePages: widget.inlinePages,
          navigateToPage: widget.navigateToPage,
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
    _loadPages();
    for (var page in widget.recentPages) {
      _expandedPages[page] = true;
    }
  }

  Future<void> _loadPages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPages = prefs.getString('pages'); // 저장된 페이지 데이터
    if (savedPages != null) {
      setState(() {
        final decodedPages = Map<String, String>.from(json.decode(savedPages));
        pageNames = decodedPages.keys.toList(); // 페이지 이름 리스트
        pageContents = decodedPages; // 페이지 내용
        pageCounter = pageNames.length + 1; // 카운터 갱신
      });
    }
  }

  Future<void> _savePages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pages', json.encode(pageContents));
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
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
            onTap: addNewPage, // 새 페이지 추가 로직 호출
          ),
          Divider(),
          Container(
            height: 300,
            child: ListView.builder(
              itemCount: widget.recentPages.length,
              itemBuilder: (context, index) {
                final pageName = widget.recentPages[index];
                final inlinePagesForPage = widget.inlinePages[pageName] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Icon(Icons.description_outlined, color: Color(0xFF91918E)),
                      title: isSidebarOpen ? Text(pageName) : null,
                      onTap: () => widget.navigateToPage(pageName),
                    ),
                    ...inlinePagesForPage.map((inlinePage) {
                      return ListTile(
                        leading: Icon(Icons.subdirectory_arrow_right),
                        title: Text(inlinePage['title'] ?? ''),
                        onTap: () => widget.navigateToPage(inlinePage['title']!),
                      );
                    }).toList(),
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