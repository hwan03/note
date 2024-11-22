import 'package:flutter/material.dart';
import 'todo_data.dart';

class SummaryChart extends StatelessWidget {
  final ToDoData toDoData;

  const SummaryChart({Key? key, required this.toDoData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: toDoData.sections.map((section) {
        final progress = toDoData.calculateProgress(section['items']);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  section['title'],
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: progress > 0.7
                              ? Colors.green
                              : progress > 0.3
                              ? Colors.orange
                              : Colors.red,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

}