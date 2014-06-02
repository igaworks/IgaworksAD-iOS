//
//  AdPopcorn.h
//  IgaworksAd
//
//  Created by wonje,song on 2014. 3. 26..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@protocol AdPopcornDelegate;

/*!
 @typedef RewardServerType enum
 
 @abstract AdPopcorn reward를 사용자에게 지급하는 방식을 설정합니다.
 
 @discussion
 */
typedef enum _RewardServerType
{
    /*! 고객의 자체 서버를 사용하여, 콜백 URL로 관리  */
    AdPopcornRewardServerTypeServer,
    /*! 자체 서버가 없이, AdPopcorn 서버로 관리  */
    AdPopcornRewardServerTypeClient,
    /*! 자체 reward가 없이, AdPopcorn point를 reward로 사용하는 경우 */
} RewardServerType;


@interface AdPopcorn : NSObject
{

}


@property (nonatomic, unsafe_unretained) id<AdPopcornDelegate> delegate;


/*!
 @abstract
 singleton AdPopcorn 객체를 반환한다.
 */
+ (AdPopcorn *)shared;

/*!
 @abstract
 Open offerwall.
 
 @discussion
 리스트 형태의 광고를 노출한다.
 */
+ (void)openOfferWallWithViewController:(UIViewController *)vController userSerialNumber:(NSString *)userSerialNumber rewardServerType:(RewardServerType)rewardServerType delegate:(id)delegate userDataDictionaryForFilter:(NSMutableDictionary *)userDataDictionaryForFilter;

@end


@protocol AdPopcornDelegate <NSObject>

@optional

/*!
 @abstract
 offerwall 리스트가 열리기 전에 호출된다.
 
 @discussion
 */
- (void)willOpenOfferWall;

/*!
 @abstract
 offerwall 리스트가 열린직 후 호출된다.
 
 @discussion
 */
- (void)didOpenOfferWall;


/*!
 @abstract
 offerwall 리스트가 닫히기 전에 호출된다.
 
 @discussion
 */
- (void)willCloseOfferWall;

/*!
 @abstract
 offerwall 리스트가 닫힌직 후 호출된다.
 
 @discussion
 */
- (void)didCloseOfferWall;

@end
