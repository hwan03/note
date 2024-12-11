import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
    {'title': '청약플러스', 'url': 'https://apply.lh.or.kr/lhapply/main.do', 'img': 'assets/images/Plus.png'},
    {'title': '마이홈', 'url': 'https://www.myhome.go.kr/hws/portal/main/getMgtMainHubPage.do', 'img': 'assets/images/MyHome.png'},
    {'title': 'LH인스타그램', 'url': 'https://www.instagram.com/with_lh_official', 'img': 'assets/images/instagram.png'},
    {'title': 'LH유튜브', 'url': 'https://www.youtube.com/channel/UCzCH27zxNFmbzultWL4u-bw', 'img': 'assets/images/youtube.png'},
    {'title': 'LH블로그', 'url': 'https://blog.naver.com/bloglh', 'img': 'assets/images/naver.png'},
  ];

  // // URL 열기 함수
  // Future<void> _launchURL(Uri url) async {
  //   if (await canLaunchUrl(url)) {
  //     await launchUrl(url, mode: LaunchMode.platformDefault);
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  // }

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
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(50), // 그리드 외부 여백 추가
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WebPageView(
                                    title: link['title']!,
                                    url: link['url']!,
                                  ),
                                ),
                              );
                            },
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


class WebPageView extends StatelessWidget {
  final String title;
  final String url;

  const WebPageView({required this.title, required this.url, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted) // JavaScript 모드 설정
          ..loadRequest(Uri.parse(url)), // URL 요청
      ),
    );
  }
}

