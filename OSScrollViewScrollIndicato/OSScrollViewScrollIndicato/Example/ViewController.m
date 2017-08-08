//
//  ViewController.m
//  OSScrollViewScrollIndicato
//
//  Created by Ossey on 05/08/2017.
//  Copyright © 2017 Ossey. All rights reserved.
//

#import "ViewController.h"
#import "UIScrollView+OSScrollIndicatoExtend.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.tableView.os_scrollIndicatoStyle = OSScrollIndicatoStyleCustom;

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %ld", indexPath.row+1];
    cell.layoutMargins = [tableView adjustedTableViewCellLayoutMarginsForMargins:cell.layoutMargins manualOffset:0.0f];
    
    return cell;
}


//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    
//    // 测试添加和移除时，是否影响scrollView是否可正常显示和使用
//    if (scrollView.contentOffset.y > 1000) {
//        [scrollView removeScrollIndicatoView];
//    }
//    else {
//        self.tableView.os_scrollIndicatoStyle = OSScrollIndicatoStyleCustom;
//    }
//}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 减速stop
    NSLog(@"stop %s", __func__);
    // UIScrollView在执行当前代理方法前执行了_scrollViewDidEndDeceleratingForDelegate方法，为私有方法，无参数
    SEL didEndDecelerating = NSSelectorFromString(@"_scrollViewDidEndDeceleratingForDelegate");
    if ([scrollView respondsToSelector:didEndDecelerating]) {
        NSLog(@"减速stop");
    }
    // #1	0x000000018d703198 in -[UIScrollView(UIScrollViewInternal) _scrollViewDidEndDeceleratingForDelegate] ()

}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    if (decelerate == NO) {
        // 拖拽 非减速stop
        NSLog(@"stop %s", __func__);
// #1	0x000000018d703100 in -[UIScrollView(UIScrollViewInternal) _scrollViewDidEndDraggingForDelegateWithDeceleration:] ()
        // UIScrollView在执行当前代理方法前执行了_scrollViewDidEndDraggingForDelegateWithDeceleration:方法，为私有方法，有参数
        SEL didEndDragging = NSSelectorFromString(@"_scrollViewDidEndDraggingForDelegateWithDeceleration:");
        if ([scrollView respondsToSelector:didEndDragging]) {
            NSLog(@"非减速stop");
        }
    }
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    [self.tableView removeFromSuperview];
}

@end
