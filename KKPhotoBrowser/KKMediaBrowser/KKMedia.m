//
//  KKMedia.m
//  KKPhotoBrowser
//
//  Created by coze on 2017/5/26.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#import "KKMedia.h"
#import <YYWebImage.h>
#import <AssetsLibrary/AssetsLibrary.h>


@implementation KKMedia {
    BOOL _loadingInProgress;
    YYWebImageOperation *_webImageOperation;
}

@synthesize underlyingData = _underlyingData,
mediaType = _mediaType,
dataStatus = _dataStatus,
progressUpdateBlock = _progressUpdateBlock,
loadingEndBlock = _loadingEndBlock;


#pragma mark - Class methods

+ (KKMedia *)mediaWithImage:(UIImage *)image {
    return [[self alloc] initWithImage:image];
}

+ (KKMedia *)mediaWithPhotoURL:(NSURL *)url {
    return [[self alloc] initWithPhotoURL:url];
}

+ (KKMedia *)mediaWithVideoURL:(NSURL *)url {
    return [[self alloc] initWithVideoURL:url];
}

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mediaType = KKMediaTypePhoto;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    if ((self = [super init])) {
        _image = image;
        _mediaType = KKMediaTypePhoto;
        _dataStatus = KKMediaDataStatusLoading;
    }
    return self;
}

- (instancetype)initWithPhotoURL:(NSURL *)url {
    if ((self = [super init])) {
        _URL = url;
        _mediaType = KKMediaTypePhoto;
        _dataStatus = KKMediaDataStatusLoading;
    }
    return self;
}

- (instancetype)initWithVideoURL:(NSURL *)url {
    if ((self = [super init])) {
        _URL = url;
        _mediaType = KKMediaTypeVideo;
        _dataStatus = KKMediaDataStatusLoading;
    }
    return self;
}

- (void)dealloc {
    [self cancelAnyLoading];
}


#pragma mark - KKMediaProtocol methods

- (id)underlyingData {
    return _underlyingData;
}

- (void)loadUnderlyingDataAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (_loadingInProgress) return;
    _loadingInProgress = YES;
    @try {
        if (self.underlyingData) {
            [self dataLoadingComplete:@(KKMediaDataStatusSuccess)];
        } else {
            [self performLoadUnderlyingDataAndNotify];
        }
    }
    @catch (NSException *exception) {
        self.underlyingData = nil;
        _loadingInProgress = NO;
        [self dataLoadingComplete:@(KKMediaDataStatusFailure)];
    }
    @finally {
    }
}

// Set the underlyingImage
- (void)performLoadUnderlyingDataAndNotify {
    
    // Get underlying image
    if (_image) {
        
        // We have UIImage!
        self.underlyingData = _image;
        [self dataLoadingComplete:@(KKMediaDataStatusSuccess)];
        
    } else if (_URL) {
        
        if (_mediaType == KKMediaTypeVideo) {
            self.underlyingData = _URL;
            [self dataLoadingComplete:@(KKMediaDataStatusSuccess)];
            return;
        }
        
        // Check what type of url it is
        if ([[[_URL scheme] lowercaseString] isEqualToString:@"assets-library"]) {
            
            // Load from assets library
            [self _performLoadUnderlyingImageAndNotifyWithAssetsLibraryURL:_URL];
            
        } else if ([_URL isFileReferenceURL]) {
            
            // Load from local file async
            [self _performLoadUnderlyingImageAndNotifyWithLocalFileURL:_URL];
            
        } else {
            // Load async from web (using SDWebImage)
            [self _performLoadUnderlyingImageAndNotifyWithWebURL:_URL];
            
        }
        
    } else {
        // Image is empty
        [self dataLoadingComplete:@(KKMediaDataStatusFailure)];
        
    }
}

// Load async from web
- (void)_performLoadUnderlyingImageAndNotifyWithWebURL:(NSURL *)url {
    @try {
        YYWebImageOptions options = YYWebImageOptionAllowBackgroundTask;
        NSURL *url = self.URL;
        if ([url isKindOfClass:[NSString class]]) {
            url = [NSURL URLWithString:(NSString *)url];
        }
        _webImageOperation = [[YYWebImageManager sharedManager] requestImageWithURL:url options:options progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            
            if (expectedSize > 0) {
                CGFloat progress = (CGFloat)receivedSize / (CGFloat)expectedSize;
                if (self.progressUpdateBlock) {
                    self.progressUpdateBlock(progress);
                }
            }
            
        } transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
            
            KKMediaDataStatus status = KKMediaDataStatusLoading;
            
            if (error) {
                status = KKMediaDataStatusFailure;
                NSLog(@"YYWebImage failed to download image: %@", error);
            } else {
                status = KKMediaDataStatusSuccess;
                self.underlyingData = image;
            }
            
            _webImageOperation = nil;
            
            [self performSelectorOnMainThread:@selector(dataLoadingComplete:) withObject:@(status) waitUntilDone:NO];
            
        }];
    } @catch (NSException *e) {
        NSLog(@"Photo from web: %@", e);
        _webImageOperation = nil;
        [self dataLoadingComplete:@(KKMediaDataStatusFailure)];
    }
}

// Load from local file
- (void)_performLoadUnderlyingImageAndNotifyWithLocalFileURL:(NSURL *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            @try {
                self.underlyingData = [UIImage imageWithContentsOfFile:url.path];
                if (!_underlyingData) {
                    NSLog(@"Error loading photo from path: %@", url.path);
                }
            } @finally {
                self.underlyingData = [self decodedImageWithImage:self.underlyingData];
                [self performSelectorOnMainThread:@selector(dataLoadingComplete:) withObject:@(KKMediaDataStatusSuccess) waitUntilDone:NO];
            }
        }
    });
}

// Load from asset library async
- (void)_performLoadUnderlyingImageAndNotifyWithAssetsLibraryURL:(NSURL *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            @try {
                ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
                [assetslibrary assetForURL:url
                               resultBlock:^(ALAsset *asset){
                                   ALAssetRepresentation *rep = [asset defaultRepresentation];
                                   CGImageRef iref = [rep fullScreenImage];
                                   if (iref) {
                                       self.underlyingData = [UIImage imageWithCGImage:iref];
                                   }
                                   [self performSelectorOnMainThread:@selector(dataLoadingComplete:) withObject:@(KKMediaDataStatusSuccess) waitUntilDone:NO];
                               }
                              failureBlock:^(NSError *error) {
                                  self.underlyingData = nil;
                                  NSLog(@"Photo from asset library error: %@",error);
                                  [self performSelectorOnMainThread:@selector(dataLoadingComplete:) withObject:@(KKMediaDataStatusFailure) waitUntilDone:NO];
                              }];
            } @catch (NSException *e) {
                NSLog(@"Photo from asset library error: %@", e);
                [self performSelectorOnMainThread:@selector(dataLoadingComplete:) withObject:@(KKMediaDataStatusFailure) waitUntilDone:NO];
            }
        }
    });
}

- (UIImage *)decodedImageWithImage:(UIImage *)image {
    if (image.images) {
        // Do not decode animated images
        return image;
    }
    
    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGRect imageRect = (CGRect){.origin = CGPointZero, .size = imageSize};
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
    
    // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
    // https://developer.apple.com/library/mac/#qa/qa1037/_index.html
    if (infoMask == kCGImageAlphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1)
    {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        
        // Set noneSkipFirst.
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    // Some PNGs tell us they have alpha but only 3 components. Odd.
    else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3)
    {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    }
    
    // It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 imageSize.width,
                                                 imageSize.height,
                                                 CGImageGetBitsPerComponent(imageRef),
                                                 0,
                                                 colorSpace,
                                                 bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    // If failed, return undecompressed image
    if (!context) return image;
    
    CGContextDrawImage(context, imageRect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingData {
    _loadingInProgress = NO;
    self.underlyingData = nil;
}

- (void)dataLoadingComplete:(NSNumber *)status {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    
    _loadingInProgress = NO;
    
    if ([status isKindOfClass:NSNumber.class]) {
        self.dataStatus = (KKMediaDataStatus)status.unsignedIntValue;
    } else {
        if (self.underlyingData) {
            self.dataStatus = KKMediaDataStatusSuccess;
        } else {
            self.dataStatus = KKMediaDataStatusFailure;
        }
    }
    
    [self performSelector:@selector(postCompleteNotification) withObject:nil afterDelay:0];
}

- (void)postCompleteNotification {
    if (self.loadingEndBlock) {
        __weak typeof(self) wself = self;
        self.loadingEndBlock(wself);
    }
}

- (void)cancelAnyLoading {
    if (_webImageOperation != nil) {
        [_webImageOperation cancel];
        _loadingInProgress = NO;
    }
}

@end
