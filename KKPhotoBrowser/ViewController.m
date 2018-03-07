//
//  ViewController.m
//  KKPhotoBrowser
//
//  Created by coze on 2017/5/24.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#import "ViewController.h"
#import "KKMediaBrowser.h"
#import "KKMedia.h"
#import "DemoImageView.h"
#import "DemoSupplementaryView.h"
#import "UIImage+KKDecode.h"

@interface ViewController () <KKMediaBrowserDelegate, KKMediaBrowserDataSource>

@property (nonatomic, strong) NSMutableArray *photos;

@property (weak, nonatomic) IBOutlet DemoImageView *imageView1;
@property (weak, nonatomic) IBOutlet DemoImageView *imageView2;
@property (weak, nonatomic) IBOutlet DemoImageView *imageView3;

@property (nonatomic, strong) DemoSupplementaryView *header;
@property (nonatomic, strong) DemoSupplementaryView *footer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView1.userInteractionEnabled = YES;
    self.imageView1.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *original = [UIImage imageNamed:@"photo1.jpg"];
    UIImage *test = [original scaleToSize:CGSizeMake(320, 320)];
    self.imageView1.image = test;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewDidTap:)];
    [self.imageView1 addGestureRecognizer:tap];
    self.imageView1.tag = 100;
    
    self.imageView2.userInteractionEnabled = YES;
    self.imageView2.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView2.image = [UIImage imageNamed:@"photo2.jpg"];
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewDidTap:)];
    [self.imageView2 addGestureRecognizer:tap];
    self.imageView2.tag = 101;
    
    self.imageView3.userInteractionEnabled = YES;
    self.imageView3.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView3.image = [UIImage imageNamed:@"video_thumb.jpg"];
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewDidTap:)];
    [self.imageView3 addGestureRecognizer:tap];
    self.imageView3.tag = 102;
    
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    KKMedia *photo;
    
    // Local Photos and Videos
    photo = [KKMedia mediaWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"photo1" ofType:@"jpg"]]];
    photo.placeholderImage = [UIImage imageNamed:@"photo1.jpg"];
    [photos addObject:photo];
    self.imageView1.media = photo;
    photo = [KKMedia mediaWithPhotoURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"photo2" ofType:@"jpg"]]];
    photo.placeholderImage = [UIImage imageNamed:@"photo2.jpg"];
    [photos addObject:photo];
    self.imageView2.media = photo;
    photo = [KKMedia mediaWithVideoURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"]]];
    photo.placeholderImage = [UIImage imageNamed:@"video_thumb.jpg"];
    [photos addObject:photo];
    self.imageView3.media = photo;
    
    self.photos = photos;
}

- (void)imageViewDidTap:(UITapGestureRecognizer *)tap {
  
    UIView *imageView = tap.view;
    NSUInteger index = imageView.tag - 100;
    KKMediaBrowser *browser = [[KKMediaBrowser alloc] initWithDataSource:self initialIndex:index];
    browser.delegate = self;
    
//    [self.navigationController pushViewController:browser animated:YES];
    [self presentViewController:browser animated:YES completion:nil];
    
}

- (NSUInteger)numberOfMediaInMediaBrowser:(KKMediaBrowser *)mediaBrowser {
    return _photos.count;
}

- (id<KKMediaProtocol>)mediaBrowser:(KKMediaBrowser *)mediaBrowser mediaAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}

- (NSArray <__kindof KKMediaFromViewState*>*)animatedFromViewsForMediaBrowser:(KKMediaBrowser *)mediaBrowser {
    NSMutableArray *views = [NSMutableArray array];
    KKMediaFromViewState *viewState = [[KKMediaFromViewState alloc] init];
    viewState.senderViewForAnimation = self.imageView1;
    viewState.media = self.imageView1.media;
    [views addObject:viewState];
    
    viewState = [[KKMediaFromViewState alloc] init];
    viewState.senderViewForAnimation = self.imageView2;
    viewState.media = self.imageView2.media;
    [views addObject:viewState];
    
    viewState = [[KKMediaFromViewState alloc] init];
    viewState.senderViewForAnimation = self.imageView3;
    viewState.media = self.imageView3.media;
    [views addObject:viewState];
    
    return views;
}

- (NSArray<UIAlertAction *> *)actionArrayForMedia:(id<KKMediaProtocol>)media withStatus:(KKMediaDataStatus)status {
    NSMutableArray *array = [NSMutableArray array];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"测试一" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       NSLog(@"%@", media);
    }];
    [array addObject:action1];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"测试二" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull button) {
        [self test];
    }];
    [array addObject:action2];
    
    return array;
}

- (void)test {
    NSLog(@"test");
}


- (DemoSupplementaryView *)header {
    if (!_header) {
        _header = [[DemoSupplementaryView alloc] init];
        _header.isHeader = YES;
    }
    return _header;
}

- (DemoSupplementaryView *)footer {
    if (!_footer) {
       _footer = [[DemoSupplementaryView alloc] init];
    }
    return _footer;
}

#pragma mark - KKMediaBrowserDataSource

- (NSArray <__kindof UIView<KKMediaSupplementaryViewProtocol>*> *)supplementaryViewsForMediaBrowser:(KKMediaBrowser *)mediaBrowser {
    return @[self.header, self.footer];
}

#pragma mark - KKMediaBrowserDelage

- (void)mediaBrowser:(KKMediaBrowser *)mediaBrowser didShowMediaAtIndex:(NSUInteger)index {
    self.header.label.text = [NSString stringWithFormat:@"header - %lu", (unsigned long)index];
    self.footer.label.text = [NSString stringWithFormat:@"footer - %lu", (unsigned long)index];
}

@end
