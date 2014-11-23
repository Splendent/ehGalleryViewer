//
//  SPEntryCollectionViewController.m
//  e-Hentai
//
//  Created by  Splenden on 2014/11/6.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import "SPEntryCollectionViewController.h"
#import "APhotoPageViewController.h"
#import "NSString+FileSize.h"
//HentaiCore
#import "HentaiSearchFilter.h"
#import "HentaiFilterView.h"
//HentaiCore - 3rd, Cache
#import "UIImageView+WebCache.h"

NSInteger const kSPEntryCollectionViewCellImageTag = 100;
NSInteger const kSPEntryCollectionViewCellLabelTag = 200;
@interface SPEntryCollectionViewController ()
@property (nonatomic, assign) NSInteger webPageIndex;
@property (nonatomic, strong) NSMutableArray * galleries;
@property (nonatomic, assign) BOOL isHentaiParserLoading;
@property (nonatomic, strong) UIRefreshControl * refreshControl;
@property (nonatomic, strong) NSArray * filterArray;
@end

@implementation SPEntryCollectionViewController

NSString * const kCollectionViewCell = @"genericCell";
NSString * const kCollectionViewLargeCell = @"genericLargeCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Do any additional setup after loading the view.
    
    //setup galleries
    self.galleries = [NSMutableArray array];
    [self createGallery];
    
    //setup refresControl
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl setTintColor:[UIColor whiteColor]];
    [self.refreshControl addTarget:self action:@selector(startRefresh:)
                  forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
}
- (void)viewWillAppear:(BOOL)animated {
    DTrace();
    [self.navigationController setHidesBarsOnTap:NO];
    [self.navigationController setHidesBarsOnSwipe:YES];
    [self.navigationController setToolbarHidden:YES animated:animated];

    self.isHentaiParserLoading = NO;
    self.docSizeBarButton.title = [NSString sizeOfFolder:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]];
    [super viewWillAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    DTrace();
    [super viewWillDisappear:animated];
}
- (void)dealloc {
    DTrace();
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    APhotoPageViewController * photoVC = segue.destinationViewController;
    UICollectionViewCell * cell = sender;
    NSIndexPath * indexPath = [self.collectionView indexPathForCell:cell];
    photoVC.galleryInfo = self.galleries[indexPath.row];
    [super prepareForSegue:segue sender:sender];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.galleries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row + 5 > [self.galleries count] && self.isHentaiParserLoading == NO){
        self.webPageIndex++;
        [self loadGalleryAtIndex:self.webPageIndex WithFilter:self.searchTextField.text];
    }
    NSString * reuseIdentifier = kCollectionViewCell;
#warning it seems i have to use customlayout to do multiple cell size?
//    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale;
//    if(screenWidth > 1000) {
//        reuseIdentifier = kCollectionViewLargeCell;
//    }
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor darkTextColor];
    UIImageView * imageView = (UIImageView *)[cell viewWithTag:kSPEntryCollectionViewCellImageTag];
    UILabel * label = (UILabel *)[cell viewWithTag:kSPEntryCollectionViewCellLabelTag];
    // Configure the cell
    NSDictionary *hentaiInfo = self.galleries[indexPath.row];
    label.text = hentaiInfo[@"title"];
    
    
    NSString *imgUrl = @"http://i.imgur.com/1gzbPf1.jpg"; //貓貓圖(公司用)
    imgUrl = hentaiInfo[@"thumb"]; //(真的H縮圖)
    [imageView sd_setImageWithURL:[NSURL URLWithString:imgUrl]
                 placeholderImage:[UIImage imageNamed:@"default-placeholder"]
                          options:SDWebImageRefreshCached];
    
//    [self.cellCategory setCategoryStr:dataDict[@"category"]];
//    [self.cellStar setStar:dataDict[@"rating"]];

    return cell;
}

#pragma mark <UICollectionViewDelegate>
//nothing here
#pragma mark - IBAction
- (IBAction)search:(id)sender {
#warning should do something to prevent multiple search
    //textFieldEndAndExit or click searchBarButton
    [self.refreshControl beginRefreshing];
    [self createGalleryWithFilter:self.searchTextField.text];
}
- (IBAction)startRefresh:(id)sender {
    //pullToRefresh
    [self createGalleryWithFilter:self.searchTextField.text];
}
- (IBAction)clearFiles:(id)sender{
    //clear document folder
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] error:&error];
    if (error == nil) {
        for (NSString *path in directoryContents) {
            NSString *fullPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:path];
            BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
            if (!removeSuccess) {
                DPLog(@"clear fail");
            }
        }
    } else {
        DPLog(@"clear fail");
    }
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDisk];
    
    UIBarButtonItem * senderButton = sender;
    senderButton.title =[NSString sizeOfFolder:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]];
}
#pragma mark - property
- (NSArray *) filterArray {
    return @[@1,@2,@3,@4,@5,@6,@7,@8,@9,@0];
}

#pragma mark - gallery method
- (void)createGallery{
    [self createGalleryWithFilter:@""];
}
- (void)createGalleryWithFilter:(NSString *)filter{
    self.isHentaiParserLoading = YES;
    self.webPageIndex = 0;
    [self.collectionView setContentOffset:CGPointMake(0, -self.collectionView.contentInset.top) animated:YES];
    NSString *correctedFilterString = [[[filter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *baseUrlString = [NSString stringWithFormat:@"http://g.e-hentai.org/?page=%lu", (unsigned long)self.webPageIndex];
    NSString *filterURLString = [HentaiSearchFilter searchFilterUrlByKeyword:correctedFilterString
                                                                 filterArray:[self filterArray]
                                                                     baseUrl:baseUrlString];
    __weak SPEntryCollectionViewController * weakSelf = self;
    [HentaiParser requestListAtFilterUrl:filterURLString completion: ^(HentaiParserStatus status, NSArray *listArray) {
        if(status == HentaiParserStatusSuccess && listArray != nil) {
            weakSelf.galleries = [listArray mutableCopy];
            [weakSelf.collectionView reloadData];
        } else {
            DPLog(@"search fail");
        }
        weakSelf.isHentaiParserLoading = NO;
        [weakSelf.refreshControl endRefreshing];
    }];
}
- (void)loadGalleryAtIndex:(NSInteger)index {
    [self loadGalleryAtIndex:index WithFilter:@""];
}
- (void)loadGalleryAtIndex:(NSInteger)index WithFilter:(NSString *)filter {
    self.isHentaiParserLoading = YES;
    NSString *correctedFilterString = [[[filter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *baseUrlString = [NSString stringWithFormat:@"http://g.e-hentai.org/?page=%lu", (unsigned long)index];
    NSString *filterURLString = [HentaiSearchFilter searchFilterUrlByKeyword:correctedFilterString filterArray:[self filterArray] baseUrl:baseUrlString];
    __weak SPEntryCollectionViewController * weakSelf = self;
    [HentaiParser requestListAtFilterUrl:filterURLString completion: ^(HentaiParserStatus status, NSArray *listArray) {
        if(status == HentaiParserStatusSuccess && [listArray count] > 0) {
            [weakSelf.galleries addObjectsFromArray:listArray];
            [weakSelf.collectionView reloadData];
        } else {
            DPLog(@"search fail");
        }
        weakSelf.isHentaiParserLoading = NO;
        [weakSelf.refreshControl endRefreshing];
    }];
}
@end
