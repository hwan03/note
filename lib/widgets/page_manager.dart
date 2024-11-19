class PageManager {
  static final PageManager _instance = PageManager._internal();
  factory PageManager() => _instance;

  List<String> pageNames = [];
  Map<String, String> pageContents = {};
  int pageCounter = 1;

  PageManager._internal();

  void addPage(String title) {
    pageNames.insert(0, title);
    pageContents[title] = "기본 내용입니다.";
  }

  void updatePage(String oldTitle, String newTitle, String content) {
    int index = pageNames.indexOf(oldTitle);
    if (index != -1) {
      pageNames[index] = newTitle;
      pageContents.remove(oldTitle);
      pageContents[newTitle] = content;
    }
  }

  void deletePage(String title) {
    pageNames.remove(title);
    pageContents.remove(title);
  }
}