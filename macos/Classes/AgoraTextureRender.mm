#import "AgoraTextureRender.h"

@interface AgoraTextureRender()
@property(nonatomic, assign) CVPixelBufferRef pixelBuffer;
@end

@implementation AgoraTextureRender
- (AgoraVideoBufferType)bufferType {
  return AgoraVideoBufferTypePixelBuffer;
}

- (AgoraVideoPixelFormat)pixelFormat {
  return AgoraVideoPixelFormatNV12;
}

- (void)shouldDispose {

}

- (BOOL)shouldInitialize {
  return YES;
}

- (void)shouldStart {

}

- (void)shouldStop {

}

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer rotation:(AgoraVideoRotation)rotation {
  NSLog(@"renderPixelBuffer");
  CVPixelBufferRelease(self.pixelBuffer);
  self.pixelBuffer = CVPixelBufferRetain(pixelBuffer);
  [self.textureRegistry textureFrameAvailable: self.textureId];
}

- (CVPixelBufferRef _Nullable)copyPixelBuffer {
  NSLog(@"copyPixelBuffer");
  if (self.pixelBuffer != nil) {
    return self.pixelBuffer;
  }
  return nil;
}
@end
