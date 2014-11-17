//
//  APhotoPageViewController.m
//  e-Hentai
//
//  Created by  Splenden on 2014/11/9.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import "APhotoPageViewController.h"
#import "APhotoViewController.h"
#import "AFNetworking.h"

@interface APhotoPageViewController ()
@property (nonatomic, strong) NSString * hentaiKey;
@property (nonatomic, strong) NSString * galleryURLString;
@property (nonatomic, strong) NSMutableArray * galleryImageURLs;
@property (nonatomic, assign) NSString * galleryImageCount;
@property (nonatomic, strong) NSOperationQueue * galleryDownloadQueue;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) NSInteger downloadedPageCount;

@property (nonatomic, strong) UIBarButtonItem * backBarButton;
@property (nonatomic, strong) UIBarButtonItem * indidactor;
//@property (nonatomic, strong) AFURLSessionManager * sessionManager;
@property (nonatomic, assign) BOOL isParserLoading;
@end

@implementation APhotoPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationItem setRightBarButtonItems:@[self.backBarButton,self.indidactor]];
    self.dataSource = self;
}
- (void)viewWillAppear:(BOOL)animated {
    DTrace();
    [self.navigationController setHidesBarsOnSwipe:NO];
    [self.navigationController setHidesBarsOnTap:YES];
    self.isParserLoading = NO;
    self.downloadedPageCount = 0;
    self.navigationItem.title = @"Loading...";
    self.galleryImageURLs = [NSMutableArray array];
    self.galleryURLString = self.galleryInfo[@"url"];
    self.galleryImageCount = self.galleryInfo[@"filecount"];
    self.galleryDownloadQueue = [NSOperationQueue new];
    [self.galleryDownloadQueue setMaxConcurrentOperationCount:5];
    [self loadImageURLsForPage:0];
    
    // kick things off by making the first page
    // it will crash if set pageIndex:0, magic
    self.currentPage = 1;
    [self refreshPageView:self.currentPage animated:NO];
    [super viewWillAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated{
    DTrace();
    [self.galleryDownloadQueue cancelAllOperations];
    [super viewWillDisappear:animated];
}
- (void)dealloc{
    DTrace();
    //#warning downloadtask should cancel after dealloc, but it seems not working, it casuse createNewOperation, FilesMaager fcd crash
    //    [self.sessionManager.operationQueue cancelAllOperations];
    //    [self.sessionManager invalidateSessionCancelingTasks:YES];
}
//- (AFURLSessionManager *)sessionManager {
//    if(_sessionManager == nil){
//        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//        _sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
//    }
//    return _sessionManager;
//}

- (NSString *)hentaiKey {
    if(_hentaiKey == nil){
        NSArray *splitStrings = [self.galleryInfo[@"url"] componentsSeparatedByString:@"/"];
        NSUInteger splitCount = [splitStrings count];
        NSString *checkHentaiKey = [NSString stringWithFormat:@"%@-%@-%@", splitStrings[splitCount - 3], splitStrings[splitCount - 2], self.galleryInfo[@"title"]];
        _hentaiKey = [checkHentaiKey stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    }
    return _hentaiKey;
}
- (NSString *)galleryFolderPath {
    return [[[FilesManager documentFolder] fcd:self.hentaiKey] currentPath];
}
- (void)createNewOperation:(NSString *)urlString {
    HentaiDownloadImageOperation *newOperation = [HentaiDownloadImageOperation new];
    newOperation.downloadURLString = urlString;
    newOperation.isCacheOperation = NO;
    newOperation.hentaiKey = self.hentaiKey;
    newOperation.delegate = self;
    [self.galleryDownloadQueue addOperation:newOperation];
/*
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    __weak APhotoPageViewController * weakSelf = self;
    NSURLSessionDownloadTask *downloadTask = [self.sessionManager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL * docURL = [NSURL fileURLWithPath:[weakSelf galleryFolderPath]];
        return [docURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        DTrace();
    }];
    [downloadTask resume];
 */
}
- (void)loadImageURLsForPage:(NSInteger)index {
    DPLog(@"load Page:%ld/%ld",(long)index, (long)[self.galleryImageCount integerValue]);
    self.isParserLoading = YES;
    __weak APhotoPageViewController * weakSelf = self;
    [HentaiParser requestImagesAtURL:self.galleryURLString atIndex:index completion: ^(HentaiParserStatus status, NSArray *images) {
        self.isParserLoading = NO;
        //Return images url array
        if (status == HentaiParserStatusSuccess && [images count] > 0) { // Node was nil problem, check array count
            [weakSelf.galleryImageURLs addObjectsFromArray:images];
            [weakSelf refreshPageView:weakSelf.currentPage animated:NO];
            for (NSString *imageURL in images) {
                BOOL isExist = [[NSFileManager defaultManager] isReadableFileAtPath:[[weakSelf galleryFolderPath] stringByAppendingPathComponent:[imageURL lastPathComponent]]];
                if (isExist == NO) {
                    [weakSelf createNewOperation:imageURL];
                } else {
                    [self refreshNavigationItemTitle];
                }
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
}
#pragma mark - HentaiDownloadImageOperationDelegate
- (void)downloadResult:(NSString *)urlString heightOfSize:(CGFloat)height isSuccess:(BOOL)isSuccess {
    //completion delegate
    DPLog(@"Download Done %@",[urlString lastPathComponent]);
    BOOL isNearByPage = NO;
    for(NSInteger i = -1 ; i <=1 ; i++) {
        NSInteger safeAndOffsetedIndex = self.currentPage + i - 1;
        if(safeAndOffsetedIndex < 0)safeAndOffsetedIndex = 0;
        if([[self.galleryImageURLs[safeAndOffsetedIndex] lastPathComponent] isEqualToString:[urlString lastPathComponent]]) {
            DPLog(@"Ooh. we go a nearby page:%ld to %ld",(long)self.currentPage + i, (long)self.currentPage);
            isNearByPage = YES;
        }
    }
    if(isNearByPage) {
        [self refreshPageView:self.currentPage animated:NO];
    }
    [self refreshNavigationItemTitle];
}
#pragma mark - UI Refresh methods
- (void)refreshNavigationItemTitle {
    self.downloadedPageCount ++;
    if(self.downloadedPageCount == [self.galleryImageCount integerValue]){
        self.navigationItem.title = self.galleryInfo[@"title"]?self.galleryInfo[@"title"]:@"Gallery";
        [(UIActivityIndicatorView *)self.indidactor.customView stopAnimating];
    } else {
        self.navigationItem.title = [NSString stringWithFormat:@"%ld/%@",(long)self.downloadedPageCount,self.galleryImageCount];
    }
}
- (void)refreshPageView:(NSInteger)index animated:(BOOL)animated{
    DTrace();
    APhotoViewController *currentPage = [APhotoViewController photoViewControllerForImage:[self imageForIndex:index]
                                                                                pageIndex:index];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self setViewControllers:@[currentPage]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:animated
                      completion:NULL];
    });
}
#pragma mark - UIPageViewControllerDataSource
- (UIImage *)imageForIndex:(NSInteger)index
{
    DPLog(@"load Index:%ld",(long)index);
    UIImage *image = nil;
    if(index <= [self.galleryImageCount integerValue]) {
        if(index + 40 >= [self.galleryImageURLs count] &&                            // preload
           self.isParserLoading == NO &&                                             // checking isLoading
           [self.galleryImageURLs count] < [self.galleryImageCount integerValue]) {  // make sure it wont infinity loading
            [self loadImageURLsForPage:(index / 40 + 1)];
        }
        
        if(index <= [self.galleryImageURLs count]) {
            FMStream *hentaiFilesManager = [[FilesManager documentFolder] fcd:self.hentaiKey];
            NSString *eachImageString = self.galleryImageURLs[index -1]; // cuz array start from 0
            image = [UIImage imageWithData:[hentaiFilesManager read:[eachImageString lastPathComponent]]];
        }
    }
    return image;
}
#warning photo should reload after download success
- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerBeforeViewController:(APhotoViewController *)vc
{
    if(vc.pageIndex - 1 <= 0)return nil;
    self.currentPage = vc.pageIndex;
    return [APhotoViewController photoViewControllerForImage:[self imageForIndex:vc.pageIndex - 1] pageIndex:vc.pageIndex - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerAfterViewController:(APhotoViewController *)vc
{
    if(vc.pageIndex + 1 >= [self.galleryImageCount integerValue] + 1)return nil;
    self.currentPage = vc.pageIndex;
    return [APhotoViewController photoViewControllerForImage:[self imageForIndex:vc.pageIndex + 1] pageIndex:vc.pageIndex + 1];
}
#pragma mark - navigationItem
- (UIBarButtonItem *)backBarButton {
    if(_backBarButton == nil){
        _backBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                       target:self
                                                                       action:@selector(backButtonClicked:)];
    }
    return _backBarButton;
}
- (UIBarButtonItem *)indidactor {
    if(_indidactor == nil){
        UIActivityIndicatorView * indicatorView =  [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [indicatorView setHidesWhenStopped:YES];
        [indicatorView startAnimating];
        _indidactor = [[UIBarButtonItem alloc] initWithCustomView:indicatorView];
    }
    return _indidactor;
}
#pragma mark - IBAction
- (IBAction)backButtonClicked:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
