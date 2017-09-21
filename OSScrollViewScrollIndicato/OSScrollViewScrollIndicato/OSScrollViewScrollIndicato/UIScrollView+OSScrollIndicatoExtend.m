//
//  UIScrollView+OSScrollIndicatoExtend.m
//  OSScrollViewScrollIndicato
//
//  Created by Ossey on 05/08/2017.
//  Copyright © 2017 Ossey. All rights reserved.
//

#import "UIScrollView+OSScrollIndicatoExtend.h"
#import <objc/runtime.h>

/**
 此结构体用于保存初始化OSScrollIndicatoView时，scrollView的某些属性值，
 当scrollView移除OSScrollIndicatoView时，恢复scrollView之前的属性值
 */
typedef struct {
    BOOL showsVerticalScrollIndicator;
    BOOL scrollEnabled;
} OSScrollIndicatoScrollViewState;

static void * OSScrollIndicatoScrollViewContext = &OSScrollIndicatoScrollViewContext;
/**
 根据OSScrollIndicatoViewDefaultWidth确定self及子控件的宽度
 */
static CGFloat OSScrollIndicatoViewDefaultWidth = 20.0;

@interface NSObject (XYSwizzlingExtension)

+ (void)exchangeImplementationWithSelector:(SEL)originSelector swizzledSelector:(SEL)swizzledSelector;

@end


#pragma mark *** UIScrollView () ***

@interface UIScrollView ()

@property (nonatomic, strong) OSScrollIndicatoView *os_scrollIndicatoView;

@end

#pragma mark *** OSScrollIndicatoView ***

@interface OSScrollIndicatoView ()

/// 所在的tableView
@property (nonatomic, weak) UIScrollView *scrollView;
/// 调用setHidden: 方法时，会设置此属性
@property (nonatomic, assign) BOOL userHidden;
/// 指示器所在的轨道
@property (nonatomic, weak) UIImageView *trackView;
/// 指示器
@property (nonatomic, weak) UIImageView *indicatoView;
/// 是否有手指拖动在indicatoView上面
@property (nonatomic, assign) BOOL dragging;
/// 手指中心的偏移量
@property (nonatomic, assign) CGPoint fingerOffset;
@property (nonatomic, assign) BOOL disabled;
#ifdef __IPHONE_10_0
@property (nonatomic, strong) UIImpactFeedbackGenerator *feedbackGenerator;
#endif
@property (nonatomic, assign) OSScrollIndicatoScrollViewState scrollViewSate;

@end

@implementation OSScrollIndicatoView

@synthesize
trackTintColor = _trackTintColor,
indicatoTintColor = _indicatoTintColor;

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////

- (instancetype)initWithIndicatoStyle:(OSScrollIndicatoStyle)indicatoStyle {
    self = [self initWithFrame:CGRectZero];
    _indicatoStyle = indicatoStyle;
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self __setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self __setup];
    }
    return self;
}


- (void)__setup {
    _indicatoMinimiumHeight = 30.0;
    _minimumContentHeightScale = 0.98;
    _contentEdgeInsets = UIEdgeInsetsMake(2.0, 0.0, 2.0, 5.0);
#ifdef __IPHONE_10_0
    _feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
#endif
    self.backgroundColor = [UIColor clearColor];
    
    _scrollViewSate.showsVerticalScrollIndicator = NO;
    _scrollViewSate.scrollEnabled = NO;
    
}



- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    // 初始化trackView 和 indicatoView
    [self setIndicatoStyle:self.indicatoStyle];
}

- (void)removeFromSuperview {
    
    [self restoreScrollView:_scrollView];
    [super removeFromSuperview];
        _scrollView.os_scrollIndicatoView = nil;
    _scrollView = nil;
    
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Public methods
////////////////////////////////////////////////////////////////////////

- (void)setCustomView:(UIView *)customView {
    if (_customView == customView) {
        return;
    }
    
    _customView = customView;
    [self addSubview:customView];
    [self setNeedsLayout];
}

- (void)setIndicatoStyle:(OSScrollIndicatoStyle)indicatoStyle {
    
    if (indicatoStyle == OSScrollIndicatoStyleNone) {
        [self restoreScrollView:self.scrollView];
        [self removeFromSuperview];
        
    }
    
    if (indicatoStyle == _indicatoStyle) {
        return;
    }
    
    _indicatoStyle = indicatoStyle;
    
    CGFloat whiteColor = 0.3;
    CGFloat alpha = 0.1;
    
    switch (indicatoStyle) {
        case OSScrollIndicatoStyleDark:
            whiteColor = 0.8;
            alpha = 0.6;
            break;
            
        default:
            break;
    }
    self.trackView.tintColor = [UIColor colorWithWhite:whiteColor alpha:alpha];
    self.indicatoView.tintColor = [UIColor colorWithWhite:0.5 alpha:1.0];
}

- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView == scrollView) {
        return;
    }
    
    // 移除旧的scrollView的kvo
    [self restoreScrollView:_scrollView];
    
    _scrollView = scrollView;
    
    [self setupScrollView:scrollView];
    [scrollView addSubview:self];
    
    scrollView.os_scrollIndicatoView = self;
    
    [self layoutInScrollView];
}


- (void)setHidden:(BOOL)hidden {
    self.userHidden = hidden;
    [self setHidden:hidden animated:NO];
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated {
    if (_disabled) {
        super.hidden = YES;
        return;
    }
    CGFloat alpha = hidden ? 0.0 : 1.0;
    if (!animated) {
        self.alpha = alpha;
        super.hidden = hidden;
        return;
    }
    
    if (self.isHidden && hidden == NO) {
        [UIView performWithoutAnimation:^{
            self.alpha = alpha;
            super.hidden = NO;
            [self layoutInScrollView];
            [self setNeedsDisplay];
        }];
    }
    
    if (!hidden) {
        self.alpha = alpha;
    }
    
    CGRect fromRect = self.frame;
    CGRect toRect = self.frame;
    
    CGFloat widestElement = MAX(self.trackWidth, self.indicatoWidth);
    CGFloat indicatoOffset = fromRect.origin.x + _contentEdgeInsets.right + widestElement * 2.0;
    
    if (hidden == NO) {
        fromRect.origin.x = indicatoOffset;
    }
    else {
        toRect.origin.x = indicatoOffset;
    }
    self.frame = fromRect;

    [UIView animateWithDuration:3.0
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.1
                        options:
     UIViewAnimationOptionBeginFromCurrentState |
     UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.frame = toRect;
                     } completion:^(BOOL finished) {
                         [super setHidden:hidden];
                     }];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private methods
////////////////////////////////////////////////////////////////////////

- (void)setupScrollView:(UIScrollView *)scrollView {
    if (scrollView == nil) {
        return;
    }
    // 将self.scrollView的状态保存起来
    _scrollViewSate.showsVerticalScrollIndicator = self.scrollView.showsVerticalScrollIndicator;
    _scrollViewSate.scrollEnabled = self.scrollView.scrollEnabled;
    self.scrollView.showsVerticalScrollIndicator = NO;
    
    [scrollView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:NSKeyValueObservingOptionNew context:OSScrollIndicatoScrollViewContext];
    [scrollView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) options:NSKeyValueObservingOptionNew context:OSScrollIndicatoScrollViewContext];
    
}

- (void)restoreScrollView:(UIScrollView *)scrollView {
    if (scrollView == nil) {
        return;
    }
    
    // 恢复scrollView的showsVerticalScrollIndicator
    scrollView.showsVerticalScrollIndicator = _scrollViewSate.showsVerticalScrollIndicator;
    scrollView.scrollEnabled = _scrollViewSate.scrollEnabled;
    
    @try {
        [scrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) context:OSScrollIndicatoScrollViewContext];
        [scrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:OSScrollIndicatoScrollViewContext];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    
    
}

- (void)updateStateForScrollView {
    
    CGRect frame = _scrollView.frame;
    CGSize contentSize = _scrollView.contentSize;
    if (contentSize.height / frame.size.height < _minimumContentHeightScale) {
        self.disabled = YES;
    }
    else {
        self.disabled = NO;
    }
    
    [self setHidden:self.disabled || self.userHidden animated:NO];
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Layout
////////////////////////////////////////////////////////////////////////

/// 布局self.frame
- (void)layoutInScrollView {
    
    CGRect scrollViewFrame = _scrollView.frame;
    UIEdgeInsets contentInset = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        contentInset = _scrollView.adjustedContentInset;
    } else {
        contentInset = _scrollView.contentInset;
    }
    CGPoint contentOffset = _scrollView.contentOffset;
    CGFloat halfWidth = OSScrollIndicatoViewDefaultWidth * 0.5;
    
    scrollViewFrame.size.height -= (contentInset.top + contentInset.bottom);
    CGFloat height = scrollViewFrame.size.height - (_contentEdgeInsets.top + _contentEdgeInsets.bottom);
    CGFloat offsetX = halfWidth - _contentEdgeInsets.right;
    self.fingerOffset = CGPointMake(MAX(offsetX, 0.0), self.fingerOffset.y);
    
    CGRect frame = CGRectZero;
    frame.size.width = OSScrollIndicatoViewDefaultWidth;
    frame.size.height = height;
    frame.origin.x = scrollViewFrame.size.width - (_contentEdgeInsets.right + halfWidth);
    frame.origin.x = MIN(frame.origin.x, scrollViewFrame.size.width - OSScrollIndicatoViewDefaultWidth);
    frame.origin.y = _contentEdgeInsets.top;
    frame.origin.y += contentOffset.y;
    frame.origin.y += contentInset.top;
    
    self.frame = frame;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    
    // 更新trackView的frame
    CGRect trackFrame = CGRectZero;
    trackFrame.size.width = self.trackWidth;
    trackFrame.size.height = frame.size.height;
    trackFrame.origin.x  = frame.size.width == self.trackWidth ? 0 : ceilf(((frame.size.width - self.trackWidth) * 0.5) + self.fingerOffset.x);
    self.trackView.frame = CGRectIntegral(trackFrame);
    
    /*
     更新indicatoView的宽度和中心点x值和trackView对其，
     注意:拖动时不要处理indicatoView的宽度以外的布局及frame，这里只需要更新下它的宽度
     */
    CGRect indicatoFrame = self.indicatoView.frame;
    indicatoFrame.size.width = self.indicatoWidth;
    self.indicatoView.frame = indicatoFrame;
    CGPoint indicatoCenter = self.indicatoView.center;
    indicatoCenter.x = self.trackView.center.x;
    self.indicatoView.center = indicatoCenter;
    
    if (self.isDragging || self.disabled) {
        return;
    }
    
    // 更新indicatoView的frame y值
    indicatoFrame = CGRectZero;
    indicatoFrame.size.width = self.indicatoWidth;
    indicatoFrame.size.height = [self heightOfIndicatoForContentSize];
    indicatoFrame.origin.x = ceilf(((frame.size.width - self.indicatoWidth) * 0.5f) + self.fingerOffset.x);
    
    // 计算indicatoViewy轴的偏移量
    UIEdgeInsets contentInset = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        contentInset = _scrollView.adjustedContentInset;
    } else {
        contentInset = _scrollView.contentInset;
    }
    CGPoint contentOffset     = _scrollView.contentOffset;
    CGSize contentSize        = _scrollView.contentSize;
    CGRect scrollViewFrame    = _scrollView.frame;
    
    CGFloat scrollableHeight = (contentSize.height + contentInset.top + contentInset.bottom) - scrollViewFrame.size.height;
    CGFloat scrollProgress = (contentOffset.y + contentInset.top) / scrollableHeight;
    indicatoFrame.origin.y = (frame.size.height - indicatoFrame.size.height) * scrollProgress;
    
    void (^tapticBlock)() = ^{
        // 到达边缘时触发taptic反馈
#ifdef __IPHONE_10_0
        [_feedbackGenerator impactOccurred];
#endif
        
    };
    if (contentOffset.y == -contentInset.top || contentOffset.y + scrollViewFrame.size.height == contentSize.height + contentInset.bottom) {
        tapticBlock();
    }
    // 如果滚动视图扩展超出其滚动的范围，缩小处理指示器
    if (contentOffset.y < -contentInset.top) {
        // 顶部
        indicatoFrame.size.height -= (-contentOffset.y - contentInset.top);
        indicatoFrame.size.height = MAX(indicatoFrame.size.height, (self.trackWidth * 2 + 2));
    }
    else if (contentOffset.y + scrollViewFrame.size.height > contentSize.height + contentInset.bottom) {
        // 底部
        CGFloat adjustedContentOffset = contentOffset.y + scrollViewFrame.size.height;
        CGFloat delta = adjustedContentOffset - (contentSize.height + contentInset.bottom);
        indicatoFrame.size.height -= delta;
        indicatoFrame.size.height = MAX(indicatoFrame.size.height, (self.trackWidth * 2 + 2));
        indicatoFrame.origin.y = frame.size.height - indicatoFrame.size.height;
    }
    
    indicatoFrame.origin.y = MAX(indicatoFrame.origin.y, 0.0f);
    indicatoFrame.origin.y = MIN(indicatoFrame.origin.y, (frame.size.height - indicatoFrame.size.height));
    
    self.indicatoView.frame = indicatoFrame;
    
    [self updateCustomViewFrame];
}

/// 根据indicatoView更新customView的frame
- (void)updateCustomViewFrame {
    CGRect customViewFrame = _customView.frame;
    CGRect indicatoFrame = self.indicatoView.frame;
    CGFloat margin = 0.0;
    customViewFrame.origin.x = -(customViewFrame.size.width + CGRectGetMaxX(indicatoFrame) + margin);
    customViewFrame.origin.y = indicatoFrame.origin.y + CGRectGetHeight(indicatoFrame)*0.5 - CGRectGetHeight(customViewFrame)*0.5;
    _customView.frame = customViewFrame;
}

- (CGFloat)heightOfIndicatoForContentSize {
    if (_scrollView == nil) {
        return _indicatoMinimiumHeight;
    }
    
    CGFloat heightRatio = _scrollView.frame.size.height / _scrollView.contentSize.height;
    CGFloat height = self.frame.size.height * heightRatio;
    return MAX(floorf(height), _indicatoMinimiumHeight); // floorf 向下取整 floorf(3.33) = 3;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Observe
////////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (context == OSScrollIndicatoScrollViewContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))] || [keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))]) {
            [self updateStateForScrollView];
            if (self.isHidden) {
                return;
            }
            [self layoutInScrollView];
            [self setNeedsLayout];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Events
////////////////////////////////////////////////////////////////////////

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.disabled) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenSelf) object:nil];
    void (^ block)() = ^{
        [_feedbackGenerator prepare];
        
        self.scrollView.scrollEnabled = NO;
        self.dragging = YES;
        
        CGPoint touchPoint = [touches.anyObject locationInView:self];
        
        CGRect indicatoFrame = self.indicatoView.frame;
        if (touchPoint.y > (indicatoFrame.origin.y - 20) &&
            touchPoint.y < indicatoFrame.origin.y + (indicatoFrame.size.height + 20)) {
            self.fingerOffset = CGPointMake(self.fingerOffset.x, (touchPoint.y - indicatoFrame.origin.y));
            return;
        }
        
        CGFloat halfHeight = indicatoFrame.size.height * 0.5;
        
        CGFloat destinationOffsetY = touchPoint.y - halfHeight;
        destinationOffsetY = MAX(0.0f, destinationOffsetY);
        destinationOffsetY = MIN(self.frame.size.height - halfHeight, destinationOffsetY);
        
        self.fingerOffset = CGPointMake(self.fingerOffset.x, touchPoint.y - destinationOffsetY);
        indicatoFrame.origin.y = destinationOffsetY;
        
        [UIView animateWithDuration:0.2
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:0.1
                            options:
         UIViewAnimationOptionBeginFromCurrentState |
         UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.indicatoView.frame = indicatoFrame;
                             [self updateCustomViewFrame];
                         } completion:NULL];
        
        [self setScrollViewContentOffsetYForIndicatoOffsetY:floorf(destinationOffsetY) animated:NO];
    };
    block();
//    [UIView performWithoutAnimation:block];
    
   
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    self.scrollView.scrollEnabled = YES;
    self.dragging = NO;
    
    [self performSelector:@selector(hiddenSelf) withObject:nil afterDelay:3.0];
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    self.scrollView.scrollEnabled = YES;
    self.dragging = NO;
    
    [self performSelector:@selector(hiddenSelf) withObject:nil afterDelay:3.0];
}

- (void)hiddenSelf {
    [self setHidden:YES animated:YES];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.disabled) {
        return;
    }
    
    // 获取手指移动的点
    CGPoint touchPoint = [[touches anyObject] locationInView:self];
    CGFloat delta = 0.0;
    CGRect indicatoRect = self.indicatoView.frame;
    CGRect trackRect = self.trackView.frame;
    CGFloat minY = 0.0;
    CGFloat maxY = trackRect.size.height - indicatoRect.size.height;
    
    CGFloat offsetY = self.fingerOffset.y;
    
    // 更新y值加上上一次的偏移量
    delta = indicatoRect.origin.y;
    indicatoRect.origin.y = touchPoint.y - offsetY;
    
    // 当按住指示器时，调整y轴的偏移量，防止超出边界
    if (indicatoRect.origin.y < minY) {
        offsetY += indicatoRect.origin.y;
        offsetY = MAX(minY, offsetY);
        indicatoRect.origin.y = minY;
    }
    else if (indicatoRect.origin.y > maxY) {
        CGFloat indicatoOverflow = CGRectGetMaxY(indicatoRect) - trackRect.size.height;
        offsetY += indicatoOverflow;
        offsetY = MIN(offsetY, indicatoRect.size.height);
        indicatoRect.origin.y = MIN(indicatoRect.origin.y, maxY);
    }
    self.fingerOffset = CGPointMake(self.fingerOffset.x, offsetY);
    _indicatoView.frame = indicatoRect;
    delta -= indicatoRect.origin.y;
    delta = fabs(delta); // 绝对值
    [self updateCustomViewFrame];
    // 到达边缘时触发taptic反馈
#ifdef __IPHONE_10_0
    // #define FLT_EPSILON                1.19209290E-07F 可用来作为float趋0最小的判断值
    if (delta > FLT_EPSILON && (CGRectGetMinY(indicatoRect) < FLT_EPSILON || CGRectGetMinY(indicatoRect) >= maxY - FLT_EPSILON)) {
        [_feedbackGenerator impactOccurred];
    }
#endif
    
    [self setScrollViewContentOffsetYForIndicatoOffsetY:indicatoRect.origin.y animated:NO];
}

- (void)setScrollViewContentOffsetYForIndicatoOffsetY:(CGFloat)indicatoOffsetY animated:(BOOL)animated {
    CGFloat heightRange = _trackView.frame.size.height - _indicatoView.frame.size.height;
    indicatoOffsetY = MAX(0.0f, indicatoOffsetY);
    indicatoOffsetY = MIN(heightRange, indicatoOffsetY);
    
    CGFloat positionRatio = indicatoOffsetY / heightRange;
    
    CGRect frame       = _scrollView.frame;
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        inset = _scrollView.adjustedContentInset;
    } else {
        inset = _scrollView.contentInset;
    }
    CGSize contentSize = _scrollView.contentSize;
    
    CGFloat totalScrollSize = (contentSize.height + inset.top + inset.bottom) - frame.size.height;
    CGFloat scrollOffset = totalScrollSize * positionRatio;
    scrollOffset -= inset.top;
    
    CGPoint contentOffset = _scrollView.contentOffset;
    contentOffset.y = scrollOffset;
    
    [self.scrollView setContentOffset:contentOffset animated:animated];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    UIView *touchView = [super hitTest:point withEvent:event];
    
    if (self.disabled || self.isDragging) {
        return touchView;
    }
//    if ([@[self, _trackView, _indicatoView] containsObject:touchView]) {
//        self.hidden = NO;
//    }
//    else {
//        self.hidden = YES;
//    }
    self.scrollView.scrollEnabled = touchView != self;
    return touchView;
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - set
////////////////////////////////////////////////////////////////////////

- (void)setTrackTintColor:(UIColor *)trackTintColor {
    _trackTintColor = trackTintColor;
    self.trackView.tintColor = trackTintColor;
}

- (UIColor *)trackTintColor {
    return self.trackView.tintColor;
}

- (void)setIndicatoTintColor:(UIColor *)indicatoTintColor {
    _indicatoTintColor = indicatoTintColor;
    self.indicatoView.tintColor = indicatoTintColor;
}

- (UIColor *)indicatoTintColor {
    return self.indicatoView.tintColor;
}



- (void)setDragging:(BOOL)dragging {
    if (_dragging == dragging) {
        return;
    }
    _dragging = dragging;
  
    void (^block)() = ^{
        
        CGRect trankViewFrame = self.trackView.frame;
        trankViewFrame.size.width = self.trackWidth;
        self.trackView.frame = trankViewFrame;
        CGRect indicatoWidthFrame = self.indicatoView.frame;
        indicatoWidthFrame.size.width = self.indicatoWidth;
        self.indicatoView.frame = indicatoWidthFrame;
        [self layoutIfNeeded];
    };
    
    //    if (dragging == NO) {
        [UIView animateWithDuration:0.2
                              delay:0.1
             usingSpringWithDamping:1.0
              initialSpringVelocity:0.1
                            options:
         UIViewAnimationOptionBeginFromCurrentState |
         UIViewAnimationOptionAllowUserInteraction
                         animations:block completion:NULL];
        
//    }
//    else {
//        block();
//    }
   
    
}


////////////////////////////////////////////////////////////////////////
#pragma mark - get
////////////////////////////////////////////////////////////////////////

- (UIImageView *)trackView {
    if (!_trackView) {
        UIImageView *trackView = [[UIImageView alloc] initWithImage:[[self class] verticalCapsuleImageWithWidth:self.trackWidth]];
        _trackView = trackView;
        trackView.accessibilityIdentifier = NSStringFromSelector(_cmd);
        [self addSubview:_trackView];
        trackView.layer.cornerRadius = 0.6;
        trackView.layer.masksToBounds = YES;
    }
    return _trackView;
}

- (UIImageView *)indicatoView {
    if (!_indicatoView) {
        UIImageView *indicatoView = [[UIImageView alloc] initWithImage:[[self class] verticalCapsuleImageWithWidth:self.indicatoWidth]];
        _indicatoView = indicatoView;
        indicatoView.accessibilityIdentifier = NSStringFromSelector(_cmd);
        [self addSubview:_indicatoView];
        indicatoView.layer.cornerRadius = 0.5;
        indicatoView.layer.masksToBounds = YES;
    }
    return _indicatoView;
}

- (CGFloat)trackWidth {
    if (self.indicatoStyle == OSScrollIndicatoStyleCustom) {
        if (self.isDragging) {
            return _trackWidth = OSScrollIndicatoViewDefaultWidth;
        }
    }
    return _trackWidth = 2.0;
}

- (CGFloat)indicatoWidth {
    if (self.indicatoStyle == OSScrollIndicatoStyleCustom) {
        if (self.isDragging) {
            return _indicatoWidth = OSScrollIndicatoViewDefaultWidth-6;
        }
    }
    return _indicatoWidth = 4.0;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

+ (UIImage *)verticalCapsuleImageWithWidth:(CGFloat)width {
    UIImage *image = nil;
    CGFloat radius = width * 0.5;
    CGRect frame = CGRectMake(0,
                              0,
                              width+1,
                              width+1);
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0.0);
    [[UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:radius] fill];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(radius, radius, radius, radius) resizingMode:UIImageResizingModeStretch];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    return image;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    
}

@end

@implementation UIScrollView (OSScrollIndicatoExtend)

- (void)setOs_scrollIndicatoView:(OSScrollIndicatoView *)os_scrollIndicatoView {
    objc_setAssociatedObject(self, @selector(os_scrollIndicatoView), os_scrollIndicatoView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (OSScrollIndicatoView *)os_scrollIndicatoView {
    
    OSScrollIndicatoView *scrollIndicatoView = objc_getAssociatedObject(self, _cmd);
    if (!scrollIndicatoView) {
        scrollIndicatoView = [[OSScrollIndicatoView alloc] initWithIndicatoStyle:OSScrollIndicatoStyleDefault];
        [self setOs_scrollIndicatoView:scrollIndicatoView];
        if ([self xy_canRemoveScrollIndicatoView]) {
            // mark: removeScrollIndicatoView 方法hock到removeFromSuperview中，但是removeScrollIndicatoView中的释放工作要在removeFromSuperview之后执行，不然会挂掉的，所有这里使用SwizzlingOptionAfter
            [[self class] exchangeImplementationWithSelector:@selector(removeFromSuperview) swizzledSelector:@selector(os_removeScrollIndicatoView)];
        }
        if ([self xy_canSetOs_separatorInset]) {
            [[self class] exchangeImplementationWithSelector:@selector(setSeparatorInset:) swizzledSelector:@selector(setOs_separatorInset:)];
            UITableView *tableView = (UITableView *)self;
            tableView.separatorInset = [tableView adjustedTableViewSeparatorInsetForInset:tableView.separatorInset];
        }

        
        if ([self xy_canObserverPrivateDelegateMethods]) {
            // 减速完成停止滚动，非减速
            SEL didEndDeceleratingSEL = NSSelectorFromString(@"_scrollViewDidEndDeceleratingForDelegate");
            if ([self respondsToSelector:didEndDeceleratingSEL]) {
                [[self class] exchangeImplementationWithSelector:didEndDeceleratingSEL swizzledSelector:@selector(os_scrollViewDidEndDeceleratingForDelegate)];
            }
            // 拖拽完成停止滚动，非减速
            SEL didEndDraggingSEL = NSSelectorFromString(@"_scrollViewDidEndDraggingForDelegateWithDeceleration:");
            if ([self respondsToSelector:didEndDraggingSEL]) {
                [[self class] exchangeImplementationWithSelector:didEndDraggingSEL swizzledSelector:@selector(os_scrollViewDidEndDraggingForDelegateWithDeceleration:)];
            }

            // 即将开始拖拽，显示
            SEL willBeginDraggingSEL = NSSelectorFromString(@"_scrollViewWillBeginDragging");
            if ([self respondsToSelector:willBeginDraggingSEL]) {
                [[self class] exchangeImplementationWithSelector:willBeginDraggingSEL swizzledSelector:@selector(os_scrollViewWillBeginDragging)];
            }

        }
    }
    return scrollIndicatoView;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - 
////////////////////////////////////////////////////////////////////////

- (void)os_removeScrollIndicatoView {
    [self os_removeScrollIndicatoView];
    [self.os_scrollIndicatoView removeFromSuperview];
    self.os_scrollIndicatoView = nil;
}

- (void)setOs_scrollIndicatoStyle:(OSScrollIndicatoStyle)os_scrollIndicatoStyle {
    objc_setAssociatedObject(self, @selector(os_scrollIndicatoStyle), @(os_scrollIndicatoStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.os_scrollIndicatoView.indicatoStyle = os_scrollIndicatoStyle;
    self.os_scrollIndicatoView.scrollView = self;

}

///
/// 执行scrollViewWillBeginDragging: 之前执行的方法，显示OSScrollViewScrollIndicato
///
- (void)os_scrollViewWillBeginDragging {
    [self os_scrollViewWillBeginDragging];
     OSScrollIndicatoView *scrollIndicatoView = objc_getAssociatedObject(self, @selector(os_scrollIndicatoView));
    [NSObject cancelPreviousPerformRequestsWithTarget:scrollIndicatoView selector:@selector(hiddenSelf) object:nil];
}

///
/// scrollView减速完成停止滚动时执行的方法 执行scrollViewDidEndDecelerating: 方法之前执行的方法，隐藏
///
- (void)os_scrollViewDidEndDeceleratingForDelegate {
    [self os_scrollViewDidEndDeceleratingForDelegate];
    OSScrollIndicatoView *scrollIndicatoView = objc_getAssociatedObject(self, @selector(os_scrollIndicatoView));
    if (scrollIndicatoView.dragging) {
        return;
    }
    
    [scrollIndicatoView performSelector:@selector(hiddenSelf) withObject:nil afterDelay:3.0];

}

///
/// scrollView滚动完成停止滚动时执行的方法 执行scrollViewDidEndDragging: willDecelerate: 方法之前执行的方法，隐藏
///
- (void)os_scrollViewDidEndDraggingForDelegateWithDeceleration:(BOOL)isDecelerating {
    [self os_scrollViewDidEndDraggingForDelegateWithDeceleration:isDecelerating];
    
    if (isDecelerating == NO) {
        OSScrollIndicatoView *scrollIndicatoView = objc_getAssociatedObject(self, @selector(os_scrollIndicatoView));
        if (scrollIndicatoView.dragging) {
            return;
        }
        [scrollIndicatoView performSelector:@selector(hiddenSelf) withObject:nil afterDelay:3.0];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (OSScrollIndicatoStyle)os_scrollIndicatoStyle {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}


- (UIEdgeInsets)adjustedTableViewSeparatorInsetForInset:(UIEdgeInsets)inset {
    inset.right = self.os_scrollIndicatoView.contentEdgeInsets.right * 2.0;
    return inset;
}

- (UIEdgeInsets)adjustedTableViewCellLayoutMarginsForMargins:(UIEdgeInsets)layoutMargins manualOffset:(CGFloat)offset {
    layoutMargins.right = self.os_scrollIndicatoView.contentEdgeInsets.right * 2.0 + 15.0;
    layoutMargins.right += offset;
    return layoutMargins;
}

- (Class)xy_baseClassToSwizzling {
    if ([self isKindOfClass:[UITableView class]]) {
        return [UITableView class];
    }
    if ([self isKindOfClass:[UIScrollView class]]) {
        return [UIScrollView class];
    }
    return nil;
}

- (void)setOs_separatorInset:(UIEdgeInsets)separatorInset {
    [self setOs_separatorInset:separatorInset];
    if (![self xy_canSetOs_separatorInset]) {
        return;
    }
    UIEdgeInsets separatorInset_ = ((UITableView *)self).separatorInset;
    [self adjustedTableViewSeparatorInsetForInset:separatorInset_];
}

- (BOOL)xy_canSetOs_separatorInset {
    if ([self isKindOfClass:[UITableView class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)xy_canRemoveScrollIndicatoView {
    if ([self respondsToSelector:@selector(os_removeScrollIndicatoView)]) {
        return YES;
    }
    return NO;
}

- (BOOL)xy_canObserverPrivateDelegateMethods {
    if ([self isKindOfClass:[UIScrollView class]] ||
        [self isKindOfClass:[UITableView class]] ||
        [self isKindOfClass:[UICollectionView class]]) {
        return YES;
    }
    return NO;
}

@end

@implementation NSObject (XYSwizzlingExtension)

#pragma mark - Swizzling
+ (void)exchangeImplementationWithSelector:(SEL)originSelector swizzledSelector:(SEL)swizzledSelector {
    Class class = [self class];
    Method originMethod = class_getInstanceMethod(class, originSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class,
                                        originSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originMethod),
                            method_getTypeEncoding(originMethod));
    } else {
        method_exchangeImplementations(originMethod, swizzledMethod);
    }
}


@end
