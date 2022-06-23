#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTConvert.h>
#import <VungleSDK/VungleSDK.h>

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow
#define DEVICE_SPECIFIC_ADVIEW_AD_FORMAT ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? MAAdFormat.leader : MAAdFormat.banner

NS_ASSUME_NONNULL_BEGIN

/**
 * The primary bridge between JS <-> native code for the Unity ads React Native module.
 */
@interface Vungleads : RCTEventEmitter<RCTBridgeModule, VungleSDKDelegate>

/**
 * Shared instance of this bridge module.
 */
@property (nonatomic, strong, readonly, class) Vungleads *shared;

@end

NS_ASSUME_NONNULL_END

//@interface Vungleads : NSObject <RCTBridgeModule>

//@end
