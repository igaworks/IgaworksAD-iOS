//
//  AdPopcornStyle.h
//  IgaworksAd
//
//  Created by wonje,song on 2014. 5. 19..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// NSError codes for error domain.
typedef NS_ENUM(NSInteger, AdPopcornThemeColor)
{
    AdPopcornThemeBlueColor = 1,
    AdPopcornThemeRedColor = 2,
    AdPopcornThemeYellowColor = 3
};






@interface AdPopcornStyle : NSObject

@property (nonatomic, unsafe_unretained) AdPopcornThemeColor adPopcornThemeColor;
@property (nonatomic, unsafe_unretained) AdPopcornThemeColor adPopcornTextThemeColor;
@property (nonatomic, unsafe_unretained) AdPopcornThemeColor adPopcornRewardThemeColor;
@property (nonatomic, unsafe_unretained) AdPopcornThemeColor adPopcornRewardCheckThemeColor;

@property (nonatomic, unsafe_unretained) UIColor *adPopcornCustomThemeColor;
@property (nonatomic, unsafe_unretained) UIColor *adPopcornCustomTextThemeColor;
@property (nonatomic, unsafe_unretained) UIColor *adPopcornCustomRewardThemeColor;
@property (nonatomic, unsafe_unretained) UIColor *adPopcornCustomRewardCheckThemeColor;

@property (nonatomic, copy) NSString *adPopcornOfferWallTitle;

+ (AdPopcornStyle *)sharedInstance;

@end
