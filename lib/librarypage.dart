import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

class LibraryInfo {
  final String name;
  final String address;
  final String url;
  final String tel;

  LibraryInfo(this.name, this.address, this.url, this.tel);
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String apiKeyInfoNaru =
      'bd3254f61ba3ad0901c3df6e543a19b07cd4e2656d4b7c8f2e0f59ce59895fcc';
  NCameraPosition _initialCameraPosition = const NCameraPosition(
    target: NLatLng(37.5666102, 126.9783881), // 임시 기본 위치: 서울
    zoom: 15,
  );
  NaverMapController? _controller;
  Position? _currentPosition;
  bool _isSdkInitialized = false; // SDK 초기화 상태 체크
  bool _isMapReady = false; // 맵 초기화 상태 체크
  String address = ''; // 주소 정보
  String regionCode = ''; //지역코드
  Map<NLatLng, List<LibraryInfo>> libraryInfoMap = {};
  Set<String> addedMarkers = {}; // 추가된 마커를 추적하기 위한 Set
  final Map<String, String> _regionCodes = {
    '서울특별시 종로구': '11010',
    '서울특별시 중구': '11020',
    '서울특별시 용산구': '11030',
    '서울특별시 성동구': '11040',
    '서울특별시 광진구': '11050',
    '서울특별시 동대문구': '11060',
    '서울특별시 중랑구': '11070',
    '서울특별시 성북구': '11080',
    '서울특별시 강북구': '11090',
    '서울특별시 도봉구': '11100',
    '서울특별시 노원구': '11110',
    '서울특별시 은평구': '11120',
    '서울특별시 서대문구': '11130',
    '서울특별시 마포구': '11140',
    '서울특별시 양천구': '11150',
    '서울특별시 강서구': '11160',
    '서울특별시 구로구': '11170',
    '서울특별시 금천구': '11180',
    '서울특별시 영등포구': '11190',
    '서울특별시 동작구': '11200',
    '서울특별시 관악구': '11210',
    '서울특별시 서초구': '11220',
    '서울특별시 강남구': '11230',
    '서울특별시 송파구': '11240',
    '서울특별시 강동구': '11250',
  };

  @override
  void initState() {
    super.initState();
    _initializeSdk().then((_) {
      _getCurrentLocation();
    });
  }

  Future<void> _initializeSdk() async {
    try {
      await NaverMapSdk.instance.initialize(
        clientId: 'eoa0ax20f1', // 네이버 클라우드 플랫폼 클라이언트 ID
      );
      setState(() {
        _isSdkInitialized = true;
      });
    } catch (e) {
      print('SDK 초기화 오류: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('위치 권한이 거부되었습니다.');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _initialCameraPosition = NCameraPosition(
          target: NLatLng(position.latitude, position.longitude),
          zoom: 14,
        );
      });

      print('현재 위치: ${position.latitude}, ${position.longitude}');

      // 위치 정보를 사용하여 마커 추가 시도
      if (_isMapReady && _currentPosition != null) {
        addCurrentLocationMarker(position.latitude, position.longitude);
      }

      await _reverseGeolocation(position.latitude, position.longitude);
      await _fetchLibraries(address);

      if (_controller != null) {
        moveToCurrentLocation();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _reverseGeolocation(double lat, double lng) async {
    String apiUrl =
        'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?coords=$lng,$lat&output=json';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'X-NCP-APIGW-API-KEY-ID': 'eoa0ax20f1',
          'X-NCP-APIGW-API-KEY': '08luvgdU8r3B6IBPU1ya4eT6irWzUEBsdsOtsMnH',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'][0]['region'];
        final String area1Name = results['area1']['name'];
        final String area2Name = results['area2']['name'];

        setState(() {
          address = '$area1Name $area2Name';
        });

        if (_regionCodes.containsKey(address)) {
          regionCode = _regionCodes[address]!;
          print('도서관 지역 코드: $regionCode');
        } else {
          print('해당 주소에 대한 지역 코드가 없습니다.');
        }

        print('확인된 주소: $address');
      } else {
        print('주소 가져오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('역지오코딩 오류: $e');
    }
  }

  Future<void> _fetchLibraries(String addr) async {
    String apiUrl =
        'http://data4library.kr/api/libSrch?authKey=$apiKeyInfoNaru&region=11&dtl_region=$regionCode&pageSize=30&format=json';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final libraries = data['response']['libs'];

        if (!mounted) return;

        for (int i = 0; i < libraries.length; i++) {
          // 각 도서관의 정보 추출
          final String name = libraries[i]['lib']['libName']; // 도서관 이름
          final double latitude =
              double.parse(libraries[i]['lib']['latitude']); // 위도
          final double longitude =
              double.parse(libraries[i]['lib']['longitude']); // 경도
          final String libURL = libraries[i]['lib']['homepage']; // 홈페이지 URL
          final String libraryAddress =
              libraries[i]['lib']['address']; // 도서관 주소
          final String libtel = libraries[i]['lib']['tel']; // 전화번호

          final position = NLatLng(latitude, longitude);
          final libraryInfo = LibraryInfo(name, libraryAddress, libURL, libtel);

          // 중복된 도서관 정보 추가 방지
          if (!libraryInfoMap.containsKey(position)) {
            libraryInfoMap[position] = [libraryInfo];
          } else {
            // 기존에 존재하는 도서관 리스트에 중복 추가 방지
            if (!libraryInfoMap[position]!.any((info) => info.name == name)) {
              libraryInfoMap[position]!.add(libraryInfo);
            }
          }

          // 마커 추가 여부 확인
          if (!addedMarkers.contains('$latitude,$longitude')) {
            // 마커 생성
            final marker = NMarker(
              id: '$name-$i', // 고유한 ID 설정
              position: position,
            );

            _controller?.addOverlay(marker);

            marker.setOnTapListener((NMarker tappedMarker) {
              showLibraryInfo(position);
            });

            addedMarkers.add('$latitude,$longitude'); // 추가된 마커 위치 저장
            print('마커 추가됨: $name, $libURL at ($latitude, $longitude)');
          }
        }
      } else {
        print('도서관 데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('도서관 정보 불러오기 오류: $e');
    }
  }

  void onMapReady(NaverMapController controller) {
    setState(() {
      _controller = controller;
      _isMapReady = true; // 맵이 준비되었음을 설정
    });

    if (_currentPosition != null) {
      moveToCurrentLocation();
      addCurrentLocationMarker(
          _currentPosition!.latitude, _currentPosition!.longitude);
    } else {
      _getCurrentLocation();
    }
  }

  void addCurrentLocationMarker(double lat, double lng) {
    if (_controller != null) {
      final marker = NMarker(
        id: 'current_location',
        position: NLatLng(lat, lng),
        iconTintColor: Colors.red,
      );
      _controller?.addOverlay(marker);
      print('현재 마커 위치: $lat, $lng');
    } else {
      print('현재 마커 생성 안함');
    }
  }

  void moveToCurrentLocation() {
    if (_controller != null && _currentPosition != null) {
      _controller!.updateCamera(
        NCameraUpdate.withParams(
          target:
              NLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 14,
        ),
      );
      print('카메라가 현재 위치로 이동했습니다.');
    } else {
      print('컨트롤러 또는 현재 위치가 null입니다.');
    }
  }

  // URL을 여는 함수
  Future<void> launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      print('URL을 열 수 없습니다: $url');
    }
  }

  // 도서관 정보 표시하는 함수
  void showLibraryInfo(NLatLng position) {
    final libraries = libraryInfoMap[position] ?? [];

    if (libraries.isEmpty) {
      print('해당 위치에 도서관 정보가 없습니다.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('도서관 정보'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: libraries.map((library) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('이름: ${library.name}'),
                    Text('주소: ${library.address}'),
                    Text('전화번호: ${library.tel}'),
                    GestureDetector(
                      onTap: () => launchURL(library.url),
                      child: Text(
                        '웹사이트: ${library.url}',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              child: const Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
        title: const Text('Library Locations'),
      ),
      body: Stack(
        children: [
          if (_isSdkInitialized)
            NaverMap(
              onMapReady: onMapReady,
              options: NaverMapViewOptions(
                initialCameraPosition: _initialCameraPosition,
              ),
            )
          else
            const Center(child: CircularProgressIndicator()), // 초기화 중일 때 로딩 표시
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: moveToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
