import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import 'AppId.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    _initAgoraRtcEngine();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Agora Flutter SDK'),
        ),
        body: Center(
          child: Text('TODO'),
        ),
      ),
    );
  }

  Future<void> _initAgoraRtcEngine() async {
    AgoraRtcEngine.create(agoraAppId);
  }
}
