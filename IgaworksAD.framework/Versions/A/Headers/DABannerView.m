//
//  DABannerView.m
//  IgaworksAd
//
//  Created by wonje,song on 2014. 4. 8..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import "DABannerView.h"

#import "DAAdapter.h"

#import "DAAdSize.h"
#import "DAService.h"

#import "DADemo.h"

#import "IgaworksADGetPUID.h"


#import "NSString+IgaworksADBase64Additions.h"

#import "UIImageView+IgaworksADAFNetworking.h"

#import "IgaworksADUtil.h"
#import "DAConstant.h"
#import "AdPopcornLog.h"




// Set Logging Component
#undef AdPopcornLogComponent
#define AdPopcornLogComponent lcl_cAdPopcorn

static inline NSString *DAErrorString(DAErrorCode code)
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

@interface DABannerView () <DAServiceDelegate, DaAdapterDelegate, UIWebViewDelegate>
{
    UIViewController *_viewController;
    NSMutableDictionary *_adapterInstanceDictionary;
    
    
    NSTimer *_scheduleTimer;
    NSInteger _loadToMediation;
    
    NSInteger _refreshRate;
    
    id _adapterInstance;
    
    id _lastAdapterInstance;
    
    CGPoint _origin;
    CGSize _size;
    
    NSString *_mediaKey;
    NSString *_mediationKey;
    
    
    UIView *_containerView;
    UIImageView *_adImageView;
    UIWebView *_webView;
    
    NSString *_webData;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
    NSString *_redirectURL;
    
    NSInteger _adNetworkFaildCount;
    
    NSString *_adNetworkName;
    
    NSInteger _age;
    DAGender _gender;
    
    double _latitude;
    double _longitude;
    double _accuracyInMeters;
}

- (id)initMediaitonAdapter:(DABannerMediationSchedule *)schedule;

//- (void)refreshAd;
- (void)loadAd;

- (void)loadAdByServer;
- (void)loadAdByClientMediation;

- (void)loadImage:(NSString *)imageURL impressionURL:(NSString *)impressionURL;

- (void)handleTap:(UIGestureRecognizer *)recognizer;

- (void)getConfig;
- (void)getBannerCampaign;
- (void)bannerMediationTracking:(ClientMediationTrackingType)type;

- (void)nextAdNetowrk;

- (void)addAlignCenterConstraint;

- (void)resetSchedule;

- (void)refreshAd;



@end



@implementation DABannerView

@synthesize delegate = _delegate;


- (void)dealloc
{
    [_scheduleTimer invalidate];
    _scheduleTimer = nil;
    
    [self removeGestureRecognizer:_tapGestureRecognizer];
 
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    AdPopcornLogInfo(@"_scheduleTimer : %@, self : %@", _scheduleTimer, self);
}

- (id)initWithBannerViewSize:(DABannerViewSizeType)size origin:(CGPoint)origin mediaKey:(NSString *)mediaKey mediationKey:(NSString *)mediationKey viewController:(UIViewController *)viewController
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
    
    self = [super initWithFrame:CGRectMake(origin.x, origin.y, [DAAdSize adSize:DABannerViewSize320x50].width, [DAAdSize adSize:DABannerViewSize320x50].height)];
    if (self)
    {
        
        // initialize log
        AdPopcornLogInitialize();
        
        // log level set
        AdPopcornLogConfigureByName("AdPopcorn*", AdPopcornLogLevelDebug);
        
        _mediaKey = mediaKey;
        _mediationKey = mediationKey;
        _origin = origin;
        _viewController = viewController;
        _size = [DAAdSize adSize:size];
        
        // demo
        _age = [DADemo sharedInstance].age;
        _gender = [DADemo sharedInstance].gender;
        if (_gender == 0)
        {
            _gender = DAGenderUnknown;
        }
        
        _latitude = [DADemo sharedInstance].latitude;
        _longitude = [DADemo sharedInstance].longitude;
        
        
        // schedule invalidate
        [_scheduleTimer invalidate];
        _scheduleTimer = nil;
        
        
        
        AdPopcornLogTrace(@"_mediaKey : %@, _origin : %f, %f, _size : %f, %f", _mediaKey, _origin.x, _origin.y, _size.width, _size.height);
        
        
        
        self.backgroundColor = [UIColor blackColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.hidden = YES;
        
        // container view
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [DAAdSize adSize:size].width, [DAAdSize adSize:size].height)];

        
        //ad image view
        _adImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [DAAdSize adSize:size].width, [DAAdSize adSize:size].height)];
        [_containerView addSubview:_adImageView];
        _adImageView.hidden = YES;
        
        
        
        _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [DAAdSize adSize:size].width, [DAAdSize adSize:size].height)];
        _webView.delegate = self;
        [_containerView addSubview:_webView];
        _webView.hidden = YES;
        
        [self addSubview:_containerView];
        
        // add constraint
        [self addAlignCenterConstraint];


        [_viewController.view addSubview:self];
        
        // add target
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:_tapGestureRecognizer];
        
        
        // adapter
        _adapterInstanceDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
        
        
//        _daService = [[DAService alloc] init];
        
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
        
        [self getConfig];
        
        
    }
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark - public
- (void)loadRequest
{
    if (_adapterInstanceDictionary.count > 0)
    {
        for (NSString *adNetworkName in [_adapterInstanceDictionary allKeys])
        {
            if ([adNetworkName isEqualToString:_adNetworkName])
            {
                id adapterInstance = [_adapterInstanceDictionary valueForKey:_adNetworkName];
                AdPopcornLogTrace(@"adapterInstance : %@", adapterInstance);
                
                if (adapterInstance != nil)
                {
                    if ([adapterInstance respondsToSelector:@selector(loadRequest)])
                    {
                        [adapterInstance loadRequest];
                    }
                    
                }
                
                break;
            }
        }
    }
}

- (void)setLogLevel:(IgaworksADLogLevel)logLevel
{
    if (logLevel == IgaworksADLogInfo)
    {
        // set log level trace
        AdPopcornLogConfigureByName("AdPopcorn*", AdPopcornLogLevelInfo);
    }
    else if (logLevel == IgaworksADLogDebug)
    {
        // set log level trace
        AdPopcornLogConfigureByName("AdPopcorn*", AdPopcornLogLevelDebug);
    }
    else if (logLevel == IgaworksADLogTrace)
    {
        // set log level trace
        AdPopcornLogConfigureByName("AdPopcorn*", AdPopcornLogLevelTrace);
    }
}

#pragma mark - private
- (id)initMediaitonAdapter:(DABannerMediationSchedule *)schedule
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
        
        // set integrationKey
        if ([adapterInstance respondsToSelector:@selector(setIntegrationKey:)])
        {
            [adapterInstance setIntegrationKey:schedule.integrationKey];
        }
        
        
        if ([adapterInstance respondsToSelector:@selector(setViewController:origin:size:bannerView:)])
        {
            [adapterInstance setViewController:_viewController origin:_origin size:_size bannerView:self];
        }
        
        
        
//        SEL setViewControllerSelector = NSSelectorFromString(@"setViewController:origin:size:adType:");
//        IMP theImplementation = [adapterInstance methodForSelector:setViewControllerSelector];
//        theImplementation(adapterInstance, setViewControllerSelector, _viewController, _origin, _size, AdBannerType);
        
    }
    
    return adapterInstance;
}

- (void)refreshAd
{
    // close
    DABannerMediationSchedule *schedule = [[DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray objectAtIndex:_loadToMediation % [DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray.count];
    
    
    id prevAdapterInstance = [_adapterInstanceDictionary valueForKey:schedule.adNetworkName];
    if (prevAdapterInstance != nil)
    {
        AdPopcornLogTrace(@"prevAdapterInstance : %@", prevAdapterInstance);
        [prevAdapterInstance closeAd];
    }
    
    
    _adNetworkFaildCount = 0;
    _loadToMediation = 0;
    [self loadAd];
}

- (void)loadAd
{
    // call to server
    // server mediation이면,
    if ([DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray.count > 0)
    {
        DABannerMediationSchedule *schedule = [[DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray objectAtIndex:_loadToMediation % [DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray.count];
        
        AdPopcornLogInfo(@"=====> adNetworkName : %@, _loadToMediation : %d, %d, %d", schedule.adNetworkName, _loadToMediation, schedule.integrationType, _loadToMediation % [DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray.count);
        
        _adNetworkName = schedule.adNetworkName;
        
        
        // for test

        /*
        if (
            [_adNetworkName isEqualToString:kDAMediationIGAW] ||
            [_adNetworkName isEqualToString:kDAMediationAdMob] ||
            [_adNetworkName isEqualToString:kDAMediationTAd] ||
            [_adNetworkName isEqualToString:kDAMediationIAd] ||
//            [_adNetworkName isEqualToString:kDAMediationAdam] ||
            [_adNetworkName isEqualToString:kDAMediationShallWeAd] ||
            [_adNetworkName isEqualToString:kDAMediationAdHub] ||
            [_adNetworkName isEqualToString:kDAMediationAppLift] ||
            [_adNetworkName isEqualToString:kDAMediationInmobi] ||
            [_adNetworkName isEqualToString:kDAMediationMMedia] ||
            [_adNetworkName isEqualToString:kDAMediationAdPost] ||
            [_adNetworkName isEqualToString:kDAMediationCauly]
            )
        {
            [self nextAdNetowrk];
        }*/

        if (NO)
        {
            
        }
        else
        {
            if (schedule.integrationType == DAMediationIntegrationServerType)
            {
                [self getBannerCampaign];
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
        
        [self getBannerCampaign];
    }
}


- (void)loadAdByServer
{
    NSString *imageURL = nil;
    
    DAGetBannerCampaignCampaign *campaign = [[DAService sharedInstance].daGetBannerCampaignResult.campaignListArray firstObject];
    
    AdPopcornLogTrace(@"campaign.isWebContent : %d", campaign.isWebContent);
    
    if (campaign.isWebContent)
    {
        _adNetworkFaildCount = 0;
        
        _webView.hidden = NO;
        _adImageView.hidden = YES;
        
        _webData = campaign.webData;
        
        [_webView loadHTMLString:_webData baseURL:nil];
        

        
        // add
//        [_viewController.view addSubview:self];
        
//        AdPopcornLogTrace(@"_viewController.view.subviews : %@", _viewController.view.subviews);
        
        // 무조건 첫번째 adnetwork로 시도.
        _loadToMediation = 0;
        
        self.hidden = NO;
        
        if ([_delegate respondsToSelector:@selector(DABannerViewDidLoadAd:)])
        {
            [_delegate DABannerViewDidLoadAd:self];
        }
        
        AdPopcornLogTrace(@"_webView : %@", _webView);
        
    }
    else
    {
        _webView.hidden = YES;
        _adImageView.hidden = NO;
        
        for (DAGetBannerCampaignCampaignImage *image in campaign.imageListArray)
        {
            if ([IgaworksADUtil isPhone])
            {
                if (image.width == kDAIphoneBannerSizeWidth && image.height == kDAIphoneBannerSizeHeight)
                {
                    imageURL = image.imageURL;
                    break;
                }
            }
        }
        
        
        AdPopcornLogTrace(@"imageURL : %@", imageURL);
       
        if (imageURL != nil)
        {
            _redirectURL = campaign.redirectURL;
            
            [self loadImage:imageURL impressionURL:campaign.impressionURL];
        }
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
            // BannerMediationTrackingBEQ : request
            [self bannerMediationTracking:ClientMediationTrackingRequestType];
            
            
            [_adapterInstance loadAd];
            
            _lastAdapterInstance = _adapterInstance;
        }
    }
    else
    {
        AdPopcornLogInfo(@"%@ adapter is not exist.", _adNetworkName);
        [self nextAdNetowrk];
    }
}

- (void)loadImage:(NSString *)imageURL impressionURL:(NSString *)impressionURL
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:imageURL]];
    [request setTimeoutInterval:3];
    
    [_adImageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
     {
         _adNetworkFaildCount = 0;
         
         _adImageView.image = image;
         // add
//         [_viewController.view addSubview:self];
         
//         AdPopcornLogTrace(@"_viewController.view.subviews : %@", _viewController.view.subviews);
         
         
         // call impression
         if (impressionURL.length != 0)
         {
             [[DAService sharedInstance] impression:impressionURL];
         }
         
         // 무조건 첫번째 adnetwork로 시도.
         _loadToMediation = 0;
         
         
         self.hidden = NO;
         
         if ([_delegate respondsToSelector:@selector(DABannerViewDidLoadAd:)])
         {
             [_delegate DABannerViewDidLoadAd:self];
         }
         
     }
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
     {
         AdPopcornLogTrace(@"error : %@", error);
         
         if ([DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray.count > 0)
         {
             [self nextAdNetowrk];
         }
         else
         {
             if ([_delegate respondsToSelector:@selector(DABannerView:didFailToReceiveAdWithError:)])
             {
                 [_delegate DABannerView:self didFailToReceiveAdWithError:[DAError errorWithDomain:kDAErrorDomain code:DALoadAdFailed userInfo:[NSDictionary dictionaryWithObjectsAndKeys:DAErrorString(DALoadAdFailed), NSLocalizedDescriptionKey, nil]]];
             }
         }
     }];
}

- (void)handleTap:(UIGestureRecognizer *)recognizer
{
    if ([[UIApplication sharedApplication] openURL:[NSURL URLWithString:_redirectURL]])
    {
        // call delegate
        if ([_delegate respondsToSelector:@selector(DABannerViewWillLeaveApplication:)])
        {
            [_delegate DABannerViewWillLeaveApplication:self];
        }
    }
}

- (void)getConfig
{
    AdPopcornLogTrace(@"country : %@, language : %@", [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode], [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]);
    
    [DAService sharedInstance].delegate = self;
    NSDictionary *parameterDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   _mediaKey, @"mediaKey",
                                   _mediationKey, @"bannerMediationKey",
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
    
    
//    AdPopcornLogTrace(@"parameterDict : %@", parameterDict);
    
    [[DAService sharedInstance] getConfig:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSString igaworksAD_base64EncodedString:[IgaworksADUtil queryString:parameterDict]], @"qrstr",
                                           nil]];
}

- (void)getBannerCampaign
{
    //    getBannerCampaign
    [DAService sharedInstance].delegate = self;
    NSDictionary *parameterDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   _mediaKey, @"mediaKey",
                                   _mediationKey, @"bannerMediationKey",
                                   @"", @"interstitialMediationKey",
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
                                   [[NSLocale currentLocale]objectForKey:NSLocaleLanguageCode], @"language",
                                   @"false", @"isWebContent",
                                   nil];
    
//    AdPopcornLogTrace(@"parameterDict : %@", parameterDict);
    
    [[DAService sharedInstance] getBannerCampaign:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSString igaworksAD_base64EncodedString:[IgaworksADUtil queryString:parameterDict]], @"qrstr",
                                   nil]];
}
             
- (void)bannerMediationTracking:(ClientMediationTrackingType)type
{
    //    getBannerCampaign
    [DAService sharedInstance].delegate = self;
    NSDictionary *parameterDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   _mediaKey, @"mediaKey",
                                   _mediationKey, @"bannerMediationKey",
                                   @"", @"interstitialMediationKey",
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
                                   [[NSLocale currentLocale]objectForKey:NSLocaleLanguageCode], @"language",
                                   @"false", @"isWebContent",
                                   [NSNumber numberWithInteger:type], @"trackingTypeCode",
                                   nil];
    
    AdPopcornLogTrace(@"parameterDict : %@", parameterDict);
    
    [[DAService sharedInstance] bannerMediationTracking:[NSDictionary dictionaryWithObjectsAndKeys:
                    [NSString igaworksAD_base64EncodedString:[IgaworksADUtil queryString:parameterDict]], @"qrstr",
                                                   nil]];
}


- (void)nextAdNetowrk
{
    double delayInSeconds = 0.3f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        _adNetworkFaildCount++;
        
        AdPopcornLogTrace(@"--------> _loadToMediation : %d", _loadToMediation);
        
        _loadToMediation = (_loadToMediation + 1) % [DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray.count;
        
        
        AdPopcornLogTrace(@"_adNetworkFaildCount : %d, bannerMediationScheduleArray.count : %d, _loadToMediation : %d", _adNetworkFaildCount, [DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray.count, _loadToMediation);
        
        // check all ad network is faild
        if (_adNetworkFaildCount >= [DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray.count)
        {
            AdPopcornLogTrace(@"==> all ad network is faild :  _delegate : %@", _delegate);
            
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if ([_delegate respondsToSelector:@selector(DABannerView:didFailToReceiveAdWithError:)])
                {
                    [_delegate DABannerView:self didFailToReceiveAdWithError:[DAError errorWithDomain:kDAErrorDomain code:DANoAd userInfo:[NSDictionary dictionaryWithObjectsAndKeys:DAErrorString(DANoAd), NSLocalizedDescriptionKey, nil]]];
                }
            });
        }
        else
        {
            dispatch_sync(dispatch_get_main_queue(), ^(void){
                [self loadAd];
                [self resetSchedule];
            });
        }
    });
}


- (void)addAlignCenterConstraint
{
    // add constraints
    [_containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    UIView *superview = self;
    [superview addConstraint:
     [NSLayoutConstraint constraintWithItem:_containerView
                                  attribute:NSLayoutAttributeCenterX
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:superview
                                  attribute:NSLayoutAttributeCenterX
                                 multiplier:1
                                   constant:0]];
    
    [superview addConstraint:
     [NSLayoutConstraint constraintWithItem:_containerView
                                  attribute:NSLayoutAttributeCenterY
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:superview
                                  attribute:NSLayoutAttributeCenterY
                                 multiplier:1
                                   constant:0]];
    
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:superview
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:0.0
                                                           constant:_size.height]];
    
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:superview
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:0.0
                                                           constant:_size.width]];
}

- (void)resetSchedule
{
    [_scheduleTimer invalidate];
    _scheduleTimer = nil;
    
    _scheduleTimer = [NSTimer timerWithTimeInterval:_refreshRate target:self selector:@selector(refreshAd) userInfo:nil repeats:YES];
    
    [[NSRunLoop mainRunLoop] addTimer:_scheduleTimer forMode:NSDefaultRunLoopMode];
}



#pragma mark - DAServiceDelegate
- (void)getConfigDidComplete
{
    // mediation list
    if ([DAService sharedInstance].daGetConfigResult.isResult)
    {
        // init client adapter for mediation
        for (DABannerMediationSchedule *schedule in [DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray)
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
        
        
        if ([DAService sharedInstance].daGetConfigResult.bannerMediationRefreshRate > 0)
        {
            _refreshRate = [DAService sharedInstance].daGetConfigResult.bannerMediationRefreshRate;
            
            
            // schedule
            // skip
            //    _loadToMediation = (_loadToMediation + 1) % _mediationListArray.count;
            // 무조건 첫번째 adnetwork로 시도.
            _loadToMediation = 0;
            
            [self loadAd];
            
            [self resetSchedule];
        }
        else
        {
            [self loadAd];
        }
        
        
        AdPopcornLogTrace(@"_refreshRate : %d", _refreshRate);
        
        
    }
    else
    {
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

- (void)getBannerCampaignDidComplete
{
    if ([DAService sharedInstance].daGetBannerCampaignResult.isResult)
//    if (NO)
    {
        [self loadAdByServer];
    }
    else
    {
        if ([DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray.count > 0)
        {
            [self nextAdNetowrk];
        }
        else
        {
            if ([_delegate respondsToSelector:@selector(DABannerView:didFailToReceiveAdWithError:)])
            {
                [_delegate DABannerView:self didFailToReceiveAdWithError:[DAError errorWithDomain:kDAErrorDomain code:[DAService sharedInstance].daGetBannerCampaignResult.resultCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:DAErrorString([DAService sharedInstance].daGetBannerCampaignResult.resultCode), NSLocalizedDescriptionKey, nil]]];
            }
        }
        
        
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"DA" message:_daService.daGetBannerCampaignResult.resultMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
//        [alertView show];
    }
}

- (void)getBannerCampaignFailedWithError:(NSError *)error
{
    AdPopcornLogTrace(@"error : %@", error);
    
    if ([DAService sharedInstance].daGetConfigResult.bannerMediationScheduleArray.count > 0)
    {
        [self nextAdNetowrk];
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(DABannerView:didFailToReceiveAdWithError:)])
        {
            [_delegate DABannerView:self didFailToReceiveAdWithError:[DAError errorWithDomain:kDAErrorDomain code:DAServerTimeout userInfo:[NSDictionary dictionaryWithObjectsAndKeys:DAErrorString(DAServerTimeout), NSLocalizedDescriptionKey, nil]]];
        }
    }
}

#pragma mark - DaAdapterDelegate
- (void)DAAdapterBannerViewDidLoadAd:(UIView *)bannerView
{
    _adNetworkFaildCount = 0;
    
//    AdPopcornLogInfo(@"bannerView : %@", bannerView);
    
    // BannerMediationTrackingBEQ : impression
    [self bannerMediationTracking:ClientMediationTrackingImpressionType];
 
    
    self.hidden = NO;
    
    if ([_delegate respondsToSelector:@selector(DABannerViewDidLoadAd:)])
    {
        [_delegate DABannerViewDidLoadAd:bannerView];
    }
}

- (void)DAAdapterBannerView:(UIView *)bannerView didFailToReceiveAdWithError:(NSError *)error
{
    
    AdPopcornLogDebug(@"bannerView : %@, error : %@, _loadToMediation : %d, _adNetworkFaildCount : %d", bannerView, error, _loadToMediation, _adNetworkFaildCount);
    
    // BannerMediationTrackingBEQ : impression fail
    [self bannerMediationTracking:ClientMediationTrackingImpressionFailType];
    
    [self nextAdNetowrk];
}

- (void)DAAdapterBannerViewWillLeaveApplication:(UIView *)bannerView
{
    // BannerMediationTrackingBEQ : click
    [self bannerMediationTracking:ClientMediationTrackingClickType];
}

- (void)DAAdapterInvokeDelegateTimeout
{
    AdPopcornLogDebug(@"DAAdapterInvokeDelegateTimeout.");
    
    
    [self nextAdNetowrk];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
//    AdPopcornLogTrace(@"request.URL : %@", request.URL);
    
    if([_webData rangeOfString:request.URL.absoluteString].length != 0)
    {
        [[UIApplication sharedApplication] openURL:request.URL];
        
        // call delegate
        if ([_delegate respondsToSelector:@selector(DABannerViewWillLeaveApplication:)])
        {
            [_delegate DABannerViewWillLeaveApplication:self];
        }
    }
    
    return YES;
}

@end
