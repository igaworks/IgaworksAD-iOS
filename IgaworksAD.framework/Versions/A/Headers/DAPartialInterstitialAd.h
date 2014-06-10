//
//  DAPartialInterstitialAd.h
//  IgaworksAd
//
//  Created by wonje,song on 2014. 4. 22..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "DAError.h"
#import "IgaworksAD.h"

@protocol DAPartialInterstitialAdDelegate;

@interface DAPartialInterstitialAd : NSObject


@property (nonatomic, unsafe_unretained) id<DAPartialInterstitialAdDelegate> delegate;


- (id)initWithKey:(NSString *)mediaKey;


- (BOOL)presentFromViewController:(UIViewController *)viewController;

- (void)setLogLevel:(IgaworksADLogLevel)logLevel;


@end

@protocol DAPartialInterstitialAdDelegate <NSObject>

@optional
- (void)DAPartialInterstitialAdDidLoad:(DAPartialInterstitialAd *)partialInterstitialAd;

//- (void)daInterstitialAdDidLoad;

- (void)DAPartialInterstitialAd:(DAPartialInterstitialAd *)partialInterstitialAd didFailToReceiveAdWithError:(DAError *)error;

- (void)DAPartialInterstitialAdWillLeaveApplication:(DAPartialInterstitialAd *)partialInterstitialAd;

@end
