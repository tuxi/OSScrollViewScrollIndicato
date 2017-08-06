//
//  UIScrollView+OSScrollIndicatoExtend.m
//  OSScrollViewScrollIndicato
//
//  Created by Ossey on 05/08/2017.
//  Copyright © 2017 Ossey. All rights reserved.
//

#import "UIScrollView+OSScrollIndicatoExtend.h"
#import <objc/runtime.h>

struct OSScrollIndicatoScrollViewState {
    BOOL showsVerticalScrollIndicator;
};

static void * OSScrollIndicatoScrollViewContext = &OSScrollIndicatoScrollViewContext;
static CGFloat OSScrollIndicatoViewWidth = 20.0;

typedef struct OSScrollIndicatoScrollViewState OSScrollIndicatoScrollViewState;

@interface UIScrollView ()

@property (nonatomic, strong) OSScrollIndicatoView *scrollIndicatoView;

@end


@interface OSScrollIndicatoView ()

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL userHidden;
@property (nonatomic, strong) UIImageView *trackView;
@property (nonatomic, strong) UIImageView *indicatoView;
@property (nonatomic, assign) BOOL dragging;
/// 手指中心的偏移量
@property (nonatomic, assign) CGFloat offsetY;
@property (nonatomic, assign) CGFloat offsetX;
@property (nonatomic, assign) BOOL disabled;
#ifdef __IPHONE_10_0
@property (nonatomic, strong) UIImpactFeedbackGenerator *feedbackGenerator;
#endif

@end

@implementation OSScrollIndicatoView
{
    OSScrollIndicatoScrollViewState _scrollViewSatate;
}

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
    _trackWidth = 2.0;
    _indicatoWidth = 4.0;
    _edgeInset = 7.5;
    _indicatoMinimiumHeight = 64.0;
    _minimumContentHeightScale = 5.0;
    _indicatoVerticalInstt = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
#ifdef __IPHONE_10_0
    _feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
#endif
}

- (void)__setupUI {
    if (self.trackView || self.indicatoView) {
        return;
    }
    
    self.backgroundColor = [UIColor clearColor];
    
    self.trackView = [[UIImageView alloc] initWithImage:[[self class] verticalCapsuleImageWithWidth:self.trackWidth]];
    [self addSubview:self.trackView];
    self.indicatoView = [[UIImageView alloc] initWithImage:[[self class] verticalCapsuleImageWithWidth:self.indicatoWidth]];
    [self addSubview:self.indicatoView];
    
    [self setIndicatoStyle:self.indicatoStyle];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    [self __setupUI];
}

- (void)setIndicatoStyle:(OSScrollIndicatoStyle)indicatoStyle {
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
}

- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView == scrollView) {
        return;
    }
    
    [self restoreScrollView:_scrollView];
    
    _scrollView = scrollView;
    
    [self configScrollView:_scrollView];
    
    [scrollView addSubview:self];
    
    scrollView.scrollIndicatoView = self;
    
    [self layoutInScrollView];
}

- (void)removeFromSuperview {
    
    [self restoreScrollView:_scrollView];
    [super removeFromSuperview];
    _scrollView.scrollIndicatoView = nil;
    _scrollView = nil;
    
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
    
    if (!animated) {
        super.hidden = hidden;
        return;
    }
    
    if (self.isHidden && hidden == NO) {
        super.hidden = NO;
        [self layoutInScrollView];
        [self setNeedsDisplay];
    }
    
    CGRect fromRect = self.frame;
    CGRect toRect = self.frame;
    
    CGFloat widestElement = MAX(_trackWidth, _indicatoWidth);
    CGFloat indicatoOffset = fromRect.origin.x + _edgeInset + widestElement * 2.0;
    
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


- (void)configScrollView:(UIScrollView *)scrollView {
    if (scrollView == nil) {
        return;
    }
    
    // 将self.scrollView的状态保存起来
    _scrollViewSatate.showsVerticalScrollIndicator = self.scrollView.showsVerticalScrollIndicator;
    self.scrollView.showsVerticalScrollIndicator = NO;
    
    [scrollView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:NSKeyValueObservingOptionNew context:OSScrollIndicatoScrollViewContext];
    [scrollView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) options:NSKeyValueObservingOptionNew context:OSScrollIndicatoScrollViewContext];
    
}

- (void)restoreScrollView:(UIScrollView *)scrollView {
    if (scrollView == nil) {
        return;
    }
    
    scrollView.showsVerticalScrollIndicator = _scrollView.showsVerticalScrollIndicator;
    
    [scrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))];
    [scrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize))];
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

- (void)layoutInScrollView {
    
    CGRect scrollViewFrame = _scrollView.frame;
    UIEdgeInsets contentInset = _scrollView.contentInset;
    CGPoint contentOffset = _scrollView.contentOffset;
    CGFloat halfWidth = OSScrollIndicatoViewWidth * 0.5;
    
    scrollViewFrame.size.height -= (contentInset.top + contentInset.bottom);
    CGFloat height = scrollViewFrame.size.height - (_indicatoVerticalInstt.top + _indicatoVerticalInstt.bottom);
    CGFloat offsetX = halfWidth - _edgeInset;
    self.offsetX = MAX(offsetX, 0.0);
    
    CGRect frame = CGRectZero;
    frame.size.width = OSScrollIndicatoViewWidth;
    frame.size.height = height;
    frame.origin.x = scrollViewFrame.size.width - (_edgeInset + halfWidth);
    frame.origin.x = MIN(frame.origin.x, scrollViewFrame.size.width - OSScrollIndicatoViewWidth);
    frame.origin.y = _indicatoVerticalInstt.top;
    frame.origin.y += contentOffset.y;
    frame.origin.y += contentInset.top;
    
    self.frame = frame;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    
    CGRect trackFrame = CGRectZero;
    trackFrame.size.width = _trackWidth;
    trackFrame.size.height = frame.size.height;
    trackFrame.origin.x  = ceilf(((frame.size.width - _trackWidth) * 0.5) + _offsetX);
    self.trackView.frame = CGRectIntegral(trackFrame);
    
    // Don't handle automatic layout when dragging; we'll do that manually elsewhere
    if (self.dragging || self.disabled) {
        return;
    }
    
    // The frame of the handle
    CGRect indicatoFrame = CGRectZero;
    indicatoFrame.size.width = _indicatoWidth;
    indicatoFrame.size.height = [self heightOfIndicatoForContentSize];
    indicatoFrame.origin.x = ceilf(((frame.size.width - _indicatoWidth) * 0.5f) + _offsetX);
    
    // Work out the y offset of the handle
    UIEdgeInsets contentInset = _scrollView.contentInset;
    CGPoint contentOffset     = _scrollView.contentOffset;
    CGSize contentSize        = _scrollView.contentSize;
    CGRect scrollViewFrame    = _scrollView.frame;
    
    CGFloat scrollableHeight = (contentSize.height + contentInset.top + contentInset.bottom) - scrollViewFrame.size.height;
    CGFloat scrollProgress = (contentOffset.y + contentInset.top) / scrollableHeight;
    indicatoFrame.origin.y = (frame.size.height - indicatoFrame.size.height) * scrollProgress;
    
    // If the scroll view expanded beyond its scrollable range, shrink the handle to match the rubber band effect
    if (contentOffset.y < -contentInset.top) {
        // 顶部
        indicatoFrame.size.height -= (-contentOffset.y - contentInset.top);
        indicatoFrame.size.height = MAX(indicatoFrame.size.height, (_trackWidth * 2 + 2));
    }
    else if (contentOffset.y + scrollViewFrame.size.height > contentSize.height + contentInset.bottom) {
        // 底部
        CGFloat adjustedContentOffset = contentOffset.y + scrollViewFrame.size.height;
        CGFloat delta = adjustedContentOffset - (contentSize.height + contentInset.bottom);
        indicatoFrame.size.height -= delta;
        indicatoFrame.size.height = MAX(indicatoFrame.size.height, (_trackWidth * 2 + 2));
        indicatoFrame.origin.y = frame.size.height - indicatoFrame.size.height;
    }
    
    indicatoFrame.origin.y = MAX(indicatoFrame.origin.y, 0.0f);
    indicatoFrame.origin.y = MIN(indicatoFrame.origin.y, (frame.size.height - indicatoFrame.size.height));
    
    self.indicatoView.frame = indicatoFrame;
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
#pragma mark -
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
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Events
////////////////////////////////////////////////////////////////////////

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.disabled) {
        return;
    }
    
    [_feedbackGenerator prepare];
    
    self.scrollView.scrollEnabled = NO;
    self.dragging = YES;
    
    CGPoint touchPoint = [touches.anyObject locationInView:self];
    
    CGRect indicatoFrame = self.indicatoView.frame;
    if (touchPoint.y > (indicatoFrame.origin.y - 20) &&
        touchPoint.y < indicatoFrame.origin.y + (indicatoFrame.size.height + 20)) {
        self.offsetY = (touchPoint.y - indicatoFrame.origin.y);
        return;
    }
    
    CGFloat halfHeight = indicatoFrame.size.height * 0.5;
    
    CGFloat destinationOffsetY = touchPoint.y - halfHeight;
    destinationOffsetY = MAX(0.0f, destinationOffsetY);
    destinationOffsetY = MIN(self.frame.size.height - halfHeight, destinationOffsetY);
    
    self.offsetY = touchPoint.y - destinationOffsetY;
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
    } completion:^(BOOL finished) {
        
    }];
    
    [self setScrollViewContentOffsetYForIndicatoOffsetY:floorf(destinationOffsetY) animated:NO];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    self.scrollView.scrollEnabled = YES;
    self.dragging = NO;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    self.scrollView.scrollEnabled = YES;
    self.dragging = NO;
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
    
    // 更新y值加上上一次的偏移量
    delta = indicatoRect.origin.y;
    indicatoRect.origin.y = touchPoint.y - _offsetY;
    
    // 当按住指示器时，调整y轴的偏移量，防止超出边界
    if (indicatoRect.origin.y < minY) {
        _offsetY += indicatoRect.origin.y;
        _offsetY = MAX(minY, _offsetY);
        indicatoRect.origin.y = minY;
    }
    else if (indicatoRect.origin.y > maxY) {
        CGFloat indicatoOverflow = CGRectGetMaxY(indicatoRect) - trackRect.size.height;
        _offsetY += indicatoOverflow;
        _offsetY = MIN(_offsetY, indicatoRect.size.height);
        indicatoRect.origin.y = MIN(indicatoRect.origin.y, maxY);
    }
    
    _indicatoView.frame = indicatoRect;
    delta -= indicatoRect.origin.y;
    delta = fabs(delta); // 绝对值
    
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
    UIEdgeInsets inset = _scrollView.contentInset;
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
    
    if (self.disabled || self.dragging) {
        return touchView;
    }
    
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

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)dealloc {
    [self restoreScrollView:_scrollView];
}

@end

@implementation UIScrollView (OSScrollIndicatoExtend)

- (void)setScrollIndicatoView:(OSScrollIndicatoView *)scrollIndicatoView {
    objc_setAssociatedObject(self, @selector(scrollIndicatoView), scrollIndicatoView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (OSScrollIndicatoView *)scrollIndicatoView {
    
     OSScrollIndicatoView *scrollIndicatoView = objc_getAssociatedObject(self, _cmd);
    if (!scrollIndicatoView) {
        scrollIndicatoView = [[OSScrollIndicatoView alloc] initWithIndicatoStyle:OSScrollIndicatoStyleDefault];
        [self setScrollIndicatoView:scrollIndicatoView];
    }
    return scrollIndicatoView;
}

- (void)removeScrollIndicatoView {
    [self.scrollIndicatoView removeFromSuperview];
}

- (void)setOs_scrollIndicatoStyle:(OSScrollIndicatoStyle)os_scrollIndicatoStyle {
    objc_setAssociatedObject(self, @selector(os_scrollIndicatoStyle), @(os_scrollIndicatoStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.scrollIndicatoView.indicatoStyle = os_scrollIndicatoStyle;
    self.scrollIndicatoView.scrollView = self;

}

- (OSScrollIndicatoStyle)os_scrollIndicatoStyle {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}


- (UIEdgeInsets)adjustedTableViewSeparatorInsetForInset:(UIEdgeInsets)inset {
    inset.right = self.scrollIndicatoView.edgeInset * 2.0;
    return inset;
}

- (UIEdgeInsets)adjustedTableViewCellLayoutMarginsForMargins:(UIEdgeInsets)layoutMargins manualOffset:(CGFloat)offset {
    layoutMargins.right = self.scrollIndicatoView.edgeInset * 2.0 + 15.0;
    layoutMargins.right += offset;
    return layoutMargins;
}
@end
