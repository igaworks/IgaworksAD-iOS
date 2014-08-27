//
//  ASCore.h
//  AppService
//
//  Created by 강기태 on 2014. 7. 11..
//  Copyright (c) 2014년 IGAWorks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ASCore : NSObject

@property (nonatomic) NSString* adBrixAppKey;
//@property NSMutableDictionary* subclassMap;



+ (void)initAppServiceWithAppKey:(NSString*)adBrix_appKey;
//+ (void)initAppService:(NSString*)adBrix_appKey;

//+ (void)registerSubclass:(Class)subclass collectionName:(NSString*)name;

@end