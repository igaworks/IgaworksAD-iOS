//
//  DAInterstitialView.m
//  IgaworksAd
//
//  Created by wonje,song on 2014. 4. 14..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import "DAInterstitialAd.h"

#import "DAConstant.h"

#import "IgaworksADUtil.h"
#import "NSString+IgaworksADBase64Additions.h"
#import "IgaworksADGetPUID.h"

#import "DADemo.h"

#import "DAService.h"

#import "UIImageView+IgaworksADAFNetworking.h"

#import "DAInterstitialViewController.h"

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

@interface DAInterstitialAd () <DAServiceDelegate, DAInterstitialViewControllerDelegate, DaAdapterDelegate>
{
    NSMutableDictionary *_adapterInstanceDictionary;
    
    DAMediation _loadToMediation;
    
    id _adapterInstance;
    
    NSInteger _refreshRate;
    
    NSString *_mediaKey;
    NSString *_mediationKey;
    
    
    DAInterstitialViewController *_daInterstitialViewController;
    
    UIStoryboard *_daStoryboard;
    
    BOOL _isInterstitialAdViewPresented;
    
    
    NSString *_adNetworkName;
    
    UIViewController *_viewController;
    
    NSInteger _adNetworkFaildCount;
    
    NSInteger _age;
    DAGender _gender;
    
    double _latitude;
    double _longitude;
    double _accuracyInMeters;
    
    NSString *_impressionUrl;
    
    BOOL _isServerType;
    
}

@property (nonatomic, strong) UIImageView *adImageView;

- (id)initMediaitonAdapter:(DAInterstitialMediationSchedule * )schedule;
- (void)loadAd;
- (void)loadAdByServer;
- (void)loadAdByClientMediation;

- (void)loadImage:(NSString *)imageURL redirectURL:(NSString *)redirectURL impressionURL:(NSString *)impressionURL;

- (void)getConfig;
- (void)getInterstitialCampaign;
- (void)interstitialMediationTracking:(ClientMediationTrackingType)type;
- (void)nextAdNetowrk;

- (DAInterstitialMediationSchedule *)getSchedule:(NSString *)adNetworkName;

- (void)refreshAd;

@end

@implementation DAInterstitialAd

@synthesize delegate = _delegate;
@synthesize interstitialAdIsVisible = _interstitialAdIsVisible;

@synthesize adImageView = _adImageView;


- (id)initWithKey:(NSString *)mediaKey mediationKey:(NSString *)mediationKey viewController:(UIViewController *)viewController
{
    NSAssert(mediaKey != nil, @"'Media key provided must not be nil'");
    NSAssert(viewController != nil, @"'View Controller provided must not be nil or some other object'");
    
    if (mediaKey == nil)
    {
        AdPopcornLogError(@"'Media key provided must not be nil'");
    }
    
    if (viewController == nil)
    {
        AdPopcornLogError(@"'View Controller provided must not be nil or some other object'");
    }
    
    if (mediationKey == nil)
    {
        mediationKey = @"";
    }
    
    self = [super init];
    if (self)
    {
        _mediaKey = mediaKey;
        _mediationKey = mediationKey;
        _viewController = viewController;
        
        // demo
        _age = [DADemo sharedInstance].age;
        _gender = [DADemo sharedInstance].gender;
        if (_gender == 0)
        {
            _gender = DAGenderUnknown;
        }
        
        _latitude = [DADemo sharedInstance].latitude;
        _longitude = [DADemo sharedInstance].longitude;
        
        // adapter
        _adapterInstanceDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
        
        /*
        if (![DAService sharedInstance].daGetConfigResult.isResult)
        {
            [self getConfig];
        }
        else
        {
            [self getConfigDidComplete];
            
//            _loadToMediation = 0;
//            [self loadAd];
        }
         */
        
        [self getConfig];
        
        
        
//        [self getInterstitialCampaign:[UIApplication sharedApplication].statusBarOrientation];
        
    }
    
    return self;
}

/*
- (BOOL)presentInView:(UIView *)view
{
    [view addSubview:_daInterstitialViewController.view];
    _isInterstitialAdViewPresented = YES;
    
    return YES;
}
 */


/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

#pragma mark - public
- (BOOL)presentFromViewController:(UIViewController *)viewController
{
    // server type인 경우만,
    
    if (_isServerType)
    {
        if (!_isInterstitialAdViewPresented)
        {
            [viewController presentViewController:_daInterstitialViewController animated:YES completion:^(void){
                
                // call impressions
                if (_impressionUrl.length != 0)
                {
                    [[DAService sharedInstance] impression:_impressionUrl];
                }
                
                
                _isInterstitialAdViewPresented = YES;
            }];
        }
        else
        {
            // call impressions
            if (_impressionUrl.length != 0)
            {
                [[DAService sharedInstance] impression:_impressionUrl];
            }
        }
    }
    
    return YES;
}

// for test
- (void)refreshAd
{
    [_viewController dismissViewControllerAnimated:YES completion:NULL];
    
    [self loadAd];
}

#pragma mark - private
- (id)initMediaitonAdapter:(DAInterstitialMediationSchedule *)schedule
{
    Class adapterClass = nil;
    id adapterInstance = nil;
    
    
    switch ([[DAService sharedInstance] mediation:schedule.adNetworkName])
    {
        case DAMediationIAd:
        {
            adapterClass = NSClassFromString(kDAMediationAdapterIAd);
            break;
        }
            
        case DAMediationAdMob:
        {
            adapterClass = NSClassFromString(kDAMediationAdapterAdMob);
            break;
        }
            
        case DAMediationAdam:
        {
            adapterClass = NSClassFromString(kDAMediationAdapterAdam);
            break;
        }
            
        case DAMediationCauly:
        {
            adapterClass = NSClassFromString(kDAMediationAdapterCauly);
            break;
        }
            
        case DAMediationAdPost:
        {
            adapterClass = NSClassFromString(kDAMediationAdapterAdPost);
            break;
        }
            
        case DAMediationShallWeAd:
        {
            adapterClass = NSClassFromString(kDAMediationAdapterShallWeAd);
            break;
        }
            
        case DAMediationTAd:
        {
            adapterClass = NSClassFromString(kDAMediationAdapterTAd);
            break;
        }
            
        case DAMediationAdHub:
        {
            adapterClass = NSClassFromString(kDAMediationAdapterAdHub);
            break;
        }
            
        case DAMediationInmobi:
        {
            adapterClass = NSClassFromString(kDAMediationAdapterInmobi);
            break;
        }
            
        case DAMediationMMedia:
        {
            adapterClass = NSClassFromString(kDAMediationAdapterMMedia);
            break;
        }
            
        default:
            break;
    }
    
    if (adapterClass)
    {
        SEL sharedInstanceSelector = NSSelectorFromString(@"sharedInstance");
        adapterInstance = ((id (*)(id, SEL))[adapterClass methodForSelector:sharedInstanceSelector])(adapterClass, sharedInstanceSelector);
        
        
        AdPopcornLogTrace(@"adapterInstance : %@", adapterInstance);
        
        
        // isSupportInterstitialAd
        if ([adapterInstance respondsToSelector:@selector(isSupportInterstitialAd)])
        {
            if (![adapterInstance isSupportInterstitialAd])
            {
                AdPopcornLogTrace(@"%@ is not support interstitial ad", schedule.adNetworkName);
                adapterInstance = nil;
            }
            else
            {
                // set integrationKey
                if ([adapterInstance respondsToSelector:@selector(setIntegrationKey:)])
                {
                    [adapterInstance setIntegrationKey:schedule.integrationKey];
                }
                
                if ([adapterInstance respondsToSelector:@selector(setViewController:)])
                {
                    [adapterInstance setViewController:_viewController];
                }
            }
        }
    }
    
    return adapterInstance;
}


- (void)loadAd
{
    // call to server
    // server mediation이면,
    if ([DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray.count > 0)
    {
        DAInterstitialMediationSchedule *schedule = [[DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray objectAtIndex:_loadToMediation % [DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray.count];
        
        AdPopcornLogInfo(@"=====> adNetworkName : %@, %ld, %d", schedule.adNetworkName, (long)schedule.integrationType, _loadToMediation % [DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray.count);
        
        _adNetworkName = schedule.adNetworkName;
        
        // for test
        if (NO)
        {

/*
        if (
            [_adNetworkName isEqualToString:kDAMediationAdHub] ||
//            [_adNetworkName isEqualToString:kDAMediationIGAW] ||
            [_adNetworkName isEqualToString:kDAMediationInmobi] ||
            [_adNetworkName isEqualToString:kDAMediationCauly] ||
            [_adNetworkName isEqualToString:kDAMediationAdMob] ||
            [_adNetworkName isEqualToString:kDAMediationTAd] ||
            [_adNetworkName isEqualToString:kDAMediationIAd] ||
            [_adNetworkName isEqualToString:kDAMediationAdam] ||
            [_adNetworkName isEqualToString:kDAMediationShallWeAd] ||
            [_adNetworkName isEqualToString:kDAMediationAdPost] ||
            [_adNetworkName isEqualToString:kDAMediationAppLift] ||
            [_adNetworkName isEqualToString:kDAMediationMMedia]
            )
        {

            [self nextAdNetowrk];
 */
        }
        else
        {
            AdPopcornLogTrace(@"_adNetworkName : %@, schedule.integrationType : %d", _adNetworkName,  schedule.integrationType);
            ;
            if (schedule.integrationType == DAMediationIntegrationServerType)
            {
                [self getInterstitialCampaign];
            }
            else if (schedule.integrationType == DAMediationIntegrationClientType)
            {
                [self loadAdByClientMediation];
            }
        }
    }
    else
    {
        _adNetworkName = kDAMediationIGAW;
        
        [self getInterstitialCampaign];
    }
}

- (void)loadAdByServer
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (!_isInterstitialAdViewPresented)
        {
            _daStoryboard = [UIStoryboard storyboardWithName:[NSString stringWithFormat:@"%@.bundle/%@", kBundleFileNameForDA, @"DAStoryboardAutoLayoutForIphone"] bundle:nil];
            
//            _daStoryboard = [UIStoryboard storyboardWithName:@"DAStoryboardAutoLayoutForIphone" bundle:nil];
            
            _daInterstitialViewController = [_daStoryboard instantiateViewControllerWithIdentifier:@"DAInterstitialView"];
            _daInterstitialViewController.delegate = self;
        }
        
        NSString *imageURL = nil;
        DAGetInterstitialCampaignCampaign *campaign = [[DAService sharedInstance].daGetInterstitialCampaignResult.campaignListArray firstObject];
            
            
//            DAInterstitialMediationSchedule *schedule = [self getSchedule:campaign.adNetworkName];
            
        _daInterstitialViewController.campaign = campaign;
        if (campaign.isWebContent)
        {
            _adNetworkFaildCount = 0;
            _isServerType = YES;
            
            if ([_delegate respondsToSelector:@selector(DAInterstitialAdDidLoad:)])
            {
                [_delegate DAInterstitialAdDidLoad:self];
            }
        }
        else
        {
            for (DAGetInterstitialCampaignCampaignImage *image in campaign.imageListArray)
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
            
    }
    else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
            
    }
}

- (void)loadAdByClientMediation
{
    _adapterInstance = [_adapterInstanceDictionary valueForKey:_adNetworkName];
    AdPopcornLogTrace(@"_adapterInstance : %@", _adapterInstance);
    
    
    if (_adapterInstance != nil)
    {
        // set delegate
//        SEL setDelegateSelector = NSSelectorFromString(@"setDelegate:");
//        IMP theImplementation = [_adapterInstance methodForSelector:setDelegateSelector];
//        theImplementation(_adapterInstance, setDelegateSelector, self);
        
        if ([_adapterInstance respondsToSelector:@selector(setDelegate:)])
        {
            [_adapterInstance setDelegate:self];
        }
        
        if ([_adapterInstance respondsToSelector:@selector(loadAd)])
        {
            
            // interstitialMediationTracking : request
            [self interstitialMediationTracking:ClientMediationTrackingRequestType];
            
            [_adapterInstance loadAd];
        }
    }
    else
    {
        AdPopcornLogInfo(@"%@ adapter is not exist.", _adNetworkName);
        
        [self nextAdNetowrk];
    }
}

- (void)getConfig
{
    [DAService sharedInstance].delegate = self;
    NSDictionary *parameterDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                       _mediaKey, @"mediaKey",
                                       @"", @"bannerMediationKey",
                                       _mediationKey, @"interstitialMediationKey",
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
                                       //                                       uaString, @"userAgent",
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

- (void)getInterstitialCampaign
{
    [DAService sharedInstance].delegate = self;
    NSDictionary *parameterDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   _mediaKey, @"mediaKey",
                                   @"", @"bannerMediationKey",
                                   _mediationKey, @"interstitialMediationKey",
                                   _adNetworkName == nil ? @"" : _adNetworkName, @"adNetworkName",
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
                                   @"false", @"isWebContent",
                                   nil];
    
    AdPopcornLogTrace(@"parameterDict : %@", parameterDict);
    
    
    [[DAService sharedInstance] getInterstitialCampaign:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSString igaworksAD_base64EncodedString:[IgaworksADUtil queryString:parameterDict]], @"qrstr", nil]];

}

- (void)interstitialMediationTracking:(ClientMediationTrackingType)type
{
    [DAService sharedInstance].delegate = self;
    NSDictionary *parameterDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   _mediaKey, @"mediaKey",
                                   @"", @"bannerMediationKey",
                                   _mediationKey, @"interstitialMediationKey",
                                   _adNetworkName == nil ? @"" : _adNetworkName, @"adNetworkName",
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
                                   @"false", @"isWebContent",
                                   [NSNumber numberWithInteger:type], @"trackingTypeCode",
                                   nil];
    
    AdPopcornLogTrace(@"parameterDict : %@", parameterDict);
    
    
    [[DAService sharedInstance] interstitialMediationTracking:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSString igaworksAD_base64EncodedString:[IgaworksADUtil queryString:parameterDict]], @"qrstr", nil]];
}


- (void)loadImage:(NSString *)imageURL redirectURL:(NSString *)redirectURL impressionURL:(NSString *)impressionURL
{
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:imageURL]];
    
    _impressionUrl = impressionURL;
    
    [imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
     {
         _adNetworkFaildCount = 0;
         
         _daInterstitialViewController.adImage = image;
         _daInterstitialViewController.redirectURL = redirectURL;

         
         if (_isInterstitialAdViewPresented)
         {
             [_daInterstitialViewController updateImage:image interfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
         }
         
         _isServerType = YES;
         
         if ([_delegate respondsToSelector:@selector(DAInterstitialAdDidLoad:)])
         {
             [_delegate DAInterstitialAdDidLoad:self];
         }
     }
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
     {
         if ([DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray.count > 0)
         {
             [self nextAdNetowrk];
         }
         else
         {
             if ([_delegate respondsToSelector:@selector(DAInterstitialAd:didFailToReceiveAdWithError:)])
             {
                 [_delegate DAInterstitialAd:self didFailToReceiveAdWithError:[DAError errorWithDomain:kDAErrorDomain code:DALoadAdFailed userInfo:[NSDictionary dictionaryWithObjectsAndKeys:DAErrorString(DALoadAdFailed), NSLocalizedDescriptionKey, nil]]];
             }
         }
     }];
}

- (void)nextAdNetowrk
{
    double delayInSeconds = 0.3f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        _adNetworkFaildCount++;
        
        _loadToMediation = (_loadToMediation + 1) % [DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray.count;
        
        
        AdPopcornLogTrace(@"_adNetworkFaildCount : %d, _mediationNameListArray.count : %d", _adNetworkFaildCount, [DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray.count);
        
        // check all ad network is faild
        if (_adNetworkFaildCount >= [DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray.count)
        {
            AdPopcornLogTrace(@"==> all ad network is faild :  _delegate : %@", _delegate);
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if ([_delegate respondsToSelector:@selector(DAInterstitialAd:didFailToReceiveAdWithError:)])
                {
                    [_delegate DAInterstitialAd:self didFailToReceiveAdWithError:[DAError errorWithDomain:kDAErrorDomain code:DANoAd userInfo:[NSDictionary dictionaryWithObjectsAndKeys:DAErrorString(DANoAd), NSLocalizedDescriptionKey, nil]]];
                }
                
                // close
                [_daInterstitialViewController close:nil];
            });
        }
        else
        {
            dispatch_sync(dispatch_get_main_queue(), ^(void){
                [self loadAd];
            });
        }
    });
}

- (DAInterstitialMediationSchedule *)getSchedule:(NSString *)adNetworkName
{
    DAInterstitialMediationSchedule *returnToSchedule = nil;
    
    for (DAInterstitialMediationSchedule *schedule in [DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray)
    {
        if ([schedule.adNetworkName isEqualToString:adNetworkName])
        {
            returnToSchedule = schedule;
        }
    }

    return returnToSchedule;
}


#pragma mark - DAServiceDelegate
- (void)getConfigDidComplete
{
    if ([DAService sharedInstance].daGetConfigResult.isResult)
    {
        // init client adapter for mediation
        for (DAInterstitialMediationSchedule *schedule in [DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray)
        {
            if (schedule.integrationType == DAMediationIntegrationClientType)
            {
                // init adapter
                id adapterInstance = [self initMediaitonAdapter:schedule];
                
                if (adapterInstance != nil)
                {
                    //                    [_adapterInstanceArray addObject:adapterInstance];
                    [_adapterInstanceDictionary setValue:adapterInstance forKey:schedule.adNetworkName];
                    
                }
            }
        }
        
        AdPopcornLogTrace(@"_adapterInstanceDictionary : %@", _adapterInstanceDictionary);
        
        
        
        // schedule
        // skip
        //    _loadToMediation = (_loadToMediation + 1) % _mediationListArray.count;
        // 무조건 첫번째 adnetwork로 시도.

        
        _loadToMediation = 0;
        
        [self loadAd];
        
    }
    else
    {
        // get config result == 0
        
        [self loadAd];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"DA" message:[DAService sharedInstance].daGetConfigResult.resultMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
        [alertView show];
    }
}

- (void)getConfigFailedWithError:(NSError *)error
{
    AdPopcornLogTrace(@"error : %@", error);
    
    [self loadAd];
}

- (void)getInterstitialCampaignDidComplete
{
    if ([DAService sharedInstance].daGetInterstitialCampaignResult.isResult)
    {
        [self loadAdByServer];
    }
    else
    {
        if ([DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray.count > 0)
        {
            [self nextAdNetowrk];
        }
        else
        {
            if ([_delegate respondsToSelector:@selector(DAInterstitialAd:didFailToReceiveAdWithError:)])
            {
                [_delegate DAInterstitialAd:self didFailToReceiveAdWithError:[DAError errorWithDomain:kDAErrorDomain code:[DAService sharedInstance].daGetInterstitialCampaignResult.isResult userInfo:[NSDictionary dictionaryWithObjectsAndKeys:DAErrorString([DAService sharedInstance].daGetInterstitialCampaignResult.isResult), NSLocalizedDescriptionKey, nil]]];
            }
        }
        
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"DA" message:[DAService sharedInstance].daGetInterstitialCampaignResult.resultMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
//        [alertView show];
    }
}


- (void)getInterstitialCampaignFailedWithError:(NSError *)error
{
    AdPopcornLogTrace(@"error : %@", error);
    
    if ([DAService sharedInstance].daGetConfigResult.interstitialMediationScheduleArray.count > 0)
    {
        [self nextAdNetowrk];
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(DAInterstitialAd:didFailToReceiveAdWithError:)])
        {
            [_delegate DAInterstitialAd:self didFailToReceiveAdWithError:[DAError errorWithDomain:kDAErrorDomain code:DAServerTimeout userInfo:[NSDictionary dictionaryWithObjectsAndKeys:DAErrorString(DAServerTimeout), NSLocalizedDescriptionKey, nil]]];
        }
    }
}

#pragma mark - DAInterstitialViewControllerDelegate
- (void)willChangeRotation:(UIInterfaceOrientation)toInterfaceOrientation
{
    AdPopcornLogTrace(@"toInterfaceOrientation : %d", toInterfaceOrientation);
    
    [self getInterstitialCampaign];
}

- (void)didClose
{
    _isInterstitialAdViewPresented = NO;
}

- (void)didTap
{
    if ([_delegate respondsToSelector:@selector(DAInterstitialAdWillLeaveApplication:)])
    {
        [_delegate DAInterstitialAdWillLeaveApplication:self];
    }
}

#pragma mark - DaAdapterDelegate
- (void)DAAdapterInterstitialAdDidLoadAd:(NSObject *)interstitialAd
{
    _adNetworkFaildCount = 0;
    
    _isServerType = NO;
    
    // interstitialMediationTracking : impression
    [self interstitialMediationTracking:ClientMediationTrackingImpressionType];
    
    if ([_delegate respondsToSelector:@selector(DAInterstitialAdDidLoad:)])
    {
        [_delegate DAInterstitialAdDidLoad:interstitialAd];
    }
    
}

- (void)DAAdapterInterstitial:(NSObject *)interstitialAd didFailToReceiveAdWithError:(NSError *)error
{
    AdPopcornLogTrace(@"error : %@", error);
    
    // interstitialMediationTracking : impression fail
    [self interstitialMediationTracking:ClientMediationTrackingImpressionFailType];
    
    [self nextAdNetowrk];
    
}

- (void)DAAdapterInterstitialWillLeaveApplication:(NSObject *)interstitialAd
{
    // interstitialMediationTracking : click
    [self interstitialMediationTracking:ClientMediationTrackingClickType];
    
    if ([_delegate respondsToSelector:@selector(DAInterstitialAdWillLeaveApplication:)])
    {
        [_delegate DAInterstitialAdWillLeaveApplication:interstitialAd];
    }
}


@end
