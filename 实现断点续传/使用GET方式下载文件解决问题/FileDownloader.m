//
//  FileDownloader.m
//  使用GET方式下载文件解决问题
//
//  Created by libaojun on 16/8/8.
//  Copyright © 2016年 libaojun. All rights reserved.
//

#import "FileDownloader.h"
//遵守这个协议,实现里面的三个协议方法
@interface FileDownloader()<NSURLConnectionDataDelegate>
//获取当前文件的总长度
@property (nonatomic,assign) long long expected;

@property(nonatomic,assign)float currentLength;

@property(nonatomic,strong)NSOutputStream *outputStream;

@property(nonatomic,strong)NSURLConnection *connection;

//定义一个block属性,用于记录我们传入的block
@property(nonatomic,copy)void(^progressBlock)(float progress);



//这样还是解决不了内存峰值过高的问题,原因还是一样的,把数据都一次性加载到内存中了
//@property(nonatomic,strong)NSMutableData *Mdata;

@end

@implementation FileDownloader
- (void)susedownload{
    //取消下载链接,调用之后就不会再继续下载了
    [self.connection cancel];
    
    [self.outputStream close];
}


- (void)donwloadWithUrolString:(NSString *)urlString progress:(void (^)(float))progress {
    //2.使用一个属性记录这个block
    self.progressBlock = progress;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        //记录服务器文件的大小
        self.expected = [self getServeFileSize:urlString];
        //定义一个文件保存的路径
        NSString *filePath = @"/Users/libaojun/Desktop/shougou.zip";
        
        //获取本地文件大小
        self.currentLength = [self getLocalFileSize:filePath];
        
        if (self.currentLength == -1) {
            NSLog(@"下载完成,不用下载了");
            return;
        }
        //地址
        NSURL *URL= [NSURL URLWithString:urlString];
        //请求
        NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:URL];
        
        //告诉服务器从哪个位置开始下载
        [requestM setValue:[NSString stringWithFormat:@"bytes= %f",self.currentLength] forHTTPHeaderField:@"Range"];
        
        //发起请求
        self.connection = [NSURLConnection connectionWithRequest:requestM delegate:self];
        [[NSRunLoop currentRunLoop]run];
    });
}

//获取,本地文件和服务器文件的大小.进行对比
- (long long)getLocalFileSize:(NSString *)filePath{
    //获取文件管理器
    NSFileManager *manafer = [NSFileManager defaultManager];
    //通过文件管理器去获取相对应的一些属性,如果文件不存在的话,返回的是nil
    NSDictionary *attr = [manafer attributesOfItemAtPath:filePath error:NULL];
    //如果attr不为空,那么就代表本地文件存在
    if (attr != nil) {
        //获取本地文件的大小
        long long localSize = attr.fileSize;
        //1,如果本地文件的大小比服务器的文件大小大的话,就删除重新下载
        if (localSize > self.expected) {
            //删除本地文件
            [manafer removeItemAtPath:filePath error:NULL];
            //返回0
            return 0;
        }else if(localSize < self.expected){
            return localSize;
        }else{
            //能进入到这个代码块,就证明文件已经下载完成了.-1的值是自己随意起的
            return -1;
        }
        
    }
   //默认返回0代表本地文件没有大小
    return 0;
}



//通过url的地址获取服务器文件的大小
- (long long)getServeFileSize:(NSString *)string {
    
    NSURL *url = [NSURL URLWithString:string];
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:url];
    requestM.HTTPMethod = @"HEAD";
    
    NSURLResponse *response;
    //同步获取响应头
    [NSURLConnection sendSynchronousRequest:requestM returningResponse:&response error:NULL];
    //获取文件大小
    return response.expectedContentLength;
}


    //解决峰值过高的方法就是,边下变保存,下一点保存一点

- (void)saveData:(NSData *)data{
    //保存下载文件的路径
    NSString *filePath = @"/Users/libaojun/Desktop/shougou.zip";
    //如果该文件不存在,那么这个方法初始化出来的对象就是nil
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (handle == nil) {
        //如果,handle等于nil那么就是该文件在路径不存在,就会创建一个文件夹,并且将data数据保存进去
        [data writeToFile:filePath atomically:true];
        
    }else{
        //如果存在,那么就讲该文件句柄移动到文件的最后位置.以保证不会重复写入,而是从文件最后位置开始写入的
        [handle seekToEndOfFile];
        //如果文件存在的话,就将传入的data写入到文件
        [handle writeData:data];
        //完成写入.要关闭该文件的句柄
//    closeFile:关闭一个打开的文件
        [handle closeFile];
        
    }
    
}
//    这样直接发请求会造成两个问题.一是内存峰值过高,二是无法监听下载进度,所以需要实现那三个代理方法
//    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
//        if (connectionError != nil || data.length == 0) {
//            NSLog(@"%@:错误",connectionError);
//            return;
//        }
//    }];
//}


//实现遵守的代理方法.收到响应会调用这个方法
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
     //当收到响应的时候,应该先获取文件的总长度
     //expectedContentLength这个方法就是获取文件总长度的(预期长度)
//  self.expected = response.expectedContentLength;

    //保存到的文件路径
    NSString *filePath = @"/Users/libaojun/Desktop/shougou.zip";
    
    
    //初始化输出流,并且打开管道
    //参数一:是文件路径.参数二是:代表是否要往其后面拼接数据()
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:true];
    
    //打开
    [self.outputStream open];
    
    
    
}
//当已经收到数据的时候就会调用这个方法.链接数据
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    //获取到已经下载多少
    self.currentLength += data.length;
    //计算当前的进度(如何计算当前的进度.用当前的进度,除以总的长度)
    float Progress = self.currentLength/self.expected;
    //往可变的二进制数据中存放data
//    [self.Mdata appendData:data];
    
    //保存
//    [self saveData:data];
    
//    参数一:要写入的字节.参数二:写入最多的大小
    [self.outputStream write:data.bytes maxLength:data.length];
    
    
    //3.当我们需要的时候才去调用这个block
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressBlock(Progress);
    });
    
    NSLog(@"收到数据%f:",Progress);
}
//在本次链接完成以后就会调用这个方法.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //在链接响应完成以后,应该把二进制的数据存放在公司指定的地方.一般公司都是存放在沙盒中,现在为了方便放在自己桌面
//    [self.Mdata writeToFile:@"/Users/libaojun/Desktop/shougou.zip" atomically:true];
    NSLog(@"下载完成");
    
    [self.outputStream close];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"下载失败");
    
    [self.outputStream close];
    
}
//#pragma mark - 懒加载
//- (NSMutableData *)Mdata{
//    if (_Mdata == nil) {
//        _Mdata = [NSMutableData data];
//    }
//    return _Mdata;
//}
@end



















