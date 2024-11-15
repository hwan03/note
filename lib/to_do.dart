import 'package:flutter/material.dart';
import 'widgets/sidebar.dart'; // Sidebar import

class ToDoPage extends StatefulWidget {
  @override
  _ToDoPageState createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(), // Sidebar widget 사용),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('성과 관리 편람',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600])),
                  SizedBox(height: 10),
                  Text(
                    '할 일 목록',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            title: Text('할 일 ${index + 1}'),
                            subtitle: Text('마감일: 2024-01-15'),
                            trailing: Checkbox(
                              value: false,
                              onChanged: (value) {},
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // 할 일 추가 페이지로 이동하는 로직
                    },
                    child: Text('새 할 일 추가'),
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