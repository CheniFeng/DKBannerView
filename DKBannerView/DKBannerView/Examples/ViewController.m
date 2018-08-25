//
//  ViewController.m
//  DKBannerView
//
//  Created by 雪凌 on 2018/8/23.
//  Copyright © 2018年 雪凌. All rights reserved.
//

#import "ViewController.h"
#import "DKBannerView.h"

static NSString *const IMAGE_URLSTRING0 = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1535197654779&di=de24b905b427b71e59e3a40cf94cf6a6&imgtype=0&src=http%3A%2F%2Fh.hiphotos.baidu.com%2Fimage%2Fpic%2Fitem%2Fbd3eb13533fa828ba99f3cdbf01f4134970a5a4d.jpg";
static NSString *const IMAGE_URLSTRING1 = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1535197654780&di=62e7923917a019674f7a18c2266faeb2&imgtype=0&src=http%3A%2F%2Fb.hiphotos.baidu.com%2Fimage%2Fpic%2Fitem%2F314e251f95cad1c8e671a21d723e6709c83d51c5.jpg";
static NSString *const IMAGE_URLSTRING2 = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1535197654779&di=28be569195919f38c9c2c774754c05fd&imgtype=0&src=http%3A%2F%2Fa.hiphotos.baidu.com%2Fimage%2Fpic%2Fitem%2F0b55b319ebc4b74583d7b224c2fc1e178a821544.jpg";

#define _images @[IMAGE_URLSTRING0,IMAGE_URLSTRING1,IMAGE_URLSTRING2]

@interface ViewController ()<DKBannerViewDelegate, DKBannerViewDataSource>

@property (nonatomic, weak) IBOutlet DKBannerView *bannerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.bannerView.delegate = self;
    self.bannerView.dataSource = self;
    self.bannerView.autoScroll = YES;
}

#pragma mark- DLMBannerView Delegate And DataSource

- (NSUInteger)numberOfPagesInBannerView:(DKBannerView *)bannerView {
    return _images.count;
}

- (NSString *)bannerView:(DKBannerView *)bannerView imagePathAtPage:(NSUInteger)page {
    return _images[page];
}

- (void)bannerView:(DKBannerView *)bannerView didTouchPage:(NSUInteger)page {
    
}

- (NSArray *)imageURLs {
    return _images;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
