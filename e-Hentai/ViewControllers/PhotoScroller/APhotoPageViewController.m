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
@property (nonatomic, strong) NSString * hentaiURLString;
@property (nonatomic, strong) NSMutableArray * hentaiImageURLs;
@property (nonatomic, assign) NSString * galleryImageCount;
@property (nonatomic, assign) BOOL isParserLoading;
@end

@implementation APhotoPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.dataSource = self;
}
- (void)viewWillAppear:(BOOL)animated {
    self.isParserLoading = NO;
    self.hentaiURLString = self.galleryInfo[@"url"];
    self.galleryImageCount = self.galleryInfo[@"filecount"];
    [self loadImageURLsForPage:0];
    
    // kick things off by making the first page
    APhotoViewController *pageZero = [APhotoViewController photoViewControllerForImage:[UIImage imageNamed:@"aaa"] pageIndex:1];
    if (pageZero != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{

        [self setViewControllers:@[pageZero]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:animated
                      completion:NULL];
        });
    }
    [super viewWillAppear:animated];
}
- (void)createNewOperation:(NSString *)urlString {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    __weak APhotoPageViewController * weakSelf = self;
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        //        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        //        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
        NSURL * docURL = [NSURL fileURLWithPath:[[[FilesManager documentFolder] fcd:weakSelf.hentaiKey] currentPath]];
        return [docURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
    }];
    [downloadTask resume];
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
- (void)loadImageURLsForPage:(NSInteger)index {
    self.isParserLoading = YES;
    [HentaiParser requestImagesAtURL:self.hentaiURLString atIndex:index completion: ^(HentaiParserStatus status, NSArray *images) {
        self.isParserLoading = NO;
        //Return images url array
        if (status == HentaiParserStatusSuccess) {
            self.hentaiImageURLs = [images mutableCopy];
            for (NSString *imageURL in images) {
                FMStream *hentaiFilesManager = [[FilesManager documentFolder] fcd:self.hentaiKey];
                BOOL isExist = [[NSFileManager defaultManager] isReadableFileAtPath:[[hentaiFilesManager currentPath] stringByAppendingPathComponent:[imageURL lastPathComponent]]];
                if (isExist == NO) {
                    [self createNewOperation:imageURL];
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UIPageViewControllerDataSource
- (UIImage *)imageForIndex:(NSInteger)index
{
    NSLog(@"loadIndex:%ld",(long)index);
    UIImage *image = nil;
    if(index < [self.galleryImageCount integerValue]) {
        if(index + 10 > [self.hentaiImageURLs count] && self.isParserLoading == NO) {
            [self loadImageURLsForPage:(index / 40 + 1)];
        }
        
        if(index < [self.hentaiImageURLs count]) {
            FMStream *hentaiFilesManager = [[FilesManager documentFolder] fcd:self.hentaiKey];
            NSString *eachImageString = self.hentaiImageURLs[index];
            image = [UIImage imageWithData:[hentaiFilesManager read:[eachImageString lastPathComponent]]];
        }
    }
    return image;
}
- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerBeforeViewController:(APhotoViewController *)vc
{
    return [APhotoViewController photoViewControllerForImage:[self imageForIndex:vc.pageIndex - 1] pageIndex:vc.pageIndex - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerAfterViewController:(APhotoViewController *)vc
{
    return [APhotoViewController photoViewControllerForImage:[self imageForIndex:vc.pageIndex + 1] pageIndex:vc.pageIndex + 1];
}
@end
