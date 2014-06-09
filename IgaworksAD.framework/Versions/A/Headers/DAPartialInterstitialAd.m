//
//  DAPartialInterstitialAd.m
//  IgaworksAd
//
//  Created by wonje,song on 2014. 4. 22..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import "DAPartialInterstitialAd.h"

#import "DAConstant.h"

#import "DADemo.h"

#import "IgaworksADUtil.h"
#import "NSString+IgaworksADBase64Additions.h"
#import "IgaworksADGetPUID.h"

#import "UIImageView+IgaworksADAFNetworking.h"

#import "DAPartialInterstitialViewController.h"

#import "DAService.h"
#import "DAAdapter.h"

#import "AdPopcornLog.h"

// Set Logging Component
#undef AdPopcornLogComponent
#define AdPopcornLogComponent lcl_cAdPopcorn

static inline NSString * DAErrorString(DAErrorCode code)
{
    switch (code)
    {
        case DAException:
            return @"Exception";
        case DAInvalidParameter:
            return @"Invalid parameter";
        case DAUnknownServerError:
            return @"Unknown Server Error";
        case DAInvalidMediaKey:
            return @"Invalid media key";
        case DAEmptyCampaign:
            return @"Empty Campaign";
        case DAServerTimeout:
            return @"Server timeout";
        case DALoadAdFailed:
            return @"Load ad failed";
        case DANoAd:
            return @"No ad";
            
        default: {
            return @"Success";
        }
    }
}

@interface DAPartialInterstitialAd () <DAServiceDelegate, DAPartialInterstitialViewControllerDelegate>
{
    NSString *_mediaKey;
    
    UIStoryboard *_daStoryboard;
    DAPartialInterstitialViewController *_daPartialInterstitialViewController;
    
    NSString *_redirectURL;
    UIInterfaceOrientation _orientation;
    
    BOOL _isPartialInterstitialAdViewPresented;
    
    NSInteger _age;
    DAGender _gender;
    
    double _latitude;
    double _longitude;
    double _accuracyInMeters;
    
    NSString *_impressionUrl;
    
    BOOL _isUseNavigationBar;
    UIViewController *_viewController;
}

- (void)loadAdByServer;
- (void)orientationChanged:(NSNotification *)notification;
- (void)loadImage:(NSString *)imageURL redirectURL:(NSString *)redirectURL impressionURL:(NSString *)impressionURL;

- (void)getConfig;
- (void)getPartialInterstitialCampaign;

@end

@implementation DAPartialInterstitialAd
@synthesize delegate = _delegate;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithKey:(NSString *)mediaKey
{
    self = [super init];
    if (self)
    {
        _mediaKey = mediaKey;
        
        // demo
        _age = [DADemo sharedInstance].age;
        _gender = [DADemo sharedInstance].gender;
        if (_gender == 0)
        {
            _gender = DAGenderUnknown;
        }
        
        _latitude = [DADemo sharedInstance].latitude;
        _longitude = [DADemo sharedInstance].longitude;
        
        
        
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (UIInterfaceOrientationIsPortrait(orientation))
        {
            _orientation = UIInterfaceOrientationPortrait;
        }
        else if (UIInterfaceOrientationIsLandscape(orientation))
        {
            _orientation = UIInterfaceOrientationLandscapeLeft;
        }
        
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
        
        
        [self getConfig];
        
        /*
        if (![DAService sharedInstance].daGetConfigResult.isResult)
        {
            [self getConfig];
        }
        else
        {
            [self getConfigDidComplete];
        }
         */
        
        
        
//        [self getPartialInterstitialCampaign:[UIApplication sharedApplication].statusBarOrientation];
    }
    
    return self;
}


#pragma mark - public
- (BOOL)presentFromViewController:(UIViewController *)viewController
{
    _viewController = viewController;
    
    _isUseNavigationBar = !_viewController.navigationController.isNavigationBarHidden;
    
    if (_isUseNavigationBar)
    {
        _viewController.navigationController.navigationBarHidden = YES;
    }
    
    if (!_isPartialInterstitialAdViewPresented)
    {
        _daPartialInterstitialViewController.view.alpha = 0.0f;
        [_viewController.view addSubview:_daPartialInterstitialViewController.view];
        
        _isPartialInterstitialAdViewPresented = YES;
        
        
        [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
            _daPartialInterstitialViewController.view.alpha = 1.0f;
        } completion:^(BOOL finished){

        }];
    }
    
    
    // call impressions
    if (_impressionUrl.length != 0)
    {
        [[DAService sharedInstance] impression:_impressionUrl];
    }
    
    
    return YES;
}


#pragma mark - private
- (void)getConfig
{
    [DAService sharedInstance].delegate = self;
    NSDictionary *parameterDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   _mediaKey, @"mediaKey",
                                   @"", @"bannerMediationKey",
                                   @"", @"interstitialMediationKey",
                                   [[IgaworksADGetPUID shared] getAESHashedPUID], @"puid",
                                   @"", @"openUDID",
                                   [IgaworksADUtil IDFA], @"iosIDFA",
                                   [IgaworksADUtil IDFV], @"iosIDFV",
                                   @"", @"androidID",
                                   @"", @"androidAdvertisingID",
                                   kDASDKVersion, @"sdkVersion",
                                   [IgaworksADUtil platformString], @"model",
                                   kDAiOSPlatformType, @"platformType",
                                   [NSString stringWithFormat:@"i_%@", [UIDevice currentDevice].systemVersion], @"osVersion",
                                   [IgaworksADUtil isPhone] ? @"phone" : @"tablet", @"deviceType",
                                   @"appstore", @"vendor",
                                   [IgaworksADUtil carrier], @"carrier",
                                   [IgaworksADUtil screenHeight], @"height",
                                   [IgaworksADUtil screenWidth], @"width",
                                   [IgaworksADUtil orientation], @"orientation",
                                   [NSString stringWithFormat:@"%lf", _latitude], @"latitude",
                                   [NSString stringWithFormat:@"%lf", _longitude], @"longitude",
                                   [NSNumber numberWithInteger:_age], @"age",
                                   [NSNumber numberWithInteger:_gender], @"gender",
                                   [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode], @"country",
                                   [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode], @"language",
                                   nil];
    
    
    AdPopcornLogTrace(@"parameterDict : %@", parameterDict);
    
    [[DAService sharedInstance] getConfig:[NSDictionary dictionaryWithObjectsAndKeys:
                           [NSString igaworksAD_base64EncodedString:[IgaworksADUtil queryString:parameterDict]], @"qrstr",
                           nil]];
}

- (void)getPartialInterstitialCampaign
{
    [DAService sharedInstance].delegate = self;
    NSDictionary *parameterDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   _mediaKey, @"mediaKey",
                                   [[IgaworksADGetPUID shared] getAESHashedPUID], @"puid",
                                   @"", @"openUDID",
                                   [IgaworksADUtil IDFA], @"iosIDFA",
                                   [IgaworksADUtil IDFV], @"iosIDFV",
                                   @"", @"androidID",
                                   @"", @"androidAdvertisingID",
                                   kDASDKVersion, @"sdkVersion",
                                   [IgaworksADUtil platformString], @"model",
                                   kDAiOSPlatformType, @"platformType",
                                   [NSString stringWithFormat:@"i_%@", [UIDevice currentDevice].systemVersion], @"osVersion",
                                   [IgaworksADUtil isPhone] ? @"phone" : @"tablet", @"deviceType",
                                   @"appstore", @"vendor",
                                   [IgaworksADUtil carrier], @"carrier",
                                   [IgaworksADUtil screenHeight], @"height",
                                   [IgaworksADUtil screenWidth], @"width",
                                   [IgaworksADUtil orientation], @"orientation",
                                   [NSString stringWithFormat:@"%lf", _latitude], @"latitude",
                                   [NSString stringWithFormat:@"%lf", _longitude], @"longitude",
                                   [NSNumber numberWithInteger:_age], @"age",
                                   [NSNumber numberWithInteger:_gender], @"gender",
                                   [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode], @"country",
                                   [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode], @"language",
                                   nil];
    
    AdPopcornLogTrace(@"parameterDict : %@", parameterDict);
    
    
    [[DAService sharedInstance] getPartialInterstitialCampaign:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSString igaworksAD_base64EncodedString:[IgaworksADUtil queryString:parameterDict]], @"qrstr", nil]];
    
}

- (void)loadAdByServer
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (!_isPartialInterstitialAdViewPresented)
        {
            _daStoryboard = [UIStoryboard storyboardWithName:[NSString stringWithFormat:@"%@.bundle/%@", kBundleFileNameForDA, @"DAStoryboardAutoLayoutForIphone"] bundle:nil];
            
//            _daStoryboard = [UIStoryboard storyboardWithName:@"DAStoryboardAutoLayoutForIphone" bundle:nil];
            
            _daPartialInterstitialViewController = [_daStoryboard instantiateViewControllerWithIdentifier:@"DAPartialInterstitialView"];
            _daPartialInterstitialViewController.delegate = self;
        }
    }
    else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        
        
    }
        
    
    NSString *imageURL = nil;
    DAGetPartialInterstitialCampaignCampaign *campaign = [[DAService sharedInstance].daGetPartialInterstitialCampaignResult.campaignListArray firstObject];
    
    for (DAGetPartialInterstitialCampaignCampaignImage *image in campaign.imageListArray)
    {
        if ([IgaworksADUtil isPhone])
        {
            imageURL = image.imageURL;
            break;
            /*
             if (image.width == kDAIphoneBannerSizeWidth && image.height == kDAIphoneBannerSizeHeight)
             {
             imageURL = image.imageURL;
             break;
             }
             */
        }
    }
    
    
    if (imageURL != nil)
    {
        [self loadImage:imageURL redirectURL:campaign.redirectURL impressionURL:campaign.impressionURL];
    }
}

- (void)orientationChanged:(NSNotification *)notification
{
    if (_isPartialInterstitialAdViewPresented)
    {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        
        if (UIInterfaceOrientationIsPortrait(orientation) && _orientation != UIInterfaceOrientationPortrait)
        {
            [self getPartialInterstitialCampaign];
            _orientation = UIInterfaceOrientationPortrait;
        }
        else if (UIInterfaceOrientationIsLandscape(orientation) && _orientation != UIInterfaceOrientationLandscapeLeft)
        {
            [self getPartialInterstitialCampaign];
            _orientation = UIInterfaceOrientationLandscapeLeft;
        }
    }
}

- (void)loadImage:(NSString *)imageURL redirectURL:(NSString *)redirectURL impressionURL:(NSString *)impressionURL
{
    UIImageView *imageView = [[UIImageView alloc] init];
    _redirectURL = redirectURL;
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:imageURL]];
    
    _impressionUrl = impressionURL;
    
    [imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
     {
         _daPartialInterstitialViewController.adImage = image;
         _daPartialInterstitialViewController.redirectURL = _redirectURL;
         
         
         // call impression
         //                 [_daService impression:campaign.impressionURL];
         
         if (_isPartialInterstitialAdViewPresented)
         {
             [_daPartialInterstitialViewController updateImage:image interfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
         }
         
         AdPopcornLogTrace(@"_delegate : %@", _delegate);
         
         
         if ([_delegate respondsToSelector:@selector(DAPartialInterstitialAdDidLoad:)])
         {
             [_delegate DAPartialInterstitialAdDidLoad:self];
         }
     }
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
     {
         if ([_delegate respondsToSelector:@selector(DAPartialInterstitialAd:didFailToReceiveAdWithError:)])
         {
             [_delegate DAPartialInterstitialAd:self didFailToReceiveAdWithError:[DAError errorWithDomain:kDAErrorDomain code:DALoadAdFailed userInfo:[NSDictionary dictionaryWithObjectsAndKeys:DAErrorString(DALoadAdFailed), NSLocalizedDescriptionKey, nil]]];
         }
     }];
}


#pragma mark - DAServiceDelegate
- (void)getConfigDidComplete
{
    if ([DAService sharedInstance].daGetConfigResult.isResult)
    {
        [self getPartialInterstitialCampaign];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"DA" message:[DAService sharedInstance].daGetConfigResult.resultMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
        [alertView show];
    }
}

- (void)getPartialInterstitialCampaignDidComplete
{
    if ([DAService sharedInstance].daGetPartialInterstitialCampaignResult.isResult)
    {
        [self loadAdByServer];
    }
    else
    {
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"DA" message:[DAService sharedInstance].daGetPartialInterstitialCampaignResult.resultMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
//        [alertView show];
        
        [_daPartialInterstitialViewController close:nil];
        
        if ([_delegate respondsToSelector:@selector(DAPartialInterstitialAd:didFailToReceiveAdWithError:)])
        {
            [_delegate DAPartialInterstitialAd:self didFailToReceiveAdWithError:[DAError errorWithDomain:kDAErrorDomain code:[DAService sharedInstance].daGetPartialInterstitialCampaignResult.isResult userInfo:[NSDictionary dictionaryWithObjectsAndKeys:DAErrorString([DAService sharedInstance].daGetPartialInterstitialCampaignResult.isResult), NSLocalizedDescriptionKey, nil]]];
        }
    }
}

- (void)getPatialInterstitialCampaignFailedWithError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(DAPartialInterstitialAd:didFailToReceiveAdWithError:)])
    {
        [_delegate DAPartialInterstitialAd:self didFailToReceiveAdWithError:[DAError errorWithDomain:kDAErrorDomain code:DAServerTimeout userInfo:[NSDictionary dictionaryWithObjectsAndKeys:DAErrorString(DAServerTimeout), NSLocalizedDescriptionKey, nil]]];
    }
}

#pragma mark - DAPartialInterstitialViewControllerDelegate
- (void)didClose
{
    _isPartialInterstitialAdViewPresented = NO;
    
    if (_isUseNavigationBar)
    {
        _viewController.navigationController.navigationBarHidden = NO;
    }
}

- (void)didTap
{
    if ([_delegate respondsToSelector:@selector(DAPartialInterstitialAdWillLeaveApplication:)])
    {
        [_delegate DAPartialInterstitialAdWillLeaveApplication:self];
    }
}

@end
