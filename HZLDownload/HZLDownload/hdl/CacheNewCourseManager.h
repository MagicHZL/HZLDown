//
//  CacheNewCourseManager.h
//  Athena_iOS
//
//  Created by 郝忠良 on 2020/3/26.
//  Copyright © 2020年 haozhongliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CourseDownModel.h"
#define kWeakSelf(type)   __weak typeof(type) weak##type = type;

@interface CacheNewCourseManager : NSObject <NSURLSessionDelegate>

@property(nonatomic,copy) void (^sessionBlock)(void);

@property(nonatomic,strong)NSURLSession *courseSession;

@property(nonatomic,strong)NSMutableArray<CourseDownModel * > *downs;

@property(nonatomic,strong)NSMutableDictionary *resumeDatas;

+(instancetype)shareCacheNewCourseManager;

-(void)addCourseDown:(CourseDownModel*)model;

-(void)killShowDowns:(void(^)(NSMutableArray *showArr))showBlock;

-(void)reloadDown;

//-(void)re

@end

