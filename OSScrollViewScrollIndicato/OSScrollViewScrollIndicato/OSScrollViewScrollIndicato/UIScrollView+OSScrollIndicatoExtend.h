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




@interface UIScrollView (OSScrollIndicatoExtend)

@property (nonatomic, assign) OSScrollIndicatoStyle os_scrollIndicatoStyle;
@property (nonatomic, assign) BOOL hiddenIndicato;

- (void)removeScrollIndicatoView;

- (UIEdgeInsets)adjustedTableViewSeparatorInsetForInset:(UIEdgeInsets)inset;
- (UIEdgeInsets)adjustedTableViewCellLayoutMarginsForMargins:(UIEdgeInsets)layoutMargins manualOffset:(CGFloat)offset;

@end
