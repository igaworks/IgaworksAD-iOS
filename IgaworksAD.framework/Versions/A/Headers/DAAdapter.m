//
//  DAAdapter.m
//  IgaworksAd
//
//  Created by wonje,song on 2014. 4. 10..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import "DAAdapter.h"


@interface DAAdapter ()


@end


@implementation DAAdapter

@synthesize delegate = _delegate;


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        
    }
    
    return self;
}


+ (DAAdapter *)sharedInstance
{
    static DAAdapter *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[DAAdapter alloc] init];
    });
    
    return _sharedInstance;
}

- (void)setViewController:(UIViewController *)viewController origin:(CGPoint)origin size:(CGSize)size bannerView:(DABannerView *)bannerView
{
    
}

- (void)setViewController:(UIViewController *)viewController
{

}

- (void)loadAd
{
//    AdPopcornLogTrace(@"- (void)loadAd..");
}

- (void)closeAd
{

}

- (void)loadRequest
{

}


- (CGSize)adSize
{
    return CGSizeZero;
}

- (void)setAge:(NSInteger)age
{
    
}

- (void)setGender:(DAGender)gender
{

}



@end
