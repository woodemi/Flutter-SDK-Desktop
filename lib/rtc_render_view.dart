import 'package:flutter/widgets.dart';

class RtcSurfaceView extends StatefulWidget {
  final int textureId;

  RtcSurfaceView(this.textureId);

  @override
  State<StatefulWidget> createState() {
    return _RtcSurfaceViewState();
  }
}

class _RtcSurfaceViewState extends State<RtcSurfaceView> {
  @override
  Widget build(BuildContext context) {
    return Texture(
      textureId: widget.textureId,
    );
  }
}