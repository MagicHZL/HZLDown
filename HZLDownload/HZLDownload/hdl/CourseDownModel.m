//
//  CourseDownModel.m
//  Athena_iOS
//
//  Created by 郝忠良 on 2020/3/26.
//  Copyright © 2020年 haozhongliang. All rights reserved.
//

#import "CourseDownModel.h"
#import "CacheNewCourseManager.h"
//注意！~~

@implementation CourseDownModel

-(void)finshToUnzip:(NSURL*)sourePath{
    

    [NSFileManager.defaultManager copyItemAtURL:sourePath toURL: [NSURL fileURLWithPath: [NSString stringWithFormat:@"%@/%@.zip",self.cachePath,self.roomId]] error:nil];
    
    int64_t size = 0 ;//[AthTool fileSizeAtPath:AthStrAppend(@"%@/%@.zip",self.cachePath,self.roomId)]
    
    
    if (self.totalSize == 0) {
        
        self.totalSize = size;
        
    }

    /**新的下载逻辑*/
    if (self.finshLoad) {
        
        self.finshLoad();
    }
    
    [self.downTask cancel];
    
    NSMutableArray *downs = [CacheNewCourseManager shareCacheNewCourseManager].downs;
    
    if ([downs indexOfObject:self] != NSNotFound) {
        
        [downs removeObject:self];
    }
    
    
    /****/
    //防止进行多次解压
//
//     if ([AppManager.unzipArr containsObject:self.roomId]) {
//
//         return;
//     }
    
//    [AppManager.unzipArr addObject:self.roomId];
  /*
   旧下载解压逻辑
   
   //    if (self.progressBlock) {
   //
   //        self.progressBlock(1, self.totalSize, self.totalSize);
   //    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        //有待测试
       BOOL isZip = [DBYZipArchive unzipFileAtPath:AthStrAppend(@"%@/%@.zip",self.cachePath,self.roomId) toDestination:AthStrAppend(@"%@",self.cachePath) delegate:self uniqueId:self.roomId];
        
        if (!isZip) {
            
            ATLog(@"解压失败");//解压失败删除资源
            [ATFileManager removeItemAtPath:AthStrAppend(@"%@/%@.zip",self.cachePath,self.roomId) error:nil];
//            [AppManager.unzipArr removeObject:self.roomId];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                   
                if (self.errorBlock) {
                    
                    NSError *err = [NSError errorWithDomain:NSItemProviderErrorDomain code:111 userInfo:@{@"errmsg":@"解压失败,请重新下载"}];
                    self.errorBlock(err);
                    
                    if (self.downTask) {
                        
                        [self.downTask cancel];
                        self.downTask = nil;
                    }
                    
                }
                   
            });
            
        }
    });
    
    */
}

//- (void)zipArchiveDidUnzipArchiveAtPath:(NSString *)path
//     zipInfo:(unz_global_info)zipInfo
//unzippedPath:(NSString *)unzippedPat
//                               uniqueId:(NSString *)uniqueId{
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//
//        if (self.finshLoad) {
//
//            self.finshLoad();
//        }
//
//        [self.downTask cancel];
//
//        NSMutableArray *downs = [CacheNewCourseManager shareCacheNewCourseManager].downs;
//
//        if ([downs indexOfObject:self] != NSNotFound) {
//
//            [downs removeObject:self];
//        }
//
//    });
//
//    ATLog(@"----开始删除-----");
//
//    [ATFileManager removeItemAtPath:AthStrAppend(@"%@/%@.zip",self.cachePath,self.roomId) error:nil];
////    [AppManager.unzipArr removeObject:self.roomId];
//
//    ATLog(@"----删除结束-----");
//
//
//}
//
//- (void)zipArchiveWillUnzipFileAtIndex:(NSInteger)fileIndex
// totalFiles:(NSInteger)totalFiles
//archivePath:(NSString *)archivePath
//                              fileInfo:(unz_file_info)fileInfo{
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//        if (self.unZipBlock) {
//
//            self.unZipBlock((float)fileIndex/totalFiles);
//
//        }
//
//    });
//
//}
//
//- (void)zipArchiveDidUnzipFileAtIndex:(NSInteger)fileIndex
// totalFiles:(NSInteger)totalFiles
//archivePath:(NSString *)archivePath
//                             fileInfo:(unz_file_info)fileInfo{
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//        if (self.unZipBlock) {
//
//            self.unZipBlock((float)fileIndex/totalFiles);
//
//        }
//
//    });
//
//}



-(void)start{
    
    
    if (self.downTask == nil) {
        
        [self creatNewDownTask];
        
    }
    
    
    if (self.downTask.state == NSURLSessionTaskStateRunning) {
        return;
    }
    
    [self.downTask resume];
    
    
}

-(void)pause{
    

    kWeakSelf(self);
    [self.downTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        
        weakself.downTask = nil;
    }];
    
    /* 此为另一种方案 暂不可取
     
    if (self.downTask.state == NSURLSessionTaskStateSuspended) {
     
        return;
    }
     
    [self.downTask suspend];
    
    //此为延时递归回掉 防止task被挂起时间太长导致重新下载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (self) {
            
            if(self.downTask.state == NSURLSessionTaskStateSuspended){
                
                [self.downTask resume];
                [self pause];
            }
            
        }
        
    });*/
    
}

-(void)creatNewDownTask{
    
    CacheNewCourseManager *manager = [CacheNewCourseManager shareCacheNewCourseManager];
    
    if (manager.resumeDatas[self.downUrl]) {
        
        self.downTask = [manager.courseSession downloadTaskWithResumeData:manager.resumeDatas[self.downUrl]];
        
        [manager.resumeDatas removeObjectForKey:self.downUrl];
        
        [manager.resumeDatas writeToFile:self.cachePath atomically:NO];
         
    }else{
    
        self.downTask = [manager.courseSession downloadTaskWithURL:[NSURL URLWithString:self.downUrl]];
         
    }
 
}

-(void)stop{
    
    if (self.downTask == nil) {
        
        [self start];
    }
    
    [self.downTask cancel];
    
//    if (![AppManager.unzipArr containsObject:self.roomId]) {
//
//        [ATFileManager removeItemAtPath:AthStrAppend(@"%@/%@.zip",self.cachePath,self.roomId) error:nil];
//    }
    
    NSMutableArray *downs = [CacheNewCourseManager shareCacheNewCourseManager].downs;
      
    if ([downs indexOfObject:self] != NSNotFound) {
          
        [downs removeObject:self];
    }
}


-(NSString *)cachePath{
    
    NSString *path = [NSString stringWithFormat:@"%@/%@",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject],@"duobeiyun"];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) {
        
        [NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        
    }
    
    
    return path;
}

-(void)dealloc{
    
    
    
}

@end
