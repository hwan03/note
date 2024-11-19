import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Custom Clipper Buttons")),
        body: Center(child: CustomClipperButtons()),
      ),
    );
  }
}

class CustomClipperButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
      children: [
        GestureDetector(
          onTap: () {
            print("Arrow Button Pressed");
          },
          child: ClipPath(
            clipper: ArrowClipper(),
            child: Container(
              width: 150,
              height: 60,
              color: Colors.blue,
              child: Center(
                  child: Text("Arrow Button",
                      style: TextStyle(color: Colors.white))),
            ),
          ),
        ),
        SizedBox(width: 20), // 두 버튼 사이에 간격 추가
        GestureDetector(
          onTap: () {
            print("Reverse Button Pressed");
          },
          child: ClipPath(
            clipper: ReverseClipper(),
            child: Container(
              width: 150,
              height: 60,
              color: Colors.red,
              child: Center(
                  child: Text("Reverse Button",
                      style: TextStyle(color: Colors.white))),
            ),
          ),
        ),
      ],
    );
  }
}

class ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width - 20, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 20, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class ReverseClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // 전체 사각형 영역
    Path path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 화살표 모양을 그리기 위한 경로 (ArrowClipper에서 사용한 경로)
    Path arrowPath = Path();
    arrowPath.lineTo(0, 0);
    arrowPath.lineTo(size.width - 20, 0);
    arrowPath.lineTo(size.width, size.height / 2);
    arrowPath.lineTo(size.width - 20, size.height);
    arrowPath.lineTo(0, size.height);
    arrowPath.close();

    // 화살표 영역을 제외한 나머지 경로를 반환
    path = Path.combine(PathOperation.difference, path, arrowPath);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
