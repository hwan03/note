import 'package:flutter/material.dart';
import 'to_do.dart';  // ToDoPage import

class Sidebar extends StatelessWidget {
  final bool isSidebarOpen;
  final Function onSidebarToggle;

  Sidebar({required this.isSidebarOpen, required this.onSidebarToggle});

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
                onSidebarToggle();
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
