//
//  CourseDownModel.h
//  Athena_iOS
//
//  Created by 郝忠良 on 2020/3/26.
//  Copyright © 2020年 haozhongliang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CourseDownModel : NSObject 


@property(nonatomic,copy)NSString *cachePath;

@property(nonatomic,assign)int64_t totalSize;
@property(nonatomic,copy)NSString *downUrl;
@property(nonatomic,assign)float progress;

@property(nonatomic,strong)NSURLSessionDownloadTask *downTask;

@property(nonatomic,strong)NSData *reData;

@property(nonatomic,copy)NSString *roomId;

@property(nonatomic,copy)void(^progressBlock)(float progess,float didSize,long long allSize);

@property(nonatomic,copy)void(^errorBlock)(NSError *error);

@property(nonatomic,copy)void(^unZipBlock)(float progess);

@property(nonatomic,copy)void(^finshLoad)(void);

-(void)finshToUnzip:(NSURL*)sourePath;

-(void)creatNewDownTask;

-(void)start;

-(void)pause;

-(void)stop;



@end

