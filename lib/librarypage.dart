import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late NaverMapController _controller;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // 위치 권한 확인 및 요청
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // 권한이 거부된 경우
          return;
        }
      }

      // 위치 설정을 사용하여 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // 높은 정확도
        ),
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _onMapReady(NaverMapController controller) {
    _controller = controller;
    if (_currentPosition != null) {
      // NCameraUpdate와 NLatLng를 사용하여 카메라 이동
      _controller.updateCamera(
        NCameraUpdate.withParams(
          target:
              NLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 14, // 원하는 줌 레벨 설정
        ),
      );
      _addMarker(_currentPosition!.latitude, _currentPosition!.longitude);
    }
  }

  void _addMarker(double lat, double lng) {
    // 마커 추가
    final marker = NMarker(
      id: 'current_location',
      position: NLatLng(lat, lng),
    );
    _controller.addOverlay(marker);
  }

  //기본위치 = 서울
  final cameraPosition = const NCameraPosition(
    target: NLatLng(37.5666102, 126.9783881),
    zoom: 15,
    bearing: 45,
    tilt: 30,
  );

  void _moveToCurrentLocation() {
    if (_currentPosition != null) {
      _controller.updateCamera(
        NCameraUpdate.withParams(
          target:
              NLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 14, // 원하는 줌 레벨 설정
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Locations'),
      ),
      body: Stack(
        children: [
          NaverMap(
            onMapReady: _onMapReady,
            options: NaverMapViewOptions(
              initialCameraPosition: cameraPosition,
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
