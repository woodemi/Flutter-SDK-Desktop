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
  bool _isInChannel = false;

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
        body: Container(
          child: Column(
            children: [
              OutlineButton(
                child: Text(_isInChannel ? 'Leave Channel' : 'Join Channel',
                    style: textStyle),
                onPressed: _toggleChannel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initAgoraRtcEngine() async {
    AgoraRtcEngine.create(agoraAppId);

    AgoraRtcEngine.setChannelProfile(ChannelProfile.Communication);
  }

  void _toggleChannel() {
    setState(() async {
      if (_isInChannel) {
        _isInChannel = false;
        await AgoraRtcEngine.leaveChannel();
      } else {
        _isInChannel = true;
        await AgoraRtcEngine.joinChannel(null, 'flutter', null, 0);
      }
    });
  }

  static TextStyle textStyle = TextStyle(fontSize: 18, color: Colors.blue);
}
