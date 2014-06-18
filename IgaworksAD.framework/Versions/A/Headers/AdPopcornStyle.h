//
//  AdPopcornStyle.h
//  IgaworksAd
//
//  Created by wonje,song on 2014. 5. 19..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// NSError codes for GAD error domain.
typedef NS_ENUM(NSInteger, AdPopcornThemeColor)
{
    AdPopcornThemeBlueColor = 1,
    AdPopcornThemeRedColor = 2,
    AdPopcornThemeYellowColor = 3
};

typedef NS_ENUM(NSInteger, AdPopcornTextThemeColor)
{
    AdPopcornTextThemeBlueColor = 1,
    AdPopcornTextThemeRedColor = 2,
    AdPopcornTextThemeYellowColor = 3
};

typedef NS_ENUM(NSInteger, AdPopcornRewardThemeColor)
{
    AdPopcornRewardThemeBlueColor = 1,
    AdPopcornRewardThemeRedColor = 2,
    AdPopcornRewardThemeYellowColor = 3
};

typedef NS_ENUM(NSInteger, AdPopcornRewardCheckThemeColor)
{
    AdPopcornRewardCheckThemeBlueColor = 1,
    AdPopcornRewardCheckThemeRedColor = 2,
    AdPopcornRewardCheckThemeYellowColor = 3
};


@interface AdPopcornStyle : NSObject

@property (nonatomic, unsafe_unretained) AdPopcornThemeColor adPopcornThemeColor;
@property (nonatomic, unsafe_unretained) AdPopcornTextThemeColor adPopcornTextThemeColor;
@property (nonatomic, unsafe_unretained) AdPopcornRewardThemeColor adPopcornRewardThemeColor;
@property (nonatomic, unsafe_unretained) AdPopcornRewardCheckThemeColor adPopcornRewardCheckThemeColor;

@property (nonatomic, unsafe_unretained) UIColor *adPopcornCustomThemeColor;
@property (nonatomic, unsafe_unretained) UIColor *adPopcornCustomTextThemeColor;
@property (nonatomic, unsafe_unretained) UIColor *adPopcornCustomRewardThemeColor;
@property (nonatomic, unsafe_unretained) UIColor *adPopcornCustomRewardCheckThemeColor;

+ (AdPopcornStyle *)sharedInstance;

@end
