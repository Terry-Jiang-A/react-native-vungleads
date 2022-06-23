# react-native-vungleads

vungle ads

## Installation

```sh
npm install react-native-vungleads
```

## Usage

```js
import Vungleads from 'react-native-vungleads';

//Initialize SDK
  Vungleads.initialize(SDK_KEY, (callback) => {
    setIsInitialized(true);
    logStatus('SDK Initialized: '+ callback);

    // Attach ad listeners for rewarded ads, and banner ads
    attachAdListeners();//need to call removeEventListener to remove listeners.
  });


  //Attach ad Listeners for rewarded ads, and banner ads, and so on.
    function attachAdListeners() {

    Vungleads.addEventListener('OnVungleRewardUserForPlacementID', (adInfo) => {
      
      logStatus('reward user, with ID: ' +adInfo.adUnitId);
      
    });
    Vungleads.addEventListener('OnVungleTrackClickForPlacementID', (adInfo) => {
     
      logStatus('track click , with ID: '+adInfo.adUnitId);
    });
    Vungleads.addEventListener('OnVungleWillLeaveApplicationForPlacementID', (adInfo) => {
      
      logStatus('Ad leave application, with ID: '+adInfo.adUnitId);
    });
    Vungleads.addEventListener('OnVungleAvailable', (adInfo) => {

      logStatus('Ad available with ID: '+adInfo.adUnitId);
      if (adInfo.adUnitId == BANNER_AD_UNIT_ID ) {
        //Vungleads.showBottomBanner(adInfo.adUnitId);
        setIsNativeUIBannerShowing(!isNativeUIBannerShowing);
      }else{
        
        Vungleads.showInterstitial(adInfo.adUnitId);
      }
      
    });
   

    Vungleads.addEventListener('OnVungleWillShowAdForPlacementID', (adInfo) => {
      logStatus('ad will show, with ID: ' +adInfo.adUnitId);
    });
    Vungleads.addEventListener('OnVungleDidShowAdForPlacementID', (adInfo) => {
      logStatus('ad show with ID: ' + adInfo.adUnitId);
    });
    Vungleads.addEventListener('OnVungleWillCloseAdForPlacementID', (adInfo) => {
      logStatus('ad will close');
    });
    Vungleads.addEventListener('OnVungleDidCloseAdForPlacementID', (adInfo) => {
      logStatus('ad closed')
    });
  }
// ...

  ios:
  //Modify podfile，add Unity Ads SDK：
  pod "VungleSDK-iOS", "6.11.0"
  
  For specific usage, please refer to example.
  How To Run example:
  1,$ cd example && npm install
  2,$ cd ios && pod install
  3,$ cd .. && npm run ios or npm run android
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
