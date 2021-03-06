//
//  DAInterstitialView.h
//  IgaworksAd
//
//  Created by wonje,song on 2014. 4. 14..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAError.h"
#import "IgaworksAD.h"


@protocol DAInterstitialAdDelegate;

@interface DAInterstitialAd : NSObject


@property (nonatomic, unsafe_unretained) id<DAInterstitialAdDelegate> delegate;
@property (nonatomic, unsafe_unretained, getter = isInterstitialAdIsVisible) BOOL interstitialAdIsVisible;

- (instancetype)initWithKey:(NSString *)appKey spotKey:(NSString *)spotKey viewController:(UIViewController *)viewController NS_DESIGNATED_INITIALIZER;


- (BOOL)presentFromViewController:(UIViewController *)viewController;

- (void)setLogLevel:(IgaworksADLogLevel)logLevel;

- (void)showInterstitialAdForNendAd_IMobile;


@end

@protocol DAInterstitialAdDelegate <NSObject>

- (void)DAInterstitialAd:(DAInterstitialAd *)interstitialAd didFailToReceiveAdWithError:(DAError *)error;

@optional
- (void)DAInterstitialAdDidLoad:(DAInterstitialAd *)interstitialAd;

- (void)DAInterstitialAdWillLeaveApplication:(DAInterstitialAd *)interstitialAd;

//- (void)daInterstitialAdDidLoad;

- (void)willOpenDAInterstitialAd;
- (void)didOpenDAInterstitialAd;
- (void)willCloseDAInterstitialAd;
- (void)didCloseDAInterstitialAd;


@end
