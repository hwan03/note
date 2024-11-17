import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(),
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
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return Container(
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
                                    size: 40, color: Color(0xFF91918E)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(15),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '페이지${index + 1}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text('2024.01.15'),
                                    ]),
                              )
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

  Widget _buildLabeledBox({required String label, required Widget child,}) {
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
