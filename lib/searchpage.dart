import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  //initiallize
  final TextEditingController _controller = TextEditingController();
  String apiKeyInfoNaru =
      'bd3254f61ba3ad0901c3df6e543a19b07cd4e2656d4b7c8f2e0f59ce59895fcc';
  List<dynamic> _books = [];
  String _hasBook = '';
  String _loanAvailable = '';
  String _selectedRegion = '11'; // 기본값: 서울특별시
  final Map<String, String> _regionCodes = {
    '서울특별시': '11',
    '부산광역시': '21',
    '대구광역시': '22',
    '인천광역시': '23',
    '광주광역시': '24',
    '대전광역시': '25',
    '울산광역시': '26',
    '세종특별자치시': '29',
    '경기도': '31',
    '강원도': '32',
    '충청북도': '33',
    '충청남도': '34',
    '전라북도': '35',
    '전라남도': '36',
    '경상북도': '37',
    '경상남도': '38',
    '제주특별자치도': '39',
  };

  // 도서 검색 함수
  Future<void> _bookSearch(String query) async {
    String apiUrl =
        'http://data4library.kr/api/srchBooks?authKey=$apiKeyInfoNaru&keyword=$query&pageNo=1&pageSize=10&format=json';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final docs = data['response']['docs'];

        if (mounted) {
          setState(() {
            _books = [];
            for (var item in docs) {
              _books.add(item['doc']);
            }
          });
        }
      } else {
        print('error: ${response.statusCode}');
      }
    } catch (e) {
      print('도서검색 API 호출 오류: $e');
    }
  }

  //도서 소장 도서관 목록 반환 함수
  Future<void> _fetchLibraryInfo(String isbn) async {
    String apiUrl =
        'http://data4library.kr/api/libSrchByBook?authKey=$apiKeyInfoNaru&isbn=$isbn&region=$_selectedRegion&format=json';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final libraries = data['response']['libs'];

        if (!mounted) return;

        // 소장 도서관 목록을 다이얼로그로 표시
        if (libraries == null || libraries.isEmpty) {
          // 소장 도서관 목록이 없을 때 처리
          _showErrorDialog('소장 도서관 없음', '선택한 도서를 소장한 도서관이 없습니다.');
        } else {
          // 소장 도서관 목록을 다이얼로그로 표시
          _loanStatus(libraries[0]['lib']['libCode'], isbn);
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('소장 도서관 목록'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: libraries.length,
                    itemBuilder: (context, index) {
                      final library = libraries[index]['lib'];
                      return ListTile(
                        title: Text(library['libName'] ?? 'Unknown Library'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('주소: ${library['address'] ?? 'No Address'}'),
                            Text('전화번호: ${library['tel'] ?? 'No Phone'}'),
                            Text('대출 소장여부: $_hasBook'),
                            Text('대출 가능여부: $_loanAvailable'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('닫기'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('소장 도서관 조회 오류: $e');
    }
  }

  //도서 대출 현황 반환 함수
  Future<void> _loanStatus(String libcd, String isbn) async {
    String apiUrl =
        'http://data4library.kr/api/bookExist?authKey=$apiKeyInfoNaru&libCode=$libcd&isbn13=$isbn&format=json';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['response']['result'];

        if (mounted) {
          setState(() {
            String hasBook = result['hasBook'];
            if (hasBook == 'Y') {
              _hasBook = '소장 중';
            } else {
              _hasBook = '소장 중이지 않음';
            }
            String loanAvailable = result['loanAvailable'];
            if (loanAvailable == 'Y') {
              _loanAvailable = '대출 가능';
            } else {
              _loanAvailable = '대출 불가';
            }
          });
        }
      } else {
        print('error: ${response.statusCode}');
      }
    } catch (e) {
      print('도서검색 API 호출 오류: $e');
    }
  }

  // 에러메시지 출력 함수
  void _showErrorDialog(String head, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(head),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('book search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: '도서명 입력',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _bookSearch(_controller.text);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('지역 선택:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedRegion,
                    items: _regionCodes.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.value,
                        child: Text(entry.key),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRegion = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index];
                  return ListTile(
                    title: Text(book['bookname'] ?? 'Unknown Title'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('저자: ${book['authors'] ?? 'Unknown Author'}'),
                        Text(
                            '출판사: ${book['publisher'] ?? 'Unknown Publisher'}'),
                        Text('ISBN: ${book['isbn13'] ?? 'No ISBN'}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // 도서 클릭 시 소장 도서관 조회
                      _fetchLibraryInfo(book['isbn13']);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
