import 'package:flutter/material.dart';
import 'widgets/sidebar.dart'; // Sidebar 위젯을 가져옴

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<String> _allItems = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Another Item',
    'Searchable Item',
    'Flutter Item',
    'Dart Item',
  ];
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;
  }

  void _filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredItems = _allItems;
      });
    } else {
      setState(() {
        _filteredItems = _allItems
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 사이드바 유지
          Sidebar(),
          // 메인 검색 페이지
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: '검색어를 입력하세요',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      _filterSearchResults(value);
                    },
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? Center(
                      child: Text(
                        '검색 결과가 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_filteredItems[index]),
                          leading: Icon(Icons.search),
                          onTap: () {
                            // 검색 항목 클릭 시 동작 추가 가능
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${_filteredItems[index]} 선택됨'),
                              ),
                            );
                          },
                        );
                      },
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}