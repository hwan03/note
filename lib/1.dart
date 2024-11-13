import 'package:flutter/material.dart';

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
  bool isSidebarOpen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (isSidebarOpen)
          // Sidebar
            Container(
              width: 200,
              color: Color(0xFFF5F5F3),
              child: Column(
                children: [
                  SizedBox(height: 50),
                  _buildSidebarItem(
                    icon: Icons.home,
                    label: '홈',
                    isActive: true,
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
                    icon: Icons.check_circle,
                    label: '성과 관리',
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
                    icon: Icons.settings,
                    label: '프로젝트 설정',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        isSidebarOpen = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          // Main Content
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('최근 페이지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Expanded(
                    flex: 2,
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFF2F1EE)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // 상단 회색
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF2F1EE),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                padding: EdgeInsets.all(8),
                                child: Center(
                                  child: Icon(Icons.folder, size: 40, color: Colors.orange),
                                ),
                              ),
                              // 하단 흰색
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('페이지${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('2024.01.15'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                              child: Text('내용 없음'),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // 달력
                        Expanded(
                          child: _buildLabeledBox(
                            label: '일정',
                            child: ListView.builder(
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text('월요일 11월 6일'),
                                  subtitle: Text('○○ 미팅'),
                                  trailing: Text('9AM'),
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

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    Color iconColor = Colors.black,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: TextStyle(color: isActive ? Colors.black : textColor)),
      tileColor: isActive ? Colors.white : null,
      onTap: () {},
    );
  }

  Widget _buildLabeledBox({required String label, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFF2F1EE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            color: Color(0xFFF2F1EE),
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
