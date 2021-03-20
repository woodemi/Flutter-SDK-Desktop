#import <FlutterMacOS/FlutterMacOS.h>
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>

@interface AgoraTextureRender : NSObject <FlutterTexture, AgoraVideoSinkProtocol>
@property(nonatomic, strong) id<FlutterTextureRegistry> textureRegistry;
@property(nonatomic, assign) int64_t textureId;
@end
