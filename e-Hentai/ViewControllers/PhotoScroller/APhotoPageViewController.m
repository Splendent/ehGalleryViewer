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
- (void)viewWillAppear:(BOOL)animated {
    NSString * hentaiURLString = self.galleryInfo[@"url"];
    NSString * galleryImageCount = self.galleryInfo[@"filecount"];
    
    [HentaiParser requestImagesAtURL:hentaiURLString atIndex:0 completion: ^(HentaiParserStatus status, NSArray *images) {
        //Return images url array
        if (status == HentaiParserStatusSuccess) {
            for (NSString *imageURL in images) {
                [self createNewOperation:imageURL];
            }
        }
        else if (status == HentaiParserStatusFail) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"讀取失敗囉" message:nil delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil];
            [alert show];
            [SVProgressHUD dismiss];
        }
        else if ([images count] == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"讀取失敗囉" message:nil delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil];
            [alert show];
            [SVProgressHUD dismiss];
        }
    }];
    
    // kick things off by making the first page
    APhotoViewController *pageZero = [APhotoViewController photoViewControllerForPageIndex:0];
    if (pageZero != nil)
    {
        [self setViewControllers:@[pageZero]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:YES
                      completion:NULL];
    }
    [super viewWillAppear:animated];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)createNewOperation:(NSString *)urlString {
    HentaiDownloadImageOperation *newOperation = [HentaiDownloadImageOperation new];
    newOperation.downloadURLString = urlString;
    newOperation.isCacheOperation = NO;
//    newOperation.hentaiKey = self.hentaiKey;
    newOperation.delegate = self;
//    [self.hentaiQueue addOperation:newOperation];
    [newOperation start];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - HentaiDownloadImageOperationDelegate
- (void)downloadResult:(NSString *)urlString heightOfSize:(CGFloat)height isSuccess:(BOOL)isSuccess {
    
}


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
