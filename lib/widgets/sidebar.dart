import 'package:flutter/material.dart';
import '../calendar.dart';
import '../main.dart';
import '../to_do.dart';
import '../search.dart';
import '../web_link.dart';

class Sidebar extends StatefulWidget {
  final Map<String, Map<String, dynamic>> pages; // 페이지 목록
  final Function(String) navigateToPage; // 페이지 이동 함수
  final VoidCallback addNewPage; // 페이지 추가 함수

  const Sidebar({
    required this.pages,
    required this.navigateToPage,
    required this.addNewPage,
    Key? key,
  }) : super(key: key);

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool isSidebarOpen = true;
  bool isTextVisible = true; // 텍스트 표시 여부 초기화

  void _toggleSidebar() {
    if (!isSidebarOpen) {
      // 열릴 때: 애니메이션 후 텍스트 표시
      setState(() {
        isSidebarOpen = true;
      });
      Future.delayed(Duration(milliseconds: 300), () {
        setState(() {
          isTextVisible = true;
        });
      });
    } else {
      // 닫힐 때: 즉시 텍스트 숨김
      setState(() {
        isTextVisible = false;
        isSidebarOpen = false;
      });
    }
  }

  List<Widget> _buildChevronIcons(String? parent) {
    List<Widget> chevrons = [];
    String? currentParent = parent;

    while (currentParent != null) {
      chevrons
          .add(Icon(Icons.chevron_right, color: Color(0xFF91918E), size: 16));
      currentParent = widget.pages[currentParent]?['parent']; // 부모를 따라 계층 추적
    }

    // while (currentParent != null) {
    //   chevrons.add(
    //     Text(
    //       '> ',
    //       style: TextStyle(color: Color(0xFF91918E), fontSize: 14), // 스타일 지정
    //     ),
    //   );
    //   currentParent = widget.pages[currentParent]?['parent']; // 부모를 따라 계층 추적
    // }

    return chevrons;
  }

  void _deletePage(String pageName) {
    void deleteWithChildren(String page) {
      final children = widget.pages.entries
          .where((entry) => entry.value['parent'] == page)
          .map((entry) => entry.key)
          .toList();
      for (final child in children) {
        deleteWithChildren(child);
      }
      widget.pages.remove(page);
    }

    setState(() {
      deleteWithChildren(pageName);
    });
  }

  Widget buildSidebarPages() {
    List<Widget> buildPageItems(String? parent) {
      List<Widget> pageItems = [];

      widget.pages.forEach((pageName, pageData) {
        if (pageData['parent'] == parent) {
          pageItems.add(
            ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._buildChevronIcons(pageData['parent']),
                  Icon(Icons.description_outlined, color: Color(0xFF91918E)),
                ],
              ),
              title: isSidebarOpen ? Text(pageName) : null,
              onTap: () => widget.navigateToPage(pageName),
            ),
          );
          pageItems.addAll(buildPageItems(pageName));
        }
      });

      return pageItems;
    }

    // 최상위 레벨 페이지(부모가 없는 페이지)부터 시작
    List<Widget> topLevelPages = [];
    widget.pages.forEach((pageName, pageData) {
      if (pageData['parent'] == null) {
        topLevelPages.add(
          ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, color: Color(0xFF91918E)),
              ],
            ),
            title: isSidebarOpen ? Text(pageName) : null,
            onTap: () => widget.navigateToPage(pageName),
          ),
        );
        topLevelPages.addAll(buildPageItems(pageName)); // 자식 페이지 추가
      }
    });

    return ListView(children: topLevelPages);
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
              icon: Icon(
                isSidebarOpen ? Icons.chevron_left : Icons.chevron_right,
              ),
              onPressed: _toggleSidebar,
            ),
          ),
          // 고정 메뉴 (홈, 검색, 설정)
          _buildSidebarItem(
            icon: Icons.home_outlined,
            label: '홈',
            showLabel: isTextVisible,
            onTap: () {
              // 홈 버튼 클릭 시 HomeScreen으로 이동
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      HomeScreen(),
                ),
              );
            },
          ),
          _buildSidebarItem(
            icon: Icons.search,
            label: '검색',
            showLabel: isTextVisible,
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        SearchPage(
                          pages: widget.pages,
                          navigateToPage: widget.navigateToPage,
                          addNewPage: widget.addNewPage,
                        )),
              );
            },
          ),
          _buildSidebarItem(
            icon: Icons.calendar_today,
            label: '달력',
            showLabel: isTextVisible,
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        CalendarPage(
                          pages: widget.pages,
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
            showLabel: isTextVisible,
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ToDoPage(
                          pages: widget.pages,
                          navigateToPage: widget.navigateToPage,
                          addNewPage: widget.addNewPage,
                        )),
              );
            },
          ),
          _buildSidebarItem(
            icon: Icons.language,
            label: '대외 웹사이트',
            showLabel: isTextVisible,
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        WebLinkPage(
                          pages: widget.pages,
                          navigateToPage: widget.navigateToPage,
                          addNewPage: widget.addNewPage,
                        )
                ),
              );
            },
          ),
          _buildSidebarItem(
            icon: Icons.add,
            label: '새 페이지',
            showLabel: isTextVisible,
            onTap: widget.addNewPage,
            // 새 페이지 추가 로직 호출
          ),
          Divider(),
          Expanded(
            child: buildSidebarPages(), // 최상위부터 계층적으로 페이지 표시
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool showLabel,
    VoidCallback? onTap,
  }) {
    return ListTile(
      visualDensity: VisualDensity(vertical: -3), // 밀도를 조정해 높이를 줄임
      leading: Icon(icon, color: Color(0xFF91918E)),
      title: showLabel ? Text(label) : null, // 텍스트 표시 여부 결정

      onTap: onTap,
    );
  }
}
