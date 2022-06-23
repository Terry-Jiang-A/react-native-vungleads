import Vungleads from 'react-native-vungleads';

import React, {useState} from 'react';
import {Platform, StyleSheet, Text, View} from 'react-native';
import AppButton from './AppButton';
import 'react-native-gesture-handler';
import {NavigationContainer} from "@react-navigation/native";

var adLoadState = {
  notLoaded: 'NOT_LOADED',
  loading: 'LOADING',
  loaded: 'LOADED',
};

var adsShowState = {
  notStarted: 'NOT_STARTED',
  completed: 'COMPLETED',
  failed: 'FAILED',
  start: 'STARTED',
  click: 'CLICKED',
};

const App = () => {

  // AppID
  const SDK_KEY = Platform.select({
    ios: '594a64ca5c721375350010d8',//'5e13cc9d61880b27a65bf735',//'594a64ca5c721375350010d8',
    android: '5d2da6dda1b3610017e562b4',
  });

  const INTERSTITIAL_AD_UNIT_ID = Platform.select({
    ios: 'IOS_INTERSTITIAL-7255001',//'INTERSTITIAL01-8573922',//'IOS_INTERSTITIAL-7255001',
    android: 'ANDROID_INTERSTITIAL-7201909',
  });

  const REWARDED_AD_UNIT_ID = Platform.select({
    ios: 'IOS_REAWARD-7549232',//'REWARDED01-4772665',//'IOS_REAWARD-7549232',
    android: 'ANDROID_REWARD-1650259',
  });

  const BANNER_AD_UNIT_ID = Platform.select({
    ios: 'IOS_BANNER-9506729',//'BANNER3-7051875',//'IOS_BANNER-9506729',
    android: 'ANDROID_BANNER-5364013',
  });

  // Create states
  const [isInitialized, setIsInitialized] = useState(false);
  const [interstitialAdLoadState, setInterstitialAdLoadState] = useState(adLoadState.notLoaded);
  //const [VungleadshowCompleteState, setVungleadshowCompleteState] = useState(adsShowState.notStarted);
  //const [interstitialRetryAttempt, setInterstitialRetryAttempt] = useState(0);
  const [rewardedAdLoadState, setRewardedAdLoadState] = useState(adLoadState.notLoaded);
  const [isNativeUIBannerShowing, setIsNativeUIBannerShowing] = useState(false);
  const [statusText, setStatusText] = useState('Initializing SDK...');


  Vungleads.initialize(SDK_KEY, (callback) => {
    setIsInitialized(true);
    logStatus('SDK Initialized: '+ callback);

    // Attach ad listeners for rewarded ads, and banner ads
    attachAdListeners();
  });

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

  function getInterstitialButtonTitle() {
    if (interstitialAdLoadState === adLoadState.notLoaded) {
      return 'Load Interstitial';
    } else if (interstitialAdLoadState === adLoadState.loading) {
      return 'Loading...';
    } else {
      return 'Show Interstitial'; // adLoadState.loaded
    }
  }

  function getRewardedButtonTitle() {
    if (rewardedAdLoadState === adLoadState.notLoaded) {
      return 'Load Rewarded Ad';
    } else if (rewardedAdLoadState === adLoadState.loading) {
      return 'Loading...';
    } else {
      return 'Show Rewarded Ad'; // adLoadState.loaded
    }
  }

  function logStatus(status) {
    console.log(status);
    setStatusText(status);
  }

  return (
    <NavigationContainer>
      <View style={styles.container}>
        <Text style={styles.statusText}>
          {statusText}
        </Text>
        <AppButton
          title={getInterstitialButtonTitle()}
          enabled={
            isInitialized && interstitialAdLoadState !== adLoadState.loading
          }
          onPress={() => {
            Vungleads.loadInterstitial(INTERSTITIAL_AD_UNIT_ID);
          }}
        />
        <AppButton
          title={getRewardedButtonTitle()}
          enabled={isInitialized && rewardedAdLoadState !== adLoadState.loading}
          onPress={() => {
            Vungleads.loadInterstitial(REWARDED_AD_UNIT_ID);
          }}
        />
        <AppButton
          title={isNativeUIBannerShowing ? 'Hide Native UI Banner' : 'Show Native UI Banner'}
          enabled={isInitialized}
          onPress={() => {
            if (isNativeUIBannerShowing) {
              Vungleads.unLoadAds(BANNER_AD_UNIT_ID);
              setIsNativeUIBannerShowing(!isNativeUIBannerShowing);
            }else{
              Vungleads.loadBottomBanner(BANNER_AD_UNIT_ID);
            
            } 
            
          }}
        /> 
        
      </View>
    </NavigationContainer>
  );
};


const styles = StyleSheet.create({
  container: {
    paddingTop: 80,
    flex: 1, // Enables flexbox column layout
  },
  statusText: {
    marginBottom: 10,
    backgroundColor: 'green',
    padding: 10,
    fontSize: 20,
    textAlign: 'center',
  },
  banner: {
    // Set background color for banners to be fully functional
    backgroundColor: '#000000',
    position: 'absolute',
    width: '100%',
    height: 300,
    bottom: Platform.select({
      ios: 36, // For bottom safe area
      android: 0,
    })
  }
});

export default App;