import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

enum ToggleStatus { on, off }

class _MyAppState extends State<MyApp> {
  ToggleStatus centerButtonStatus = ToggleStatus.off;
  final Battery _battery = Battery();
  int _batteryLevel = 0;
  int? _customBatteryLevel; // 사용자 정의 배터리 레벨을 저장할 변수
  final TextEditingController _controller = TextEditingController();
  final String raspberryPiUrl = 'http://192.168.137.119:5000'; // 라즈베리 파이 IP 주소와 포트

  @override
  void initState() {
    super.initState();
    _initializeBattery();
  }

  Future<void> _initializeBattery() async {
    await _getBatteryLevel();
    _battery.onBatteryStateChanged.listen((BatteryState state) async {
      await _getBatteryLevel();
      _checkCustomBatteryLevel(); // 사용자 정의 배터리 레벨과 현재 배터리 레벨을 비교
    });
  }

  Future<void> _getBatteryLevel() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      setState(() {
        _batteryLevel = batteryLevel;
      });
    } catch (e) {
      print('Failed to get battery level: $e');
    }
  }

  void _checkCustomBatteryLevel() {
    if (_customBatteryLevel != null && _batteryLevel == _customBatteryLevel) {
      _sendHttpRequest('MOVE_ROBOT', batteryLevel: _customBatteryLevel);
    }
  }

  void _showPopup(BuildContext context, String message,
      {VoidCallback? onConfirm, bool withCancelButton = true}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            if (withCancelButton)
              TextButton(
                child: const Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) {
                  FocusScope.of(context).unfocus();
                  onConfirm();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleToggle(BuildContext context) {
    if (centerButtonStatus == ToggleStatus.on) {
      _showPopup(context, '로봇을 중단하시겠습니까?', onConfirm: () {
        setState(() {
          centerButtonStatus = ToggleStatus.off;
        });
        _sendHttpRequest('STOP');
      });
    } else {
      setState(() {
        centerButtonStatus = ToggleStatus.on;
      });
      _sendHttpRequest('START');
    }
  }

  void _handleSetCustomBatteryLevel(BuildContext context) {
    if (centerButtonStatus == ToggleStatus.off) {
      _showPopup(
        context,
        '로봇 작동 설정을 ON으로 변경하시겠습니까?',
        onConfirm: () {
          setState(() {
            centerButtonStatus = ToggleStatus.on;
          });
          _sendHttpRequest('START');
        },
        withCancelButton: false,
      );
      return;
    }

    String value = _controller.text.trim();
    int level = int.tryParse(value) ?? -1;
    if (level < 5 || level > 100) {
      _showPopup(
        context,
        '5 이상 100 이하의 값만 설정할 수 있습니다',
        onConfirm: () {
          setState(() {
            _controller.clear(); // 입력한 값 초기화
          });
        },
      );
      return;
    }

    setState(() {
      _customBatteryLevel = level; // 사용자 정의 배터리 레벨 저장
    });

    _showPopup(
      context,
      '배터리 값이 $level% 일 때 로봇을 작동하시겠습니까?',
      onConfirm: () {
        // 조건에 맞는 배터리 레벨에 도달했을 때 신호를 보내도록 설정
        _checkCustomBatteryLevel();
      },
    );
  }

  Future<void> _sendHttpRequest(String command, {int? batteryLevel}) async {
    try {
      final response = await http.post(
        Uri.parse('$raspberryPiUrl/command'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'command': command,
          if (batteryLevel != null) 'batteryLevel': batteryLevel,
        }),
      );

      // 디버깅을 위한 로그 추가
      print('Response body: ${response.body}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        print('Command sent successfully: $command');
      } else {
        print('Failed to send command. Status code: ${response.statusCode}');
        print('Response body: ${response.body}'); // 응답 바디를 로그에 추가
      }
    } catch (e) {
      print('Error sending HTTP request: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
            child: Text('차 징', style: TextStyle(color: Colors.white))),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: Image.asset(
                'assets/LOGO_charging.jpg',
                width: MediaQuery.of(context).size.width / 2.5,
              ),
            ),
            ElevatedButton(
              onPressed: () => _handleToggle(context),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    return centerButtonStatus == ToggleStatus.on
                        ? Colors.green
                        : Colors.grey;
                  },
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.toggle_on, size: 30),
                  Text(
                    centerButtonStatus == ToggleStatus.on ? 'ON' : 'OFF',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Text('현재 배터리 잔량:', style: TextStyle(fontSize: 18)),
                Text('$_batteryLevel%', style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Text('사용자 정의:', style: TextStyle(fontSize: 18)),
                Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0',
                          contentPadding: EdgeInsets.all(8.0),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('%', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 5),
                    ElevatedButton(
                      onPressed: () => _handleSetCustomBatteryLevel(context),
                      child: const Text(
                        '설정',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
