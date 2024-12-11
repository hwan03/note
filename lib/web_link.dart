import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/sidebar.dart'; // Sidebar import

class WebLinkPage extends StatelessWidget {
  final Map<String, Map<String, dynamic>> pages; // 페이지 데이터
  final Function(String) navigateToPage; // 페이지 이동 함수
  final VoidCallback addNewPage; // 새 페이지 추가 함수

  WebLinkPage({
    required this.pages,
    required this.navigateToPage,
    required this.addNewPage,
    super.key,
  });

  // 외부 링크 데이터
  final List<Map<String, String>> webLinks = [
    {'title': 'LH홈페이지', 'url': 'https://www.lh.or.kr/main/', 'img': 'assets/images/lh.png'},
    {'title': 'Youtube', 'url': 'https://www.youtube.com/channel/UCzCH27zxNFmbzultWL4u-bw', 'img': 'assets/images/youtube.png'},
    {'title': 'Instagram', 'url': 'https://www.instagram.com/with_lh_official', 'img': 'assets/images/instagram.png'},
    {'title': 'LH블로그', 'url': 'https://blog.naver.com/bloglh', 'img': 'assets/images/naver.png'},
    {'title': 'Facebook', 'url': 'https://www.facebook.com/withLHofficial', 'img': 'assets/images/Facebook.png'},
    {'title': '카카오스토리', 'url': 'https://story.kakao.com/ch/storylh/', 'img': 'assets/images/Kakao.png'},
  ];

  // URL 열기 함수
  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            pages: pages,
            navigateToPage: navigateToPage,
            addNewPage: addNewPage,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '대외 웹사이트',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16), // 그리드 외부 여백 추가
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // 3열 배치
                          crossAxisSpacing: 16, // 열 간 간격
                          mainAxisSpacing: 16, // 행 간 간격
                          childAspectRatio: 1, // 정사각형 비율 유지
                        ),
                        itemCount: webLinks.length,
                        itemBuilder: (context, index) {
                          final link = webLinks[index];
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.white,
                              shadowColor: Colors.black12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: Color(0xFFF2F1EE)),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () => _launchURL(Uri.parse(link['url']!)),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    link['img']!, // 로컬 이미지 경로
                                    width: 200,
                                    height: 200,
                                  ),
                                  SizedBox(height: 8), // 이미지와 텍스트 간 간격
                                  Text(
                                    link['title']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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
}
