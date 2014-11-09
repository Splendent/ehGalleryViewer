//
//  APhotoPageViewController.h
//  e-Hentai
//
//  Created by  Splenden on 2014/11/9.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APhotoPageViewController : UIPageViewController <UIPageViewControllerDataSource, HentaiDownloadImageOperationDelegate>
@property (nonatomic, strong) NSDictionary *galleryInfo;
@end
