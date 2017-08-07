//
//  UIScrollView+OSScrollIndicatoExtend.h
//  OSScrollViewScrollIndicato
//
//  Created by Ossey on 05/08/2017.
//  Copyright © 2017 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OSScrollIndicatoStyle) {
    OSScrollIndicatoStyleDefault,
    OSScrollIndicatoStyleDark,
    OSScrollIndicatoStyleCustom
};

@interface OSScrollIndicatoView : UIView

@property (nonatomic, weak, readonly) UIScrollView *scrollView;
/** 指示器顶部和底部距离父控件的边距值，默认上下为20 */
@property (nonatomic, assign) UIEdgeInsets indicatoVerticalInstt;
@property (nonatomic, assign) CGFloat edgeInset;
/** 指示器所在轨道的主题颜色 */
@property (nonatomic, strong) UIColor *trackTintColor;
/** 指示器所在轨道的宽度 默认为4.0*/
@property (nonatomic, assign) CGFloat trackWidth;
/** 指示器的主题颜色*/
@property (nonatomic, strong) UIColor *indicatoTintColor;
/** 指示器的宽度 */
@property (nonatomic, assign) CGFloat indicatoWidth;
/** 指示器最小高度，默认为64.0 */
@property (nonatomic, assign) CGFloat indicatoMinimiumHeight;
/** 用户是否正在拖动指示器 */
@property (nonatomic, assign, readonly) BOOL dragging;
/** 指示器显示之前，指示器对比的缩放值 */
@property (nonatomic, assign) CGFloat minimumContentHeightScale;
/** 指示器样式 */
@property (nonatomic, assign) OSScrollIndicatoStyle indicatoStyle;


- (instancetype)initWithIndicatoStyle:(OSScrollIndicatoStyle)indicatoStyle;

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated;

@end


@interface UIScrollView (OSScrollIndicatoExtend)

@property (nonatomic, assign) OSScrollIndicatoStyle os_scrollIndicatoStyle;

- (void)removeScrollIndicatoView;

- (UIEdgeInsets)adjustedTableViewSeparatorInsetForInset:(UIEdgeInsets)inset;
- (UIEdgeInsets)adjustedTableViewCellLayoutMarginsForMargins:(UIEdgeInsets)layoutMargins manualOffset:(CGFloat)offset;

@end
