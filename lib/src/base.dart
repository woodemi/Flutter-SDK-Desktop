class RtcStats {
  final int totalDuration;
  final int txBytes;
  final int rxBytes;
  final int txAudioBytes;
  final int txVideoBytes;
  final int rxAudioBytes;
  final int rxVideoBytes;
  final int txKBitrate;
  final int rxKBitrate;
  final int txAudioKBitrate;
  final int rxAudioKBitrate;
  final int txVideoKBitrate;
  final int rxVideoKBitrate;
  final int lastmileDelay;
  final int txPacketLossRate;
  final int rxPacketLossRate;
  final int users;
  final double cpuTotalUsage;
  final double cpuAppUsage;

  RtcStats(
    this.totalDuration,
    this.txBytes,
    this.rxBytes,
    this.txAudioBytes,
    this.txVideoBytes,
    this.rxAudioBytes,
    this.rxVideoBytes,
    this.txKBitrate,
    this.rxKBitrate,
    this.txAudioKBitrate,
    this.rxAudioKBitrate,
    this.txVideoKBitrate,
    this.rxVideoKBitrate,
    this.lastmileDelay,
    this.txPacketLossRate,
    this.rxPacketLossRate,
    this.users,
    this.cpuTotalUsage,
    this.cpuAppUsage,
  );

  RtcStats.fromJson(Map<dynamic, dynamic> json)
      : totalDuration = json['totalDuration'],
        txBytes = json['txBytes'],
        rxBytes = json['rxBytes'],
        txAudioBytes = json['txAudioBytes'],
        txVideoBytes = json['txVideoBytes'],
        rxAudioBytes = json['rxAudioBytes'],
        rxVideoBytes = json['rxVideoBytes'],
        txKBitrate = json['txKBitrate'],
        rxKBitrate = json['rxKBitrate'],
        txAudioKBitrate = json['txAudioKBitrate'],
        rxAudioKBitrate = json['rxAudioKBitrate'],
        txVideoKBitrate = json['txVideoKBitrate'],
        rxVideoKBitrate = json['rxVideoKBitrate'],
        lastmileDelay = json['lastmileDelay'],
        txPacketLossRate = json['txPacketLossRate'],
        rxPacketLossRate = json['rxPacketLossRate'],
        users = json['users'],
        cpuTotalUsage = json['cpuTotalUsage'],
        cpuAppUsage = json['cpuAppUsage'];

  Map<String, dynamic> toJson() {
    return {
      "totalDuration": totalDuration,
      "txBytes": txBytes,
      "rxBytes": rxBytes,
      "txAudioBytes": txAudioBytes,
      "txVideoBytes": txVideoBytes,
      "rxAudioBytes": rxAudioBytes,
      "rxVideoBytes": rxVideoBytes,
      "txKBitrate": txKBitrate,
      "rxKBitrate": rxKBitrate,
      "txAudioKBitrate": txAudioKBitrate,
      "rxAudioKBitrate": rxAudioKBitrate,
      "txVideoKBitrate": txVideoKBitrate,
      "rxVideoKBitrate": rxVideoKBitrate,
      "lastmileDelay": lastmileDelay,
      "txPacketLossRate": txPacketLossRate,
      "rxPacketLossRate": rxPacketLossRate,
      "users": users,
      "cpuTotalUsage": cpuTotalUsage,
      "cpuAppUsage": cpuAppUsage,
    };
  }
}

class RemoteAudioStats {
  int uid;
  int quality;
  int networkTransportDelay;
  int jitterBufferDelay;
  int audioLossRate;
  int numChannels;
  int receivedSampleRate;
  int receivedBitrate;
  int totalFrozenTime;
  int frozenRate;

  RemoteAudioStats(
    this.uid,
    this.quality,
    this.networkTransportDelay,
    this.jitterBufferDelay,
    this.audioLossRate,
    this.numChannels,
    this.receivedSampleRate,
    this.receivedBitrate,
    this.totalFrozenTime,
    this.frozenRate,
  );

  RemoteAudioStats.fromJson(Map<dynamic, dynamic> json)
      : uid = json['uid'],
        quality = json['quality'],
        networkTransportDelay = json['networkTransportDelay'],
        jitterBufferDelay = json['jitterBufferDelay'],
        audioLossRate = json['audioLossRate'],
        numChannels = json['numChannels'],
        receivedSampleRate = json['receivedSampleRate'],
        receivedBitrate = json['receivedBitrate'],
        totalFrozenTime = json['totalFrozenTime'],
        frozenRate = json['frozenRate'];

  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "quality": quality,
      "networkTransportDelay": networkTransportDelay,
      "jitterBufferDelay": jitterBufferDelay,
      "audioLossRate": audioLossRate,
      "numChannels": numChannels,
      "receivedSampleRate": receivedSampleRate,
      "receivedBitrate": receivedBitrate,
      "totalFrozenTime": totalFrozenTime,
      "frozenRate": frozenRate
    };
  }
}

enum ChannelProfile {
  /// This is used in one-on-one or group calls, where all users in the channel can talk freely.
  Communication,

  /// Host and audience roles that can be set by calling the [AgoraRtcEngine.setClientRole] method. The host sends and receives voice/video, while the audience can only receive voice/video.
  LiveBroadcasting,
}
