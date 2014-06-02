//
//  DAInterstitialView.h
//  IgaworksAd
//
//  Created by wonje,song on 2014. 4. 14..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DAService.h"

#import "DAError.h"

@protocol DAInterstitialAdDelegate;

@interface DAInterstitialAd : NSObject



@property (nonatomic, unsafe_unretained) id<DAInterstitialAdDelegate> delegate;
@property (nonatomic, unsafe_unretained, getter = isInterstitialAdIsVisible) BOOL interstitialAdIsVisible;

- (id)initWithKey:(NSString *)mediaKey mediationKey:(NSString *)mediationKey viewController:(UIViewController *)viewController;


//- (BOOL)presentInView:(UIView *)view;
- (BOOL)presentFromViewController:(UIViewController *)viewController;

- (void)refreshAd;


@end

@protocol DAInterstitialAdDelegate <NSObject>

- (void)DAInterstitialAd:(DAInterstitialAd *)interstitialAd didFailToReceiveAdWithError:(DAError *)error;

@optional
- (void)DAInterstitialAdDidLoad:(DAInterstitialAd *)interstitialAd;

- (void)DAInterstitialAdWillLeaveApplication:(DAInterstitialAd *)interstitialAd;

//- (void)daInterstitialAdDidLoad;


@end
