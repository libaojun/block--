//
//  ViewController.m
//  使用GET方式下载文件解决问题
//
//  Created by libaojun on 16/8/8.
//  Copyright © 2016年 libaojun. All rights reserved.
//

#import "ViewController.h"
#import "FileDownloader.h"
@interface ViewController ()

@property(nonatomic,strong)FileDownloader *downloader;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)downloadBtton:(id)sender {
    self.downloader = [[FileDownloader alloc]init];
    
    [self.downloader donwloadWithUrolString:@"http://127.0.0.1/sogou.zip" progress:^(float progress) {
        self.progressView.progress = progress;
        
    }];
}
- (IBAction)suspendButton:(id)sender {
    [self.downloader susedownload];
    NSLog(@"停止下载");
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
