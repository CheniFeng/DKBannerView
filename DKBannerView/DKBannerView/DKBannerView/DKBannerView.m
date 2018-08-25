//
//  DKBannerView.m
//  DKBannerView
//
//  Created by 雪凌 on 2018/8/23.
//  Copyright © 2018年 雪凌. All rights reserved.
//

#import "DKBannerView.h"
#import "UIImageView+AFNetworking.h"

#define DEFAULT_TIMEINTERVAL  5.0f  // 默认滚动时间间隔
#define MIN_TIMEINTERVAL  0.3f  // 最小的滚动时间间隔
#define REUSE_IDENTIFIER  @"DKBannerCollectionCell"


@interface DKWeaker : NSObject

/**
 *  初始化一个weaker，并弱引用被传入的对象
 *  @param object 需要被弱引用的对象
 *  @return 一个弱引用了指定对象的Weaker。
 */
- (instancetype)initWithObject:(id)object NS_DESIGNATED_INITIALIZER;

@end

@interface DKWeaker()

@property (nonatomic, weak) id target;

@end

@implementation DKWeaker

- (instancetype)initWithObject:(id)object {
    self = [super init];
    if (self) {
        _target = object;
    }
    return self;
}

- (instancetype)init {
    return [self initWithObject:nil];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.target;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    void *nullPointer = NULL;
    [invocation setReturnValue:&nullPointer];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

@end


@interface DKBannerCollectionCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UIImageView *imageView;

@end

@implementation DKBannerCollectionCell

@synthesize imageView = _imageView;


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self viewInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self viewInit];
    }
    return self;
}

#pragma mark- *** View Init ***

- (void)viewInit {
    _imageView = [[UIImageView alloc] init];
    _imageView.backgroundColor = [UIColor clearColor];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self addSubview:_imageView];
}

#pragma mark- *** Layout Subviews ***

- (void)layoutSubviews {
    _imageView.frame = self.bounds;
    [super layoutSubviews];
}

@end

@interface DKBannerView()<UICollectionViewDelegate,
                        UICollectionViewDataSource,
                        UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation DKBannerView

@synthesize placeholder = _placeholder;
@synthesize autoScroll = _autoScroll;
@synthesize timeInterval = _timeInterval;
@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;
@synthesize imageViewMode = _imageViewMode;
@synthesize scrollDirection = _scrollDirection;
@synthesize pageIndicatorTintColor = _pageIndicatorTintColor;
@synthesize currentPageIndicatorTintColor = _currentPageIndicatorTintColor;


- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self viewInit];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self viewInit];
    }
    return self;
}


#pragma mark- *** View Init ***

- (void)viewInit {
    
    // 设置默认属性
    _imageViewMode = UIViewContentModeScaleAspectFill;
    _timeInterval = DEFAULT_TIMEINTERVAL;
    _autoScroll = YES;
    _scrollDirection = DKBannerViewScrollDirectionLeft;
    _pageCount = 0;
    _currentPageIndicatorTintColor = [UIColor whiteColor];
    _pageIndicatorTintColor = [UIColor grayColor];
    self.backgroundColor = [UIColor lightGrayColor];
    
    
    // 创建CollectionViewLayout
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
    
    // 创建CCollectionView
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds
                                             collectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self addSubview:self.collectionView];
    
    
    // 创建PageCountr
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = 0;
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.enabled = NO;
    self.pageControl.currentPageIndicatorTintColor = _currentPageIndicatorTintColor;
    self.pageControl.pageIndicatorTintColor = _pageIndicatorTintColor;
    
    [self addSubview:self.pageControl];
    
    // 注册Cell
    [self.collectionView registerClass:[DKBannerCollectionCell class]
            forCellWithReuseIdentifier:REUSE_IDENTIFIER];
    
    // 注册通知
    [self registerNofitication];
}

#pragma mark- *** Nofitication ***

- (void)registerNofitication {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

// 程序被暂停的时候，应该停止计时器
- (void)applicationWillResignActive {
    [self stopMoving];
}

// 程序从暂停状态回归的时候，重新启动计时器
- (void)applicationDidBecomeActive {
    [self startMovingIfNeeded];
}

#pragma mark - *** UICollectionViewDelegate ***

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (_pageCount > 1) {
        return _pageCount + 2;
    }
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DKBannerCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:REUSE_IDENTIFIER forIndexPath:indexPath];
    
    cell.imageView.contentMode = self.imageViewMode;
    
    if (!_pageCount) {
        [cell.imageView setImage:self.placeholder];
        return cell;
    }
    
    NSString *imagePath = [self.dataSource bannerView:self
                                      imagePathAtPage:[self pageWithIndexPath:indexPath]];
    [cell.imageView setImageWithURL:[NSURL URLWithString:imagePath]
                      placeholderImage:self.placeholder];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.bounds.size.width, collectionView.bounds.size.height);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(bannerView:didTouchPage:)]) {
        [self.delegate bannerView:self didTouchPage:[self pageWithIndexPath:indexPath]];
    }
}


#pragma mark - UIScrollerViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self adjustCurrentPageWithContentOffset:scrollView.contentOffset];
    [self jumpWithContentOffset:scrollView.contentOffset];
}

// 用户手动拖拽，暂停一下自动轮播
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self removeTimer];
}

// 用户拖拽完成，恢复自动轮播（如果需要的话）
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self startMovingIfNeeded];
}

#pragma mark- Public Method

- (void)startMoving {
    [self startMovingIfNeeded];
}

- (void)stopMoving {
    [self removeTimer];
}

- (void)startMovingIfNeeded {
    if (self.isAutoScroll && _pageCount > 1) {
        [self addTimer];
    }
}

- (void)reloadData {
    
    _pageCount = 0;
    if ([_dataSource numberOfPagesInBannerView:self]) {
        _pageCount = [_dataSource numberOfPagesInBannerView:self];
    }
    
    [self.collectionView reloadData];
    
    self.collectionView.scrollEnabled = _pageCount > 1;
    self.pageControl.numberOfPages = _pageCount;
    
    if (_pageCount > 1) {
        // 根据滚动方向，移动到第一张或者最后一张图片的位置
        NSInteger item = (self.scrollDirection == DKBannerViewScrollDirectionLeft) ?
        1 : _pageCount;
        
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionNone
                                            animated:NO];
    }
    
    [self startMovingIfNeeded];
}

#pragma mark - About Page Method

- (void)jumpToLastImage
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_pageCount inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
}

- (void)jumpToFirstImage {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
}

- (void)jumpWithContentOffset:(CGPoint)contentOffset {
    // 向左滑动时切换imageView
    if (contentOffset.x <= 0) {
        [self jumpToLastImage];
    }
    
    // 向右滑动时切换imageView
    if (contentOffset.x >= (_pageCount + 1) * self.frame.size.width) {
        [self jumpToFirstImage];
    }
}

- (void)adjustCurrentPageWithContentOffset:(CGPoint)contentOffset
{
    // 以中线作为判断点，过了中线才算是到了下一页。
    CGPoint adjustPoint = CGPointMake(contentOffset.x + (0.5 * self.frame.size.width),
                                      contentOffset.y);
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:adjustPoint];
    NSInteger currentPage = [self pageWithIndexPath:indexPath];
    
    // 只有当页面的值改变的时候才赋值并通知 Delegate, 防止值不变的时候不停地通知
    if (self.currentPage == currentPage) {
        return;
    }
    
    self.currentPage = currentPage;
    self.pageControl.currentPage = currentPage;
    [self tellDelegateCurrentPage];
}

// 将当前的 indexPath 的 item 值 转成 page
- (NSInteger)pageWithIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger page;
    NSInteger index = indexPath.item;
    NSInteger suffixIndex = _pageCount + 1;
    NSInteger prefixIndex = 0;
    
    NSInteger firstPage = 0;
    NSInteger lastPage = _pageCount - 1;
    
    if (index == prefixIndex) {
        page = lastPage;
    } else if (index == suffixIndex) {
        page = firstPage;
    }else {
        page = index - 1;
    }
    return page;
}

- (void)tellDelegateCurrentPage {
    if ([self.delegate respondsToSelector:@selector(bannerView:didMoveToPage:)]) {
        [self.delegate bannerView:self didMoveToPage:self.currentPage];
    }
}

#pragma mark- Timer

- (void)addTimer {
    
    [self removeTimer];
    NSTimeInterval speed = self.timeInterval < MIN_TIMEINTERVAL ? DEFAULT_TIMEINTERVAL : self.timeInterval;
    DKWeaker *target = [[DKWeaker alloc] initWithObject:self];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:speed
                                                  target:target
                                                selector:@selector(scrollToNextPage)
                                                userInfo:nil
                                                 repeats:YES];
    self.timer.tolerance = 0.1 * speed;
}

- (void)removeTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)scrollToNextPage {
    
    if (_pageCount > 1) {
        NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:self.collectionView.contentOffset];
        NSInteger item = (self.scrollDirection == DKBannerViewScrollDirectionLeft) ?
        (currentIndexPath.item + 1) : (currentIndexPath.item - 1);
        
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:item
                                                         inSection:currentIndexPath.section];
        [self.collectionView scrollToItemAtIndexPath:nextIndexPath
                                    atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                            animated:YES];
    }
}

#pragma mark- Setters And Getters

- (void)setDataSource:(id<DKBannerViewDataSource>)dataSource {
    _dataSource = dataSource;
    if (_dataSource) { [self reloadData]; }
}

- (void)setAutoScroll:(BOOL)autoScroll {
    _autoScroll = autoScroll;
    [self stopMoving];
    [self startMovingIfNeeded];
}

- (void)setTimeInterval:(CGFloat)timeInterval {
    _timeInterval = timeInterval;
    [self startMovingIfNeeded];
}

- (void)setPageIndicatorTintColor:(UIColor *)pageIndicatorTintColor {
    _pageIndicatorTintColor = pageIndicatorTintColor;
    _pageControl.pageIndicatorTintColor = _pageIndicatorTintColor;
}

- (void)setCurrentPageIndicatorTintColor:(UIColor *)currentPageIndicatorTintColor {
    _currentPageIndicatorTintColor = currentPageIndicatorTintColor;
    _pageControl.currentPageIndicatorTintColor = _currentPageIndicatorTintColor;
}

#pragma mark- Layout Subviews

- (void)layoutSubviews {
    
    self.collectionView.frame = self.bounds;
    self.pageControl.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - 40, CGRectGetWidth(self.bounds), 30);
    [self reloadData];
    
    [super layoutSubviews];
}

#pragma mark- Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

