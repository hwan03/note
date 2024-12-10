import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/sidebar.dart'; // Sidebar import

class WebLinkPage extends StatelessWidget {
  final List<String> recentPages;
  final Function(String) navigateToPage;
  final VoidCallback addNewPage;

  WebLinkPage({
    required this.recentPages,
    required this.navigateToPage,
    required this.addNewPage,
    Key? key,
  }) : super(key: key);

  // 외부 링크 데이터
  final List<Map<String, String>> webLinks = [
    {'title': 'LH홈페이지', 'url': 'https://www.lh.or.kr/main/', 'img':'assets/images/lh.png'},
    {'title': 'Youtube', 'url': 'https://www.youtube.com/channel/UCzCH27zxNFmbzultWL4u-bw','img':'assets/images/youtube.png'},
    {'title': 'Instagram', 'url': 'https://www.instagram.com/with_lh_official','img':'assets/images/instagram.png'},
    {'title': 'LH블로그', 'url': 'https://blog.naver.com/bloglh','img':'assets/images/naver.png'},
    {'title': 'Facebook', 'url': 'https://www.facebook.com/withLHofficial','img':'assets/images/Facebook.png'},
    {'title': '카카오스토리', 'url': 'https://story.kakao.com/ch/storylh/','img':'assets/images/Kakao.png'},
  ];

  // URL 열기 함수
  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
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
            recentPages: recentPages,
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
                          return GestureDetector(
                            onTap: () => _launchURL(Uri.parse(link['url']!)),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFF2F1EE)),
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    link['img']!, // 로컬 이미지 경로
                                    width: 300,
                                    height: 300,
                                  ),
                                  SizedBox(height: 8), // 이미지와 텍스트 간 간격
                                  Text(
                                    link['title']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
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
