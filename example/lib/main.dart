import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:flutter/material.dart';

import 'AppId.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AgoraRtcEngine.init();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInChannel = false;
  final _infoStrings = <String>[];

  @override
  void initState() {
    super.initState();

    _initAgoraRtcEngine();
    _addAgoraEventHandlers();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Agora Flutter SDK'),
          actions: <Widget>[
            FlatButton(
              child: Text('requestAVPermissions'),
              onPressed: () {
                AgoraRtcEngine.requestAVPermissions();
              },
            )
          ],
        ),
        body: Container(
          child: Column(
            children: [
              OutlineButton(
                child: Text(_isInChannel ? 'Leave Channel' : 'Join Channel',
                    style: textStyle),
                onPressed: _toggleTexture,
              ),
              Expanded(
                child: Stack(
                  children: [
                    _renderVideo(),
                    Container(child: _buildInfoList()),
                  ],
                ),
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

  void _addAgoraEventHandlers() {
    AgoraRtcEngine.onJoinChannelSuccess =
        (String channel, int uid, int elapsed) {
      setState(() {
        String info = 'onJoinChannel: ' + channel + ', uid: ' + uid.toString();
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onLeaveChannel = () {
      setState(() {
        _infoStrings.add('onLeaveChannel');
      });
    };

    AgoraRtcEngine.onUserJoined = (int uid, int elapsed) {
      setState(() {
        String info = 'userJoined: ' + uid.toString();
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onUserOffline = (int uid, int reason) {
      setState(() {
        String info = 'userOffline: ' + uid.toString();
        _infoStrings.add(info);
      });
    };
  }

  void _toggleChannel() async {
    if (_isInChannel) {
      await AgoraRtcEngine.leaveChannel();
      setState(() => _isInChannel = false);
    } else {
      await AgoraRtcEngine.joinChannel(null, 'flutter', null, 0);
      setState(() => _isInChannel = true);
    }
  }

  void _toggleTexture() async {
    if (_textureId == null) {
      await AgoraRtcEngine.enableVideo();
      var textureId = await AgoraRtcEngine.setupLocalTexture();
      setState(() => _textureId = textureId);
      AgoraRtcEngine.startPreview();
    } else {
      await AgoraRtcEngine.disposeLocalTexture(_textureId);
      setState(() => _textureId = null);
      AgoraRtcEngine.stopPreview();
      await AgoraRtcEngine.disableVideo();
    }
  }

  int _textureId;

  Widget _renderVideo() {
    return _textureId != null
        ? RtcLocalView.SurfaceView(_textureId)
        : Container();
  }

  static TextStyle textStyle = TextStyle(fontSize: 18, color: Colors.blue);

  Widget _buildInfoList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemExtent: 24,
      itemBuilder: (context, i) {
        return ListTile(
          title: Text(_infoStrings[i]),
        );
      },
      itemCount: _infoStrings.length,
    );
  }
}
