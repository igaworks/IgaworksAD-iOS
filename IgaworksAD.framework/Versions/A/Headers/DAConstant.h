//
//  DAConstant.h
//  IgaworksAd
//
//  Created by wonje,song on 2014. 4. 9..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kDALiveServerBaseURL;
extern NSString *const kDAStagingServerBaseURL;
extern NSString *const kDAGetConfigPath;
extern NSString *const kDAGetBannerCampaignPath;
extern NSString *const kDAGetInterstitialCampaignPath;
extern NSString *const kDAGetPopupCampaignPath;

extern NSString *const kDABannerMediationTrackingPath;
extern NSString *const kDAInterstitialMediationTrackingPath;

extern NSString *const kDAGetNativeAdvertisingPath;

extern NSInteger kDAHttpConnectionTimeoutSeconds;

extern NSString *const kDAiOSPlatformType;

extern NSInteger const kDAAdRefreshRate;
extern NSInteger const kDAMediationAdRefreshRate;

// mediation
extern NSString *const kDAMediationIGAW;
extern NSString *const kDAMediationIAd;
extern NSString *const kDAMediationAdMob;
extern NSString *const kDAMediationAdam;
extern NSString *const kDAMediationCauly;
extern NSString *const kDAMediationAdPost;
extern NSString *const kDAMediationTAd;
extern NSString *const kDAMediationInmobi;
extern NSString *const kDAMediationAppLift;
extern NSString *const kDAMediationMMedia;
extern NSString *const kDAMediationNendAd;
extern NSString *const kDAMediationIMobile;

// adapter
extern NSString *const kDAMediationAdapterIAd;
extern NSString *const kDAMediationAdapterAdMob;
extern NSString *const kDAMediationAdapterAdam;
extern NSString *const kDAMediationAdapterCauly;
extern NSString *const kDAMediationAdapterAdPost;
extern NSString *const kDAMediationAdapterTAd;
extern NSString *const kDAMediationAdapterInmobi;
extern NSString *const kDAMediationAdapterMMedia;
extern NSString *const kDAMediationAdapterNendAd;
extern NSString *const kDAMediationAdapterIMobile;

extern NSInteger const kDAIphoneBannerSizeWidth;
extern NSInteger const kDAIphoneBannerSizeHeight;

extern float const kDAIphoneEndingPartialInterstitialPotraitImageSizeWidth;
extern float const kDAIphoneEndingPartialInterstitialPotraitImageSizeHeight;

extern float const kDAIphoneEndingPartialInterstitialLandscapeImageSizeWidth;
extern float const kDAIphoneEndingPartialInterstitialLandscapeImageSizeHeight;

extern NSInteger const kDAIphoneEndingPartialInterstitialImageTagStartNumber;

// native ad
extern NSString *const kDANativeAdLayoutOfferwallType;
extern NSString *const kDANativeAdLayoutImageBoardType;
extern NSString *const kDANativeAdLayoutNewsFeedType;
extern NSString *const kDANativeAdLayoutContentsStreamType;

extern NSString* const kBundleFileNameForDA;

@interface DAConstant : NSObject

@end
