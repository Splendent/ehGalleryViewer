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

NSInteger const kEHPagePhotoNumber = 40;
@implementation APhotoPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationItem setRightBarButtonItems:@[self.backBarButton,self.indidactor]];
    self.dataSource = self;
}
- (void)viewWillAppear:(BOOL)animated {
    DTrace();
    //NavigationBar
    [self.navigationController setHidesBarsOnSwipe:NO];
    [self.navigationController setHidesBarsOnTap:YES];
    [self.navigationController setToolbarHidden:self.navigationController.navigationBarHidden animated:animated];
    [self.navigationController.barHideOnTapGestureRecognizer addTarget:self action:@selector(hideToolbar:)];
//    [self.navigationController.toolbar setTranslucent:YES];

    self.navigationItem.title = @"Loading...";
    //Parse,Download Status
    self.isParserLoading = NO;
    self.downloadedPageCount = 0;
    //Gallery infos
    self.galleryImageURLs = [NSMutableArray array];
    self.galleryURLString = self.galleryInfo[@"url"];
    self.galleryImageCount = self.galleryInfo[@"filecount"];
    //DownloadQueue setup
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
    [self.navigationController.barHideOnTapGestureRecognizer removeTarget:self action:@selector(hideToolbar:)];
    [super viewWillDisappear:animated];
}
- (void)dealloc{
    DTrace();
}
#pragma mark - property
- (NSString *)hentaiKey {
    if(_hentaiKey == nil){
        NSArray *splitStrings = [self.galleryInfo[@"url"] componentsSeparatedByString:@"/"];
        NSUInteger splitCount = [splitStrings count];
        NSString *checkHentaiKey = [NSString stringWithFormat:@"%@-%@-%@", splitStrings[splitCount - 3], splitStrings[splitCount - 2], self.galleryInfo[@"title"]];
        _hentaiKey = [checkHentaiKey stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    }
    return _hentaiKey;
}
#pragma mark - download Image methods
- (void)createNewOperation:(NSString *)urlString {
    HentaiDownloadImageOperation *newOperation = [HentaiDownloadImageOperation new];
    newOperation.downloadURLString = urlString;
    newOperation.isCacheOperation = NO;
    newOperation.hentaiKey = self.hentaiKey;
    newOperation.delegate = self;
    [self.galleryDownloadQueue addOperation:newOperation];
}
- (void)loadImageURLsForPage:(NSInteger)index {
    DPLog(@"load Page:%ld/%ld",(long)index, (long)[self.galleryImageCount integerValue]);
    self.isParserLoading = YES;
    UIActivityIndicatorView * indicator = (UIActivityIndicatorView *)self.indidactor.customView;
    if([indicator isAnimating]==NO){
        [indicator startAnimating];
    }
    __weak APhotoPageViewController * weakSelf = self;
    [HentaiParser requestImagesAtURL:self.galleryURLString atIndex:index completion: ^(HentaiParserStatus status, NSArray *images) {
        self.isParserLoading = NO;
        //Return images url array
        if (status == HentaiParserStatusSuccess && [images count] > 0) { // Node was nil problem, check array count
            [weakSelf.galleryImageURLs addObjectsFromArray:images];
            [weakSelf refreshPageView:weakSelf.currentPage animated:NO];
            for (NSString *imageURL in images) {
                NSString * galleryFolderPath = [[[FilesManager documentFolder] fcd:self.hentaiKey] currentPath];
                BOOL isExist = [[NSFileManager defaultManager] isReadableFileAtPath:[galleryFolderPath stringByAppendingPathComponent:[imageURL lastPathComponent]]];
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
    UIActivityIndicatorView * indicator = (UIActivityIndicatorView *)self.indidactor.customView;
    if(self.downloadedPageCount == [self.galleryImageURLs count]){
        self.navigationItem.title = self.galleryInfo[@"title"]?self.galleryInfo[@"title"]:@"Gallery";
        [indicator stopAnimating];
    } else {
        self.navigationItem.title = [NSString stringWithFormat:@"D:%ld/%@",(long)self.downloadedPageCount,self.galleryImageCount];
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
        if(index + 5 >= [self.galleryImageURLs count] &&                             // preload
           self.isParserLoading == NO &&                                             // checking isLoading
           [self.galleryImageURLs count] < [self.galleryImageCount integerValue]) {  // make sure it wont infinity loading
            [self loadImageURLsForPage:(index / kEHPagePhotoNumber + 1)];
        }
        
        if(index <= [self.galleryImageURLs count]) {
            FMStream *hentaiFilesManager = [[FilesManager documentFolder] fcd:self.hentaiKey];
            NSString *eachImageString = self.galleryImageURLs[index -1]; // cuz array start from 0
            image = [UIImage imageWithData:[hentaiFilesManager read:[eachImageString lastPathComponent]]];
        }
    }
    return image;
}
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
- (IBAction)hideToolbar:(id)sender {
    [self.navigationController setToolbarHidden:!self.navigationController.toolbar.hidden animated:YES];
}
- (IBAction)backButtonClicked:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
