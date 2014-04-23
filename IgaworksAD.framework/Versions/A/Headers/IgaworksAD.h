//
//  IgaworksAD.h
//  IgaworksAD
//
//  Created by wonje,song on 2014. 3. 26..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol IgaworksADClientRewardDelegate;

typedef enum _gender
{
    IgaworksADGenderMale = 2,
    IgaworksADGenderFemale = 1
} Gender;

typedef enum _IgaworksADLogLevel
{
    /*! only info logging  */
    IgaworksADLogInfo,
    /*! info, debug logging  */
    IgaworksADLogDebug,
    /*! all logging */
    IgaworksADLogTrace
} IgaworksADLogLevel;

/*!
 @typedef RewardServerType enum
 
 @abstract reward를 사용자에게 지급하는 방식을 설정합니다.
 
 @discussion
 */
typedef enum _IgaworksADRewardServerType
{
    /*! 고객의 자체 서버를 사용하여, 콜백 URL로 관리  */
    IgaworksADRewardServerTypeServer,
    /*! 자체 서버가 없이, AdPopcorn 서버로 관리  */
    IgaworksADRewardServerTypeClient,
    /*! 자체 reward가 없이, AdPopcorn point를 reward로 사용하는 경우 */
} IgaworksADRewardServerType;
 

@interface IgaworksAD : NSObject

@property (nonatomic, readonly) NSString *appKey;
@property (nonatomic, readonly) NSString *hashKey;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, readonly) IgaworksADRewardServerType rewardServerType;

@property (nonatomic, unsafe_unretained) id<IgaworksADClientRewardDelegate> clientRewardDelegate;



/*!
 @abstract
 초기화. init한다. Singleton method
 
 @discussion
 발급 받은 appkey로 connect한다.
 
 @param appkey              app. 등록 후, IGAWorks로부터 발급된 키.
 @param hashkey             app. 등록 후 발급된 키.
 @param rewardServerType    reward를 사용자에게 지급하는 방식
 */
+ (id)igaworksADWithAppKey:(NSString *)appKey andHashKey:(NSString *)hashKey rewardServerType:(IgaworksADRewardServerType)rewardServerType;


/*!
 @abstract
 초기화. init한다.
 
 @discussion
 발급 받은 appkey로 connect한다.
 
 @param appkey              app. 등록 후, IGAWorks로부터 발급된 키.
 @param hashkey             app. 등록 후 발급된 키.
 @param rewardServerType    reward를 사용자에게 지급하는 방식
 */
- (id)initWithAppKey:(NSString *)appKey andHashKey:(NSString *)hashKey rewardServerType:(IgaworksADRewardServerType)rewardServerType;



/*!
 @abstract
 singleton IgaworksAD 객체를 반환한다.
 */
+ (IgaworksAD *)shared;

/*!
 @abstract
 로그를 level를 설정한다.
 
 @discussion
 보고자 하는 로그 level을 info, debug, trace으로 설정한다.
 
 @param LogLevel            log level
 */
+ (void)setLogLevel:(IgaworksADLogLevel)logLevel;

/*!
 @abstract
 사용자의 나이 정보를 전송하고자 할때 호출한다.
 
 @param age              age.
 */
+ (void)setAge:(int)age;

/*!
 @abstract
 사용자의 성별 정보를 전송하고자 할때 호출한다.
 
 @param gender              gender.
 */
+ (void)setGender:(Gender)gender;

/*!
 @abstract
 사용자의 user id를 전송하고자 할때 호출한다.
 
 @param userId              user id.
 */
+ (void)setUserId:(NSString *)userId;

@end

@protocol IgaworksADClientRewardDelegate <NSObject>

@optional

/*!
 @abstract
 사용자에게 지급할 아이템이 있을때 호출된다.
 
 @discussion
 사용자에게 아이템을 지급하고, 지급이 완료되면 didGiveRewardItemWithRewardKey 메소드를 호출하여 지급 완료 확정 처리를 한다.
 */
- (void)onRewardRequestResult:(BOOL)isSuccess withMessage:(NSString *)message itemName:(NSString *)itemName itemKey:(NSString*)itemKey campaignName:(NSString *)campaignName campaignKey:(NSString*)campaignKey rewardKey:(NSString *)rewardkey quantity:(NSUInteger)quantity;


/*!
 @abstract
 사용자에게 지급할 아이템이 있을때 호출된다. 아이템 리스트를 전달한다.
 
 @discussion
 사용자에게 아이템을 지급하고, 지급이 완료되면 didGiveRewardItemWithRewardKey 메소드를 호출하여 지급 완료 확정 처리를 한다.
 */
- (void)onRewardRequestResult:(BOOL)isSuccess withMessage:(NSString *)message items:(NSArray *)itemes;

/*!
 @abstract
 Reward 지급 확정 처리 콜백 메소드.
 
 @discussion
 didGiveRewardItemWithRewardKey 메소드에서 reward 지급 처리를 완료한 뒤에 IGAWorks에 요청한 결과가 이 곳으로 리턴된다. isSuccess가 YES가 리턴되어야 최종 reward 지급이 완료된다.
 */
- (void)onRewardCompleteResult:(BOOL)isSuccess withMessage:(NSString *)message resultCode:(NSUInteger)resultCode withCompletedRewardKey:(NSString *)completedRewardKey;

@end
