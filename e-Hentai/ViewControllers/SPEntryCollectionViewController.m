//
//  SPEntryCollectionViewController.m
//  e-Hentai
//
//  Created by  Splenden on 2014/11/6.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import "SPEntryCollectionViewController.h"
#import "APhotoPageViewController.h"
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
@end

@implementation SPEntryCollectionViewController

static NSString * const reuseIdentifier = @"genericCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Do any additional setup after loading the view.
    [self.navigationController setHidesBarsOnTap:NO];
    [self.navigationController setHidesBarsOnSwipe:YES];
}
- (void)viewWillAppear:(BOOL)animated {
    self.webPageIndex = 0;
    self.isHentaiParserLoading = NO;
    __weak SPEntryCollectionViewController * weakSelf = self;
    [HentaiParser requestListAtIndex:self.webPageIndex completion: ^(HentaiParserStatus status, NSArray *listArray) {
        DTrace();
        weakSelf.galleries = [listArray mutableCopy];
        [weakSelf.collectionView reloadData];
    }];
    
    [super viewWillAppear:animated];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
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
        [self loadGalleryAtIndex:indexPath.row];
    }
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor greenColor];
    UIImageView * imageView = (UIImageView *)[cell viewWithTag:kSPEntryCollectionViewCellImageTag];
    UILabel * label = (UILabel *)[cell viewWithTag:kSPEntryCollectionViewCellLabelTag];
    // Configure the cell
    NSDictionary *hentaiInfo = self.galleries[indexPath.row];
    label.text = hentaiInfo[@"title"];
    
    
    NSString *imgUrl = @"http://i.imgur.com/1gzbPf1.jpg"; //貓貓圖(公司用)
    
    imgUrl = hentaiInfo[@"thumb"]; //(真的H縮圖)
    
    [imageView sd_setImageWithURL:[NSURL URLWithString:imgUrl]
                 placeholderImage:nil
                          options:SDWebImageRefreshCached];
    
//    [self.cellCategory setCategoryStr:dataDict[@"category"]];
//    [self.cellStar setStar:dataDict[@"rating"]];

    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/
#pragma mark - 
-(void) loadGalleryAtIndex:(NSInteger)index{
    self.isHentaiParserLoading = YES;
    NSString *baseUrlString = [NSString stringWithFormat:@"http://g.e-hentai.org/?page=%lu", (unsigned long)index];
//    NSString *filterString = [HentaiSearchFilter searchFilterUrlByKeyword:searchWord filterArray:[filterView filterResult] baseUrl:baseUrlString];
    __weak SPEntryCollectionViewController * weakSelf = self;
    [HentaiParser requestListAtFilterUrl:baseUrlString completion: ^(HentaiParserStatus status, NSArray *listArray) {
        DTrace();
        [weakSelf.galleries addObjectsFromArray:listArray];
        [weakSelf.collectionView reloadData];
        weakSelf.isHentaiParserLoading = NO;
    }];
}
@end
