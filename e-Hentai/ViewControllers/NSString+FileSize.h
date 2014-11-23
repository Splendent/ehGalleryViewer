//
//  NSString+FileSize.h
//  ehGallery
//
//  Created by  Splenden on 2014/11/23.
//  Copyright (c) 2014年 ChilunChen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (FileSize)
+(NSString *)sizeOfFolder:(NSString *)folderPath;
+(NSString *)sizeOfFile:(NSString *)filePath;
@end
