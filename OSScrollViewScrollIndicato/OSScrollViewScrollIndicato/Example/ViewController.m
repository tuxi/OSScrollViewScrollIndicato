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
    self.tableView.separatorInset = UIEdgeInsetsMake(64.0, 0, 0, 0);
    
    // Mark: 当设置此属性为UIScrollViewContentInsetAdjustmentScrollableAxes时，手指放在滚动条上滚动时会出现乱窜的问题，待解决
//    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentScrollableAxes;
    
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
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    

}



- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate == NO) {
        
    }
}


- (void)dealloc {
    NSLog(@"%s", __func__);
    
}

@end
