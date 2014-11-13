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
#warning removable vars
@property (nonatomic, strong) NSMutableArray * hentaiImageURLs;
@property (nonatomic, assign) NSString * galleryImageCount;
@end

@implementation APhotoPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.dataSource = self;
}
- (void)viewWillAppear:(BOOL)animated {
//    self.hentaiResults = [NSMutableDictionary new];
    NSString * hentaiURLString = self.galleryInfo[@"url"];
    self.galleryImageCount = self.galleryInfo[@"filecount"];
    
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
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        //        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        //        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
        NSURL * docURL = [NSURL fileURLWithPath:[[[FilesManager documentFolder] fcd:self.hentaiKey] currentPath]];
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
    if(index < [self.galleryImageCount integerValue]) {
        FMStream *hentaiFilesManager = [[FilesManager documentFolder] fcd:self.hentaiKey];
        NSString *eachImageString = self.hentaiImageURLs[index];
//        if (self.hentaiResults[[eachImageString lastPathComponent]]) {
            UIImage *image = [UIImage imageWithData:[hentaiFilesManager read:[eachImageString lastPathComponent]]];
            return image;
//        }
    } else if (self.hentaiImageURLs == nil || [self.hentaiImageURLs count] == 0){
        
    }
    return nil;
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
