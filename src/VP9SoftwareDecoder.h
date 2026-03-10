#ifndef VP9_SOFTWARE_DECODER_H
#define VP9_SOFTWARE_DECODER_H

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

@protocol VP9DecoderDelegate <NSObject>
- (void)videoDecoder:(id)decoder
    didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
    presentationTimeStamp:(CMTime)pts
    duration:(CMTime)duration;
- (void)videoDecoder:(id)decoder didFailWithError:(NSError *)error;
@end

@interface VP9SoftwareDecoder : NSObject

@property (nonatomic, weak) id<VP9DecoderDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, readonly) BOOL isInitialized;

- (instancetype)initWithFormatDescription:(CMFormatDescriptionRef)formatDescription
                    pixelBufferAttributes:(NSDictionary *)pixelBufferAttributes;
- (void)decodeFrame:(CMSampleBufferRef)sampleBuffer;
- (void)flush;
- (void)invalidate;

+ (BOOL)isAvailable;

@end

#endif
