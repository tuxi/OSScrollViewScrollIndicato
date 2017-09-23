//
//  UIScrollView+OSScrollIndicatoExtend.h
//  OSScrollViewScrollIndicato
//
//  Created by Ossey on 05/08/2017.
//  Copyright © 2017 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OSScrollIndicatoStyle) {
    OSScrollIndicatoStyleNone,
    OSScrollIndicatoStyleDefault,
    OSScrollIndicatoStyleDark,
    OSScrollIndicatoStyleCustom
};


@interface OSScrollIndicatoView : UIView

@property (nonatomic, weak, readonly) UIScrollView *scrollView;
/** 指示器和trackView顶部和底部距离父控件的边距值，默认顶部为2.0，底部为2.0，右侧为5.0, 左侧暂时无效 */
@property (nonatomic, assign) UIEdgeInsets contentEdgeInsets;
/** 指示器所在轨道的主题颜色 */
@property (nonatomic, strong) UIColor *trackTintColor;
/** 指示器所在轨道的宽度 默认为2.0, 当OSScrollIndicatoStyleCustom时，宽度与父控件相同*/
@property (nonatomic, assign) CGFloat trackWidth;
/** 指示器的主题颜色*/
@property (nonatomic, strong) UIColor *indicatoTintColor;
/** 指示器的宽度，默认为4.0，当OSScrollIndicatoStyleCustom时，宽度比父控件小6 */
@property (nonatomic, assign) CGFloat indicatoWidth;
/** 指示器最小高度，默认为30.0 */
@property (nonatomic, assign) CGFloat indicatoMinHeight;
/** 用户是否正在拖动指示器 */
@property (nonatomic, assign, readonly, getter=isDragging) BOOL dragging;
/** 指示器显示之前，指示器对比的缩放值, 当contentSize的高度除以scrollView的高度比例值 > minContentHeightScale才显示指示器 */
@property (nonatomic, assign) CGFloat minContentHeightScale;
/** 指示器样式 */
@property (nonatomic, assign) OSScrollIndicatoStyle indicatoStyle;
@property (nonatomic, strong) UIView *customView;
/** customView所在tableView的indexPath, 只有当前是tableView或者collectionView时才有效 */
@property (nonatomic, strong) NSIndexPath *customViewInScrollViewIndexPath;
@property (nonatomic, copy) void (^ customViewIndexPathChangeBlock)(NSIndexPath *indexPath);
/** customView 顶部 在 scrollView中indexPath， 少于这个indexPath则从此开始，控制customView起始的位置，default is (0,0) */
@property (nonatomic, strong) NSIndexPath *customViewInScrollViewMinIndexPath;
/** customView 底部 在 scrollView中indexPath， 大于这个indexPath则从此结束，控制customView结束的位置，default is scrollView 最大的 contentSize 计算的indexPath */
@property (nonatomic, strong) NSIndexPath *customViewInScrollViewMaxIndexPath;

- (instancetype)initWithIndicatoStyle:(OSScrollIndicatoStyle)indicatoStyle;

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated;

@end

@interface UIScrollView (OSScrollIndicatoExtend)

@property (nonatomic, assign) OSScrollIndicatoStyle os_scrollIndicatoStyle;
@property (nonatomic, readonly) OSScrollIndicatoView *os_scrollIndicatoView;

- (void)os_removeScrollIndicatoView;

- (UIEdgeInsets)adjustedTableViewSeparatorInsetForInset:(UIEdgeInsets)inset;
- (UIEdgeInsets)adjustedTableViewCellLayoutMarginsForMargins:(UIEdgeInsets)layoutMargins manualOffset:(CGFloat)offset;

@end
