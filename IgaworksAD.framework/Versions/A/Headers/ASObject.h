//
//  ASObject.h
//  AppService
//
//  Created by 강기태 on 2014. 7. 9..
//  Copyright (c) 2014년 IGAWorks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ASSaveCallback)(NSError* error);

@interface ASObject : NSObject

@property (nonatomic, copy) NSString* objectId;
@property (nonatomic, copy) NSString* createdAt;
@property (nonatomic, copy) NSString* updatedAt;
@property (nonatomic, copy) NSString* collectionId;
@property (nonatomic, copy)  NSString* collectionName;
@property (nonatomic) NSMutableDictionary* jsonAttrs;

+ (instancetype)objectWithCollectionName:(NSString*)name;

- (instancetype)initWithCollectionName:(NSString*)name;

- (id)get:(NSString*)key;
- (id)objectForKeyedSubscript:(NSString*)key;

- (void)put:(id)object withKey:(NSString*)key;
- (void)setObject:(id)object forKeyedSubscript:(NSString*)key;

- (void)save:(ASSaveCallback)block;
- (void)delete:(ASSaveCallback)block;

@end
