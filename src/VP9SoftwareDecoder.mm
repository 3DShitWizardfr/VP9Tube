#import "VP9SoftwareDecoder.h"
#import <vpx/vpx_decoder.h>
#import <vpx/vp8dx.h>

@implementation VP9SoftwareDecoder {
    vpx_codec_ctx_t _codec;
    BOOL _codecInitialized;
    CVPixelBufferPoolRef _pixelBufferPool;
    int _width;
    int _height;
}

@synthesize isInitialized = _isInitialized;

+ (BOOL)isAvailable {
    return YES;
}

- (instancetype)initWithFormatDescription:(CMFormatDescriptionRef)formatDescription
                    pixelBufferAttributes:(NSDictionary *)pixelBufferAttributes {
    self = [super init];
    if (self) {
        _codecInitialized = NO;
        _pixelBufferPool = NULL;

        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
        _width = dimensions.width;
        _height = dimensions.height;

        vpx_codec_dec_cfg_t cfg = {0};
        cfg.threads = (unsigned int)MIN(NSProcessInfo.processInfo.activeProcessorCount, 4);
        cfg.w = _width;
        cfg.h = _height;

        vpx_codec_err_t res = vpx_codec_dec_init(&_codec, vpx_codec_vp9_dx(), &cfg, 0);
        if (res != VPX_CODEC_OK) {
            NSLog(@"[VP9Tube] Failed to initialize VP9 codec: %s", vpx_codec_err_to_string(res));
            return nil;
        }
        _codecInitialized = YES;
        _isInitialized = YES;

        [self _createPixelBufferPool];
        NSLog(@"[VP9Tube] VP9 software decoder initialized (%dx%d, %u threads)", _width, _height, cfg.threads);
    }
    return self;
}

- (void)_createPixelBufferPool {
    if (_pixelBufferPool) {
        CVPixelBufferPoolRelease(_pixelBufferPool);
        _pixelBufferPool = NULL;
    }

    NSDictionary *poolAttrs = @{
        (NSString *)kCVPixelBufferWidthKey: @(_width),
        (NSString *)kCVPixelBufferHeightKey: @(_height),
        (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
        (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}
    };

    CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL,
                            (__bridge CFDictionaryRef)poolAttrs,
                            &_pixelBufferPool);
}

- (void)decodeFrame:(CMSampleBufferRef)sampleBuffer {
    if (!_codecInitialized) return;

    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    if (!blockBuffer) return;

    size_t length = 0;
    char *dataPointer = NULL;
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &length, &dataPointer);
    if (status != noErr || !dataPointer) return;

    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CMTime duration = CMSampleBufferGetDuration(sampleBuffer);

    dispatch_queue_t queue = _delegateQueue ?: dispatch_get_main_queue();

    vpx_codec_err_t res = vpx_codec_decode(&_codec, (const uint8_t *)dataPointer, (unsigned int)length, NULL, 0);
    if (res != VPX_CODEC_OK) {
        NSLog(@"[VP9Tube] Decode error: %s", vpx_codec_err_to_string(res));
        NSError *error = [NSError errorWithDomain:@"VP9Tube"
                                             code:res
                                         userInfo:@{NSLocalizedDescriptionKey: @(vpx_codec_err_to_string(res))}];
        dispatch_async(queue, ^{
            [self.delegate videoDecoder:self didFailWithError:error];
        });
        return;
    }

    vpx_codec_iter_t iter = NULL;
    vpx_image_t *img;
    while ((img = vpx_codec_get_frame(&_codec, &iter)) != NULL) {
        CVPixelBufferRef pixelBuffer = [self _pixelBufferFromVPXImage:img];
        if (pixelBuffer) {
            dispatch_async(queue, ^{
                [self.delegate videoDecoder:self
                     didOutputPixelBuffer:pixelBuffer
                     presentationTimeStamp:pts
                     duration:duration];
                CVPixelBufferRelease(pixelBuffer);
            });
        }
    }
}

- (CVPixelBufferRef)_pixelBufferFromVPXImage:(vpx_image_t *)img {
    if (!img) return NULL;

    // Handle 8-bit I420 only for now
    if (img->fmt != VPX_IMG_FMT_I420) {
        if (img->fmt == VPX_IMG_FMT_I42016) {
            NSLog(@"[VP9Tube] 10-bit VP9 (Profile 2) not yet supported");
        }
        return NULL;
    }

    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn cvRet;

    if (_pixelBufferPool) {
        cvRet = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _pixelBufferPool, &pixelBuffer);
    } else {
        NSDictionary *attrs = @{
            (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}
        };
        cvRet = CVPixelBufferCreate(kCFAllocatorDefault,
                                     img->d_w, img->d_h,
                                     kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                     (__bridge CFDictionaryRef)attrs,
                                     &pixelBuffer);
    }

    if (cvRet != kCVReturnSuccess || !pixelBuffer) return NULL;

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    // Copy Y plane
    uint8_t *dstY = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    size_t dstYStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    const uint8_t *srcY = img->planes[VPX_PLANE_Y];
    int srcYStride = img->stride[VPX_PLANE_Y];

    for (unsigned int row = 0; row < img->d_h; row++) {
        memcpy(dstY + row * dstYStride, srcY + row * srcYStride, img->d_w);
    }

    // Interleave U+V into NV12 CbCr plane
    uint8_t *dstUV = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    size_t dstUVStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    const uint8_t *srcU = img->planes[VPX_PLANE_U];
    const uint8_t *srcV = img->planes[VPX_PLANE_V];
    int srcUStride = img->stride[VPX_PLANE_U];
    int srcVStride = img->stride[VPX_PLANE_V];
    unsigned int uvHeight = (img->d_h + 1) / 2;
    unsigned int uvWidth = (img->d_w + 1) / 2;

    for (unsigned int row = 0; row < uvHeight; row++) {
        const uint8_t *uRow = srcU + row * srcUStride;
        const uint8_t *vRow = srcV + row * srcVStride;
        uint8_t *uvDst = dstUV + row * dstUVStride;
        for (unsigned int col = 0; col < uvWidth; col++) {
            uvDst[col * 2]     = uRow[col];
            uvDst[col * 2 + 1] = vRow[col];
        }
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return pixelBuffer;
}

- (void)flush {
    if (_codecInitialized) {
        vpx_codec_decode(&_codec, NULL, 0, NULL, 0);
        vpx_codec_iter_t iter = NULL;
        while (vpx_codec_get_frame(&_codec, &iter) != NULL) {}
    }
}

- (void)invalidate {
    if (_codecInitialized) {
        vpx_codec_destroy(&_codec);
        _codecInitialized = NO;
        _isInitialized = NO;
    }
    if (_pixelBufferPool) {
        CVPixelBufferPoolRelease(_pixelBufferPool);
        _pixelBufferPool = NULL;
    }
}

- (void)dealloc {
    [self invalidate];
}

@end
