#import "Vungleads.h"
#if defined(__IPHONE_14_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_14_0
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#endif

#define ROOT_VIEW_CONTROLLER (UIApplication.sharedApplication.keyWindow.rootViewController)
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH ROOT_VIEW_CONTROLLER.view.frame.size.width
#define BANNER_AD_HEIGHT 50.0
#define BANNER_SHORT_AD_WIDTH 300.0
#define BANNER_AD_WIDTH 320.0

@interface Vungleads()

// Parent Fields
@property (nonatomic, assign, getter=isPluginInitialized) BOOL pluginInitialized;
@property (nonatomic, assign, getter=isSDKInitialized) BOOL sdkInitialized;
@property (nonatomic, assign, getter=isPlayingBanner) BOOL playingBanner;
@property (nonatomic, strong) VungleSDK *sdk;
@property (retain, nonatomic) UIView *adView;

// Banner Fields
// This is the Ad Unit or Placement that will display banner ads:
@property (strong) NSString* placementId;

@property (nonatomic, strong) UIView *safeAreaBackground;

// React Native's proposed optimizations to not emit events if no listeners
@property (nonatomic, assign) BOOL hasListeners;

@end
@implementation Vungleads

static NSString *const SDK_TAG = @"VungleSdk";
static NSString *const TAG = @"Vungle Ads";

RCTResponseSenderBlock _onInitialized = nil;

static Vungleads *VungleShared; // Shared instance of this bridge module.

RCT_EXPORT_MODULE()

// `init` requires main queue b/c of UI code
+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

// Invoke all exported methods from main queue
- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (Vungleads *)shared
{
    return VungleShared;
}

- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        VungleShared = self;
        // Do any additional setup after loading the view.
        if (@available(iOS 14, *)) {
            [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                
            }];
        }
        
    }
    return self;
}

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(isInitialized)
{
    return @([self isPluginInitialized] && [self isSDKInitialized]);
}

RCT_EXPORT_METHOD(initialize :(NSString *)sdkKey :(RCTResponseSenderBlock)callback)
{
    // Guard against running init logic multiple times
    if ( [self isPluginInitialized] )
    {
        callback(@[@" Unity Sdk has Initiallized"]);
        return;
    }
    
    self.pluginInitialized = YES;
    _onInitialized = callback;
    
    self.sdk = [VungleSDK sharedSDK];
    [self.sdk updateConsentStatus:VungleConsentDenied consentMessageVersion:@"Accepted"];
    /**GDPR status option to opt_out
     [self.sdk updateConsentStatus:VungleConsentDenied consentMessageVersion:@"Denied"];
     */
    [self.sdk updateCCPAStatus:VungleCCPADenied];
    /**CCPA Status Opt_Out API Call
     [self.sdk updateCCPAStatus:VungleCCPADenied];
     */
    [self.sdk setDelegate:self];
    [self.sdk setLoggingEnabled:YES];
    NSError *error = nil;
    if(![self.sdk startWithAppId:sdkKey options:nil error:&error]) {
        NSLog(@"Error while starting VungleSDK %@",[error localizedDescription]);
      
        return;
    }
    
    
}

#pragma mark - VungleSDKDelegate Methods

- (void)vungleRewardUserForPlacementID:(nullable NSString *)placementID {
    NSLog(@"-->> Delegate Callback: vungleRewardUserForPlacementID: Rewarded for Placement ID: %@", placementID);
}

- (void)vungleTrackClickForPlacementID:(nullable NSString *)placementID {
    NSLog(@"-->> Delegate Callback: vungleTrackClickForPlacementID %@",placementID);
}

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(NSString *)placementID error:(NSError *)error {
    if (isAdPlayable) {
        NSLog(@"-->> Delegate Callback: vungleAdPlayabilityUpdate: Ad is available for Placement ID: %@", placementID);
        [self sendReactNativeEventWithName: @"OnVungleAvailable" body: @{@"adUnitId" : placementID}];
        
    } else {
        NSLog(@"-->> Delegate Callback: vungleAdPlayabilityUpdate: Ad is NOT available for Placement ID: %@", placementID);
        //[self sendReactNativeEventWithName: @"OnVungleAdNotAvailableForPlacementID" body: @{@"adUnitId" : placementID}];
        
    }
    
}

- (void)vungleWillLeaveApplicationForPlacementID:(nullable NSString *)placementID {
    NSLog(@"-->> Delegate Callback: vungleWillLeaveApplicationForPlacementId is pressed on %@",placementID);
    [self sendReactNativeEventWithName: @"OnVungleWillLeaveApplicationForPlacementID" body: @{@"adUnitId" : placementID}];
    
}

- (void)vungleDidShowAdForPlacementID:(nullable NSString *)placementID {
    NSLog(@"-->> Delegate Callback: vungleDidShowAdForPlacementID for %@",placementID);
    [self sendReactNativeEventWithName: @"OnVungleDidShowAdForPlacementID" body: @{@"adUnitId" : placementID}];
    
}

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID {
    NSLog(@"-->> Delegate Callback: vungleWillShowAdForPlacementID");
    [self sendReactNativeEventWithName: @"OnVungleWillShowAdForPlacementID" body: @{@"adUnitId" : placementID}];
}

- (void)vungleWillCloseAdForPlacementID:(nonnull NSString *)placementID {
    NSLog(@"-->> Delegate callback: vungleWillCloseAdForPlacement for %@",placementID);
    [self sendReactNativeEventWithName: @"OnVungleWillCloseAdForPlacementID" body: @{@"adUnitId" : placementID}];
    
}

- (void)vungleDidCloseAdForPlacementID:(NSString *)placementID {
    NSLog(@"-->> Delegate callback: vungleDidCloseAdForPlacementID for %@", placementID);
    [self sendReactNativeEventWithName: @"OnVungleDidCloseAdForPlacementID" body: @{@"adUnitId" : placementID}];
}

- (void)vungleSDKDidInitialize {
    NSLog(@"-->> Delegate Callback: vungleSDKDidInitialize - SDK initialized SUCCESSFULLY");
    _onInitialized(@[@"success"]);
    
}

- (void)vungleAdViewedForPlacement:(NSString *)placementID {
    NSLog(@"-->> Delegate Callback: vungleAdViewedForPlacement %@",placementID);
}

- (void)vungleSDKFailedToInitializeWithError:(NSError *)error {
    NSLog(@"-->> Delegate Callback: vungleSDKFailedToInitializeWithError: %@",error);
    _onInitialized(@[@" - VungleInitializationDelegate initializationFailed with error: %@", error ]);
    
}
#pragma mark - Interstitials

RCT_EXPORT_METHOD(loadInterstitial:(NSString *)adUnitIdentifier)
{
    NSError *error = nil;
    if ([self.sdk loadPlacementWithID:adUnitIdentifier error:&error]) {
        
        
    } else {
        
        if (error) {
            NSLog(@"Unable to load placement with reference ID :%@, Error %@", adUnitIdentifier, error);
        }
    }
    
}

RCT_EXPORT_METHOD(showInterstitial:(NSString *)adUnitIdentifier)
{
    
    NSDictionary *options = @{
        VunglePlayAdOptionKeyOrientations: @(UIInterfaceOrientationMaskAll),
        VunglePlayAdOptionKeyStartMuted:@(1),
        VunglePlayAdOptionKeyIncentivizedAlertBodyText : @"Complete the video in order to get reward",
        VunglePlayAdOptionKeyIncentivizedAlertCloseButtonText : @"Close",
        VunglePlayAdOptionKeyIncentivizedAlertContinueButtonText : @"Keep Watching",
        VunglePlayAdOptionKeyIncentivizedAlertTitleText : @"Careful!"};
    NSError *error;
    [self.sdk playAd:ROOT_VIEW_CONTROLLER options:options placementID:adUnitIdentifier error:&error];
    if (error) {
        NSLog(@"Error encountered playing ad: %@", error);
    }
    
}


RCT_EXPORT_METHOD(loadBottomBanner:(NSString *)adUnitIdentifier)
{
    NSError *error = nil;
    if ([self.sdk loadPlacementWithID:adUnitIdentifier withSize:VungleAdSizeBanner error:&error]){
        [self setPlayingBanner:YES];
        NSError *error;
        self.adView = [[UIView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH / 2) - (BANNER_AD_WIDTH / 2), SCREEN_HEIGHT - BANNER_AD_HEIGHT-20, 320, 50)];
        
        [ROOT_VIEW_CONTROLLER.view addSubview:self.adView];
        [self.sdk addAdViewToView:self.adView withOptions:nil placementID:adUnitIdentifier error:&error];
        if (error) {
            NSLog(@"Error encountered playing ad: %@", error);
           
        } else {
           
        }
        
    }
     else {
        
        if (error) {
            NSLog(@"Unable to load placement with reference ID :%@, Error %@", adUnitIdentifier, error);
        }
    }

    
    
}

RCT_EXPORT_METHOD(showBottomBanner:(NSString *)adUnitIdentifier)
{
    [self setPlayingBanner:YES];
    NSError *error;
    self.adView = [[UIView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH / 2) - (BANNER_AD_WIDTH / 2), SCREEN_HEIGHT - BANNER_AD_HEIGHT-20, 320, 50)];
    
    [ROOT_VIEW_CONTROLLER.view addSubview:self.adView];
    [self.sdk addAdViewToView:self.adView withOptions:nil placementID:adUnitIdentifier error:&error];
    if (error) {
        NSLog(@"Error encountered playing ad: %@", error);
       
    } else {
       
    }

}

RCT_EXPORT_METHOD(unLoadAds:(NSString *)adUnitIdentifier)
{
    [self.sdk finishDisplayingAd:adUnitIdentifier];
    [self setPlayingBanner:NO];
    if(self.adView != nil){
        [self.adView removeFromSuperview];
    }
    
}

- (void)addBannerViewToBottomView: (UIView *)bannerView {
    bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [ROOT_VIEW_CONTROLLER.view addSubview:bannerView];
    [ROOT_VIEW_CONTROLLER.view addConstraints:@[
                               [NSLayoutConstraint constraintWithItem:bannerView
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:ROOT_VIEW_CONTROLLER.bottomLayoutGuide
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1
                                                             constant:0],
                               [NSLayoutConstraint constraintWithItem:bannerView
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:ROOT_VIEW_CONTROLLER.view
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1
                                                             constant:0]
                               ]];
}



#pragma mark - React Native Event Bridge

- (void)sendReactNativeEventWithName:(NSString *)name body:(NSDictionary<NSString *, id> *)body
{
    [self sendEventWithName: name body: body];
}

// From RCTBridgeModule protocol
- (NSArray<NSString *> *)supportedEvents
{
    return @[@"OnVungleRewardUserForPlacementID",
             @"OnVungleTrackClickForPlacementID",
             @"OnVungleAvailable",
             @"OnVungleWillLeaveApplicationForPlacementID",
             
             @"OnVungleDidShowAdForPlacementID",
             @"OnVungleWillShowAdForPlacementID",
             @"OnVungleWillCloseAdForPlacementID",
             @"OnVungleDidCloseAdForPlacementID"];
}

- (void)startObserving
{
    self.hasListeners = YES;
}

- (void)stopObserving
{
    self.hasListeners = NO;
}

@end
