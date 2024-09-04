import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  NaverMapController? _controller;
  Position? _currentPosition;
  final Map<String, String> _markerInfoMap = {}; // 마커 ID와 정보를 매핑하기 위한 맵
  bool _isSdkInitialized = false; // SDK 초기화 상태 체크
  String? _selectedLibraryName; // 선택된 도서관 이름 저장
  String address = ''; // 주소 정보
  NCameraPosition _initialCameraPosition = const NCameraPosition(
    target: NLatLng(37.5666102, 126.9783881), // 임시 기본 위치: 서울
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _initializeSdk();
    _getCurrentLocation();
  }

  Future<void> _initializeSdk() async {
    // SDK 초기화 상태를 확인하여 상태 업데이트
    await NaverMapSdk.instance.initialize(
      clientId: 'eoa0ax20f', // 네이버 클라우드 플랫폼 클라이언트 ID
    );
    setState(() {
      _isSdkInitialized = true;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
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
        // 현재 위치로 카메라 위치 설정
        _initialCameraPosition = NCameraPosition(
          target: NLatLng(position.latitude, position.longitude),
          zoom: 14,
        );
      });

      // 위치 정보를 사용하여 역지오코딩 및 도서관 정보 검색
      await _reverseGeolocation(position.latitude, position.longitude);
      await _fetchLibraries(address);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _reverseGeolocation(double lat, double lng) async {
    // 역지오코딩: 좌표 -> 주소 변환
    String apiUrl =
        'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?coords=$lng,$lat&output=json';
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'X-Naver-Client-Id': 'eoa0ax20f1', // 네이버 클라우드 플랫폼 클라이언트 ID
        'X-Naver-Client-Secret':
            '08luvgdU8r3B6IBPU1ya4eT6irWzUEBsdsOtsMnH', // 네이버 클라우드 플랫폼 클라이언트 시크릿
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'][0]['region'];
      final String area1Name = results['area1']['name'];
      final String area2Name = results['area2']['name'];
      final String area3Name = results['area3']['name'];

      setState(() {
        address = '$area1Name $area2Name $area3Name';
      });
    } else {
      print('Failed to get address: ${response.statusCode}');
    }
  }

  Future<void> _fetchLibraries(String addr) async {
    // 네이버 지역 검색 API를 사용하여 도서관 정보 검색
    String apiUrl =
        'https://openapi.naver.com/v1/search/local.json?query=$addr 도서관&display=5&start=1&sort=random';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'X-Naver-Client-Id': 'ogu28wAdF1eENpAOXCAG', // 네이버 오픈 API 클라이언트 ID
        'X-Naver-Client-Secret': 'h5WV1SlOzj', // 네이버 오픈 API 클라이언트 시크릿
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // 도서관 위치 데이터를 파싱하여 마커 리스트로 변환
      for (var item in data['items']) {
        final double latitude = double.parse(item['mapy']); // 위도
        final double longitude = double.parse(item['mapx']); // 경도
        final String name = item['title']; // 도서관 이름
        final String markerId = item['link']; // 고유한 마커 ID

        // 마커 생성 및 추가
        final marker = NMarker(
          id: markerId,
          position: NLatLng(latitude, longitude),
        );

        // 마커와 도서관 이름을 매핑
        _markerInfoMap[markerId] = name;

        // 마커를 맵에 추가
        _controller?.addOverlay(marker);
      }
    } else {
      print('Failed to load library data: ${response.statusCode}');
    }
  }

  void _onMapReady(NaverMapController controller) {
    _controller = controller;

    // 현재 위치 마커 추가
    if (_currentPosition != null) {
      _moveToCurrentLocation();
      _addCurrentLocationMarker(
          _currentPosition!.latitude, _currentPosition!.longitude);
    }
  }

  void _addCurrentLocationMarker(double lat, double lng) {
    if (_controller == null) return;

    final marker = NMarker(
      id: 'current_location',
      position: NLatLng(lat, lng),
    );
    _controller!.addOverlay(marker);

    // 현재 위치 마커와 정보 매핑
    _markerInfoMap['current_location'] = '현재 위치';
  }

  void _moveToCurrentLocation() {
    if (_controller == null || _currentPosition == null) return;

    _controller!.updateCamera(
      NCameraUpdate.withParams(
        target:
            NLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 14,
      ),
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
              onMapReady: _onMapReady,
              options: NaverMapViewOptions(
                initialCameraPosition: _initialCameraPosition,
              ),
            )
          else
            const Center(child: CircularProgressIndicator()), // 초기화 중일 때 로딩 표시
          if (_selectedLibraryName != null) // 선택된 도서관 정보가 있을 때 표시
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _selectedLibraryName!,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
