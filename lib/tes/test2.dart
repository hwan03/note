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
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipPath(
          clipper: ArrowClipper(),
          child: Container(
            width: 150,
            height: 60,
            color: Colors.blue,
            child: Center(child: Text("Arrow Button", style: TextStyle(color: Colors.white))),
          ),
        ),
        ClipPath(
          clipper: ReverseClipper(),
          child: Container(
            width: 150,
            height: 60,
            color: Colors.red,
            child: Center(child: Text("Reverse Button", style: TextStyle(color: Colors.white))),
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
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
