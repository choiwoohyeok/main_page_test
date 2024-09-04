import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String authKeyInfoNaru =
      'bd3254f61ba3ad0901c3df6e543a19b07cd4e2656d4b7c8f2e0f59ce59895fcc';
  Map bookisbn = {String: String};

  Future<void> _bookSearch(String ttl) async {
    String apiUrl =
        'http://data4library.kr/api/srchBooks?authKey=$authKeyInfoNaru&title=$ttl&pageNo=1&pageSize=10';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        for (var results in data['docs']['doc']) {
          List bookname = results['bookname'];
          List authors = results['authors'];
          List isbn13 = results['isbn13'];
          bookisbn[bookname] = isbn13;
        }
      } else {
        print('도서검색 API 호출 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('도서검색 API 호출 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Search Page',
        style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
      ),
    );
  }
}
