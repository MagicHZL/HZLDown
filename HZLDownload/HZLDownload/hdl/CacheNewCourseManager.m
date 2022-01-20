//
//  CacheNewCourseManager.m
//  Athena_iOS
//
//  Created by 郝忠良 on 2020/3/26.
//  Copyright © 2020年 haozhongliang. All rights reserved.
//

#import "CacheNewCourseManager.h"

@implementation CacheNewCourseManager

+(instancetype)shareCacheNewCourseManager{
    
    static CacheNewCourseManager *newCacheManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        newCacheManager = [[CacheNewCourseManager alloc] init];
        
        [newCacheManager initShare];
        
    });
    
    return newCacheManager;
    
}

-(void)initShare{
    
    
    self.downs = [NSMutableArray array];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"chaoge.courseCache"];
    config.HTTPMaximumConnectionsPerHost = 3;
    self.courseSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    
}

-(void)killShowDowns:(void(^)(NSMutableArray *showArr))showBlock{
    
    kWeakSelf(self);
    
    [self.courseSession getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
        
        if (tasks.count > 0) {
            
            for (NSURLSessionTask *courseTask in tasks) {
                
                CourseDownModel *downModel = [[CourseDownModel alloc] init];
                
                downModel.downTask = (NSURLSessionDownloadTask*)courseTask;
                downModel.downUrl = courseTask.currentRequest.URL.absoluteString;
                downModel.roomId = [weakself getRoomidWithUrlStr:downModel.downUrl];
                
                [weakself.downs addObject:downModel];
                
                
            }
            
        }
        
        
        if (showBlock) {
            
            showBlock(weakself.downs);
        }
        
    }];
    
    
    
}



-(void)addCourseDown:(CourseDownModel*)model{
    
    [self.downs addObject:model];
    
    if (self.resumeDatas[model.downUrl]) {
        
//        model.downTask = [self.courseSession downloadTaskWithResumeData:self.resumeDatas[model.downUrl]];
//
//        [self.resumeDatas removeObjectForKey:model.downUrl];
//
//        [self.resumeDatas writeToFile:self.cachePath atomically:NO];
        
    }else{
        
        model.downTask = [self.courseSession downloadTaskWithURL:[NSURL URLWithString:model.downUrl]];
    }
    
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    
    for (CourseDownModel *down in self.downs) {
        
        if (downloadTask == down.downTask) {
            
            if (down.progressBlock) {
//                down.
                
                if (down.totalSize == 0) {
                    
                    down.totalSize = totalBytesExpectedToWrite;
                }
                down.progress = (float)totalBytesWritten/ totalBytesExpectedToWrite;
                
                down.progressBlock((float)totalBytesWritten/ totalBytesExpectedToWrite, (float)totalBytesWritten, totalBytesExpectedToWrite);
            }
            
            break;
        }
        
    }
    
}


-(void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    
    if (error == nil) {
        
        return;
    }
    
    NSData *redata = error.userInfo[NSURLSessionDownloadTaskResumeData];
    
    if (redata) {
        
        [self.resumeDatas setValue:redata forKey:task.currentRequest.URL.absoluteString];
        
        [self.resumeDatas writeToFile:self.cachePath atomically:NO];
        
        
    }else{
        
        for (CourseDownModel *down in self.downs) {
            
            if (task == down.downTask) {
                
                [task cancel];
                
                down.downTask = nil;
                
                if (down.errorBlock) {
                    
                    down.errorBlock(error);
                }
                
                break;
            }
            
        }
        
    }
    
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    
    BOOL isOur = NO;
    
    for (CourseDownModel *down in self.downs) {

        if (downloadTask == down.downTask) {

            [down finshToUnzip:location];
            isOur = YES;
            break;
        }
    }
    
    /**防止程序被杀死后 无内存标记*/
    
    if (!isOur) {
        
        CourseDownModel *bgModel = [[CourseDownModel alloc] init];
        bgModel.downTask = downloadTask;
        bgModel.roomId = [self getRoomidWithUrlStr:downloadTask.currentRequest.URL.absoluteString];
        
        [bgModel finshToUnzip:location];
        
    }
    
    
}


-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    
    if (self.sessionBlock) {
        
         self.sessionBlock();
    }
   
}


-(NSString *)cachePath{
    
    NSString *path = [NSString stringWithFormat:@"%@/%@",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject],@"duobeiyun"];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) {
        
        [NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        
    }
    
    path = [NSString stringWithFormat: @"%@/mycache.data",path];
    
    return path;
}


-(void)reloadDown{
    
    for (CourseDownModel *downMo in self.downs) {
        
        if (downMo.downTask) {
            
            [downMo.downTask resume];
            
            break;
            
        }
        
    }
    
}


-(NSMutableDictionary *)resumeDatas{
    
    if (!_resumeDatas) {
        
         _resumeDatas = [NSMutableDictionary dictionaryWithContentsOfFile:self.cachePath];
        
        if (!_resumeDatas) {
            
            _resumeDatas = [NSMutableDictionary dictionary];
        }
    }
    
    return _resumeDatas;
}

-(NSString*)getRoomidWithUrlStr:(NSString*)urlStr{
    
    NSString *roomId = [urlStr lastPathComponent];
    
    roomId =  [[roomId stringByReplacingOccurrencesOfString:@".zip" withString:@""] stringByReplacingOccurrencesOfString:@"_v" withString:@""];
    
    return roomId;
    
}


@end
