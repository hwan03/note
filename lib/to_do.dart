import 'package:flutter/material.dart';

class ToDoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('성과 관리 편람'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
    );
  }
}
