//
//  FileDownloader.h
//  使用GET方式下载文件解决问题
//
//  Created by libaojun on 16/8/8.
//  Copyright © 2016年 libaojun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileDownloader : NSObject

- (void)donwloadWithUrolString:(NSString *)urlString progress:(void(^)(float progress))progress;

- (void)susedownload;

@end
