//
//  ASPush.h
//  AppService
//
//  Created by 강기태 on 2014. 7. 29..
//  Copyright (c) 2014년 IGAWorks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface ASPushInfo : NSObject

@property (nonatomic) NSDate* sentTime;
@property (nonatomic) NSString* bodyText;
@property (nonatomic) NSDictionary* customData;

@end



typedef void (^ASLocalNotificationCallback)(NSInteger Id, NSDate* sentTime, NSString* bodyText, NSDictionary* customData, BOOL isForeGround);
typedef void (^ASRemoteNotificationCallback)(NSArray* pushInfos, BOOL isForeGround);



@interface ASPush : NSObject

+ (void)initPush;
+ (void)setDeviceToken:(NSData*)deviceToken;

+ (void)handleAllNotificationFromLaunch:(NSDictionary*)launchOptions;
+ (void)handleLocalNotification:(UILocalNotification *)notification;
+ (void)handleRemoteNotification:(NSDictionary *)userInfo fetchHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

+ (void)setLocalNotificationListener:(ASLocalNotificationCallback)block;
+ (void)setRemoteNotificationListener:(ASRemoteNotificationCallback)block;

+ (BOOL)getRemotePushEnable;
+ (void)setRemotePushEnable:(BOOL)isEnabled;

+ (void)registerLocalPushNotification:(NSInteger)Id date:(NSDate*)date body:(NSString*)bodyText button:(NSString*)buttonText soundName:(NSString*)sound badgeNumber:(NSInteger)badgeNum userInfo:(NSDictionary*)userInfoDict;
+ (void)cancelLocalPush:(NSInteger)Id;

@end
