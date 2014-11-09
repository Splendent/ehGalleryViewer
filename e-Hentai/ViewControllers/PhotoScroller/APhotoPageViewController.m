//
//  APhotoPageViewController.m
//  e-Hentai
//
//  Created by  Splenden on 2014/11/9.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import "APhotoPageViewController.h"
#import "APhotoViewController.h"

@interface APhotoPageViewController ()

@end

@implementation APhotoPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerBeforeViewController:(APhotoViewController *)vc
{
    NSUInteger index = vc.pageIndex;
    return [APhotoViewController photoViewControllerForPageIndex:(index - 1)];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerAfterViewController:(APhotoViewController *)vc
{
    NSUInteger index = vc.pageIndex;
    return [APhotoViewController photoViewControllerForPageIndex:(index + 1)];
}
@end
