//
//  ASUser.h
//  AppService
//
//  Created by 강기태 on 2014. 8. 5..
//  Copyright (c) 2014년 IGAWorks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ASUserLoginCompleteCallback)( NSString* objectId );

@interface ASUser : NSObject

@property (nonatomic) NSMutableArray* loginWaitingCallbacks;

+ (void)login;
+ (NSString*)getSessionId;
+ (NSString*)getObjectId;

+ (void)setLoginCompleteCallback:(ASUserLoginCompleteCallback)block;

+ (void)setTargetingData:(id)obj withKey:(NSString*)key;
+ (id)getTargetingDataWithKey:(NSString*)key;
@end
