import 'package:flutter/material.dart';

import 'homepage.dart';
import 'librarypage.dart';
import 'searchpage.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 네이버 맵 SDK 초기화
  await NaverMapSdk.instance.initialize(
    clientId: 'eoa0ax20f1', // 네이버 클라우드 플랫폼 클라이언트 ID
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomePage(), // home_page.dart에서 가져옴
    const SearchPage(), // search_page.dart에서 가져옴
    const LibraryPage(), // profile_page.dart에서 가져옴
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('체키라웃'),
        centerTitle: true,
        elevation: 0.0,
      ),
      /* drawer: Drawer(
          child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(username ?? '사용자 이름 없음'),
            accountEmail: Text(email ?? '이메일 없음'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                username != null ? username[0] : '?',
                style: const TextStyle(fontSize: 40.0, color: Colors.white),
              ),
            ),
          ), 
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('홈'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () {
              userProvider.clearUser();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const StartPage()));
            },
          ),
        ],
      )), */
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Library',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
