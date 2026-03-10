#import <CoreMedia/CoreMedia.h>
#import "VP9SoftwareDecoder.h"

#ifndef kCMVideoCodecType_VP9
#define kCMVideoCodecType_VP9 'vp09'
#endif

static BOOL isVP9Format(id formatDescription) {
    if (!formatDescription) return NO;
    CMFormatDescriptionRef desc = (__bridge CMFormatDescriptionRef)formatDescription;
    FourCharCode codecType = CMFormatDescriptionGetMediaSubType(desc);
    return codecType == kCMVideoCodecType_VP9;
}

static VP9SoftwareDecoder *makeVP9DecoderWithAttrs(id formatDescription, id pixelBufferAttributes, id delegate, id delegateQueue) {
    NSLog(@"[VP9Tube] Intercepting VP9 — using bundled libvpx decoder");
    VP9SoftwareDecoder *decoder = [[VP9SoftwareDecoder alloc]
        initWithFormatDescription:(__bridge CMFormatDescriptionRef)formatDescription
            pixelBufferAttributes:pixelBufferAttributes];
    if (decoder) {
        decoder.delegate = delegate;
        decoder.delegateQueue = delegateQueue;
    }
    return decoder;
}

%hook MLVideoDecoderFactory

- (id)videoDecoderWithDelegate:(id)delegate delegateQueue:(id)delegateQueue formatDescription:(id)formatDescription pixelBufferAttributes:(id)pixelBufferAttributes preferredOutputFormats:(id)preferredOutputFormats error:(NSError **)error {
    if (isVP9Format(formatDescription)) {
        VP9SoftwareDecoder *decoder = makeVP9DecoderWithAttrs(formatDescription, pixelBufferAttributes, delegate, delegateQueue);
        if (decoder) return decoder;
        NSLog(@"[VP9Tube] Bundled decoder init failed, falling through");
    }
    return %orig;
}

- (id)videoDecoderWithDelegate:(id)delegate delegateQueue:(id)delegateQueue formatDescription:(id)formatDescription pixelBufferAttributes:(id)pixelBufferAttributes setPixelBufferTypeOnlyIfEmpty:(BOOL)setPixelBufferTypeOnlyIfEmpty error:(NSError **)error {
    if (isVP9Format(formatDescription)) {
        VP9SoftwareDecoder *decoder = makeVP9DecoderWithAttrs(formatDescription, pixelBufferAttributes, delegate, delegateQueue);
        if (decoder) return decoder;
    }
    return %orig;
}

- (id)videoDecoderWithDelegate:(id)delegate delegateQueue:(id)delegateQueue formatDescription:(id)formatDescription pixelBufferAttributes:(id)pixelBufferAttributes error:(NSError **)error {
    if (isVP9Format(formatDescription)) {
        VP9SoftwareDecoder *decoder = makeVP9DecoderWithAttrs(formatDescription, pixelBufferAttributes, delegate, delegateQueue);
        if (decoder) return decoder;
    }
    return %orig;
}

%end

%hook HAMDefaultVideoDecoderFactory

- (id)videoDecoderWithDelegate:(id)delegate delegateQueue:(id)delegateQueue formatDescription:(id)formatDescription pixelBufferAttributes:(id)pixelBufferAttributes preferredOutputFormats:(id)preferredOutputFormats error:(NSError **)error {
    if (isVP9Format(formatDescription)) {
        VP9SoftwareDecoder *decoder = makeVP9DecoderWithAttrs(formatDescription, pixelBufferAttributes, delegate, delegateQueue);
        if (decoder) return decoder;
    }
    return %orig;
}

- (id)videoDecoderWithDelegate:(id)delegate delegateQueue:(id)delegateQueue formatDescription:(id)formatDescription pixelBufferAttributes:(id)pixelBufferAttributes setPixelBufferTypeOnlyIfEmpty:(BOOL)setPixelBufferTypeOnlyIfEmpty error:(NSError **)error {
    if (isVP9Format(formatDescription)) {
        VP9SoftwareDecoder *decoder = makeVP9DecoderWithAttrs(formatDescription, pixelBufferAttributes, delegate, delegateQueue);
        if (decoder) return decoder;
    }
    return %orig;
}

- (id)videoDecoderWithDelegate:(id)delegate delegateQueue:(id)delegateQueue formatDescription:(id)formatDescription pixelBufferAttributes:(id)pixelBufferAttributes error:(NSError **)error {
    if (isVP9Format(formatDescription)) {
        VP9SoftwareDecoder *decoder = makeVP9DecoderWithAttrs(formatDescription, pixelBufferAttributes, delegate, delegateQueue);
        if (decoder) return decoder;
    }
    return %orig;
}

%end

