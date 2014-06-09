//
//  DAAdSize.m
//  IgaworksAd
//
//  Created by wonje,song on 2014. 4. 9..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import "DAAdSize.h"

@implementation DAAdSize


+ (CGSize)adSize:(DABannerViewSizeType)bannerViewSizeType
{
    CGSize size = CGSizeZero;
    switch (bannerViewSizeType)
    {
        case DABannerViewSize320x50:
            size = CGSizeMake(320.0f, 50.0f);
            break;
        default:
            break;
    }
    
    return size;
}

+ (CGSize)adRealSize:(DABannerViewRealSizeType)bannerViewRealSizeType
{
    CGSize size = CGSizeZero;
    switch (bannerViewRealSizeType)
    {
        case DABannerViewSizeIphonePotriat320x50:
            size = CGSizeMake(320.0f, 50.0f);
            break;
            
        case DABannerViewSizeIphoneLandscape480x32:
            size = CGSizeMake(480.0f, 32.0f);
            break;
            
        case DABannerViewSizeIphoneLandscape518x32:
            size = CGSizeMake(518.0f, 32.0f);
            break;
            
        default:
            break;
    }
    
    return size;
}

@end
