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
@property (nonatomic, strong) NSString * hentaiKey;
@property (nonatomic, assign) NSInteger page;
#warning removable vars
@property (nonatomic, strong) NSMutableArray * hentaiImageURLs;
@property (nonatomic, strong) NSMutableDictionary * hentaiResults;
@end

@implementation APhotoPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.page = 0;
    self.dataSource = self;
}
- (void)viewWillAppear:(BOOL)animated {
    self.hentaiResults = [NSMutableDictionary new];
    NSString * hentaiURLString = self.galleryInfo[@"url"];
    NSString * galleryImageCount = self.galleryInfo[@"filecount"];
    
    [HentaiParser requestImagesAtURL:hentaiURLString atIndex:0 completion: ^(HentaiParserStatus status, NSArray *images) {
        //Return images url array
        if (status == HentaiParserStatusSuccess) {
            self.hentaiImageURLs = [images mutableCopy];
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
    APhotoViewController *pageZero = [APhotoViewController photoViewControllerForImage:[UIImage imageNamed:@"aaa"]];
    if (pageZero != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{

        [self setViewControllers:@[pageZero]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:YES
                      completion:NULL];
        });
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
    newOperation.hentaiKey = self.hentaiKey;
    newOperation.delegate = self;
//    [self.hentaiQueue addOperation:newOperation];
    [newOperation start];
}
- (NSString *)hentaiKey {
    if(_hentaiKey == nil){
        NSArray *splitStrings = [self.galleryInfo[@"url"] componentsSeparatedByString:@"/"];
        NSUInteger splitCount = [splitStrings count];
        NSString *checkHentaiKey = [NSString stringWithFormat:@"%@-%@-%@", splitStrings[splitCount - 3], splitStrings[splitCount - 2], self.galleryInfo[@"title"]];
        _hentaiKey = [checkHentaiKey stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    }
    return _hentaiKey;
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
    NSLog(@"%@",urlString);
//    if (isSuccess) {
    self.hentaiResults[[urlString lastPathComponent]] = @(height);
//        NSInteger availableCount = [self availableCount];
//        if (availableCount > self.realDisplayCount) {
//            if (availableCount >= 1) {
//                [SVProgressHUD dismiss];
//            }
//            self.realDisplayCount = availableCount;
//            [self.hentaiTableView reloadData];
//        }
//    }
//    else {
//        NSNumber *retryCount = self.retryMap[urlString];
//        if (retryCount) {
//            retryCount = @([retryCount integerValue] + 1);
//        }
//        else {
//            retryCount = @(1);
//        }
//        self.retryMap[urlString] = retryCount;
//        
//        if ([retryCount integerValue] <= 3) {
//            [self createNewOperation:urlString];
//        }
//        else {
//            self.failCount++;
//            self.maxHentaiCount = [NSString stringWithFormat:@"%ld", [self.maxHentaiCount integerValue] - 1];
//            [self.hentaiImageURLs removeObject:urlString];
//        }
//    }
}


#pragma mark - UIPageViewControllerDataSource
- (UIImage *)imageForIndex:(NSInteger)index
{
    NSLog(@"loadIndex:%ld",(long)index);
    if(self.hentaiImageURLs!=nil) {
        FMStream *hentaiFilesManager = [[FilesManager documentFolder] fcd:self.hentaiKey];
        NSString *eachImageString = self.hentaiImageURLs[index];
        if (self.hentaiResults[[eachImageString lastPathComponent]]) {
            UIImage *image = [UIImage imageWithData:[hentaiFilesManager read:[eachImageString lastPathComponent]]];
            return image;
        }
    }
    return nil;
}
- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerBeforeViewController:(APhotoViewController *)vc
{
    if (vc.pageIndex == 0) {
        return nil;
    }
    self.page --;
    UIImage * img = [self imageForIndex:self.page];
    if(img != nil){
        return [APhotoViewController photoViewControllerForImage:img];
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerAfterViewController:(APhotoViewController *)vc
{
    self.page++;
    UIImage * img = [self imageForIndex:self.page];
    if(img != nil){
        return [APhotoViewController photoViewControllerForImage:img];
    }
    return nil;
}
@end
