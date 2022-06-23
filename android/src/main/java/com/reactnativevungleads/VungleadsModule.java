package com.reactnativevungleads;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import static com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter;

//Vungle
import com.vungle.warren.Vungle;
import com.vungle.warren.AdConfig;              // Custom ad configurations
import com.vungle.warren.InitCallback;          // Initialization callback
import com.vungle.warren.LoadAdCallback;        // Load ad callback
import com.vungle.warren.PlayAdCallback;        // Play ad callback
//import com.vungle.warren.VungleNativeAd;        // MREC ad
import com.vungle.warren.Banners;               // Banner ad
import com.vungle.warren.VungleBanner;          // Banner ad
import com.vungle.warren.Vungle.Consent;        // GDPR consent
import com.vungle.warren.VungleSettings;         // Minimum disk space
import com.vungle.warren.error.VungleException;  // onError message

import java.util.concurrent.TimeUnit;
import android.util.Log;
import android.text.TextUtils;
import android.app.Activity;
import android.content.Context;
import androidx.annotation.Nullable;
import android.os.Handler;
import android.view.WindowManager;
import android.widget.RelativeLayout;
import android.view.ViewGroup.LayoutParams;
import android.view.View;
import android.content.pm.ActivityInfo;


@ReactModule(name = VungleadsModule.NAME)
public class VungleadsModule extends ReactContextBaseJavaModule {
    public static final String NAME = "Vungleads";

    private static final String SDK_TAG = "Vungle Ads Sdk";
    private static final String TAG     = "Vungle Ads Module";


    public static  VungleadsModule instance;
    private static Activity          sCurrentActivity;
    private RelativeLayout bottomBannerView;
    public static final int BANNER_WIDTH = 320;
    public static final int BANNER_HEIGHT = 50;
    private VungleBanner vungleBanner;

    private Callback mInitCallback;

    // Parent Fields
    private boolean                  isPluginInitialized;
    private boolean                  isSdkInitialized;

    private final LoadAdCallback vungleLoadAdCallback = new LoadAdCallback() {
      @Override
      public void onAdLoad(String placementReferenceId) {
        WritableMap params = Arguments.createMap();
        params.putString( "adUnitId", placementReferenceId );
        sendReactNativeEvent( "OnVungleAvailable", params );

      }

      @Override
      public void onError(String placementReferenceId, VungleException exception) {
        Log.e(TAG, "onError: " + exception);

      }
    };

    private final PlayAdCallback vunglePlayAdCallback = new PlayAdCallback() {
      @Override
      public void onAdStart(String id) {
        // Ad experience started
        WritableMap params = Arguments.createMap();
        params.putString( "adUnitId", id );

        sendReactNativeEvent( "OnVungleDidShowAdForPlacementID", params );
      }

      @Override
      public void onAdViewed(String id) {
        // Ad has rendered
      }

      // Deprecated
      @Override
      public void onAdEnd(String id, boolean completed, boolean isCTAClicked) {

      }

      @Override
      public void onAdEnd(String id) {
        // Ad experience ended
        WritableMap params = Arguments.createMap();
        params.putString( "adUnitId", id );

        sendReactNativeEvent( "OnVungleDidCloseAdForPlacementID", params );
      }

      @Override
      public void onAdClick(String id) {
        // User clicked on ad
        WritableMap params = Arguments.createMap();
        params.putString( "adUnitId", id );

        sendReactNativeEvent( "OnVungleTrackClickForPlacementID", params );
      }

      @Override
      public void onAdRewarded(String id) {
        // User earned reward for watching an rewarded ad
        WritableMap params = Arguments.createMap();
        params.putString( "adUnitId", id );

        sendReactNativeEvent( "OnVungleRewardUserForPlacementID", params );
      }

      @Override
      public void onAdLeftApplication(String id) {
        // User has left app during an ad experience
        WritableMap params = Arguments.createMap();
        params.putString( "adUnitId", id );

        sendReactNativeEvent( "OnVungleWillLeaveApplicationForPlacementID", params );
      }

      @Override
      public void creativeId(String creativeId) {
        // Vungle creative ID to be displayed
      }

      @Override
      public void onError(String id, VungleException exception) {
        // Ad failed to play
        Log.e(TAG, "onError: failed to play");
      }
    };

    public static VungleadsModule getInstance()
    {
      return instance;
    }

    public VungleadsModule(ReactApplicationContext reactContext) {
        super(reactContext);
        instance = this;
        sCurrentActivity = reactContext.getCurrentActivity();
    }

    @Override
    @NonNull
    public String getName() {
        return NAME;
    }

    @Nullable
    private Activity maybeGetCurrentActivity()
    {
      // React Native has a bug where `getCurrentActivity()` returns null: https://github.com/facebook/react-native/issues/18345
      // To alleviate the issue - we will store as a static reference (WeakReference unfortunately did not suffice)
      if ( getReactApplicationContext().hasCurrentActivity() )
      {
        sCurrentActivity = getReactApplicationContext().getCurrentActivity();
      }

      return sCurrentActivity;
    }


    // Example method
    // See https://reactnative.dev/docs/native-modules-android
    @ReactMethod(isBlockingSynchronousMethod = true)
    public boolean isInitialized()
    {
      return isPluginInitialized && isSdkInitialized;
    }

    @ReactMethod
    public void initialize(final String sdkKey, final Callback callback)
    {
      // Check if Activity is available
      Activity currentActivity = maybeGetCurrentActivity();
      if ( currentActivity != null )
      {
        performInitialization( sdkKey, currentActivity, callback );
      }
      else
      {
        Log.d( TAG, "No current Activity found! Delaying initialization..." );

        new Handler().postDelayed(new Runnable()
        {
          @Override
          public void run()
          {
            Context contextToUse = maybeGetCurrentActivity();
            if ( contextToUse == null )
            {
              Log.d( TAG,"Still unable to find current Activity - initializing SDK with application context" );
              contextToUse = getReactApplicationContext();
            }

            performInitialization( sdkKey, contextToUse, callback );
          }
        }, TimeUnit.SECONDS.toMillis( 3 ) );
      }
    }

    @ReactMethod()
    public void loadInterstitial(String adUnitId)
    {
      if (Vungle.isInitialized()) {
        Vungle.loadAd(adUnitId, vungleLoadAdCallback);
      }
    }

    @ReactMethod()
    public void showInterstitial(String adUnitId)
    {
      if (Vungle.canPlayAd(adUnitId)) {
        Vungle.playAd(adUnitId, null, vunglePlayAdCallback);
      }

    }

    @ReactMethod()
    public void loadBottomBanner(String adUnitId)
    {
      if (Vungle.isInitialized()) {
        Banners.loadBanner(adUnitId, AdConfig.AdSize.BANNER, new LoadAdCallback() {
          @Override
          public void onAdLoad(String placementReferenceId) {
            showBottomBanner(placementReferenceId);
            WritableMap params = Arguments.createMap();
            params.putString( "adUnitId", placementReferenceId );
            sendReactNativeEvent( "OnVungleAvailable", params );

          }

          @Override
          public void onError(String placementReferenceId, VungleException exception) {
            Log.e(TAG, "onError: " + exception.getLocalizedMessage());

          }
        });
      }

    }

    @ReactMethod()
    public void showBottomBanner(String adUnitId)
    {
      if (Banners.canPlayAd(adUnitId, AdConfig.AdSize.BANNER)) {
        vungleBanner = Banners.getBanner(adUnitId, AdConfig.AdSize.BANNER, vunglePlayAdCallback);
        loadBannerView();
      }

    }

    @ReactMethod()
    public void unLoadAds(String adUnitId)
    {
      if (bottomBannerView != null && sCurrentActivity != null){
        sCurrentActivity.runOnUiThread(new Runnable() {
          @Override
          public void run() {
            bottomBannerView.setVisibility(View.INVISIBLE);
            bottomBannerView.removeAllViews();
            bottomBannerView = null;
            vungleBanner.destroyAd();

          }
        });

      }



    }

    private static  int toPixelUnits(int dipUnit) {
      float density = sCurrentActivity.getResources().getDisplayMetrics().density;
      return Math.round(dipUnit * density);
    }

    private void loadBannerView(){
      sCurrentActivity.runOnUiThread(new Runnable(){

        @Override
        public void run(){
          sCurrentActivity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
          //sCurrentActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);//横屏：根据传感器横向切换

          bottomBannerView = new RelativeLayout(sCurrentActivity.getApplicationContext());

          LayoutParams lp = new LayoutParams(LayoutParams.MATCH_PARENT,LayoutParams.MATCH_PARENT);
          sCurrentActivity.addContentView(bottomBannerView,lp);

          //RelativeLayout.LayoutParams bannerLayoutParams = new RelativeLayout.LayoutParams(LayoutParams.MATCH_PARENT,LayoutParams.WRAP_CONTENT);
          //bannerLayoutParams.setMargins(5, 5, 5, 5);

          int width = toPixelUnits(BANNER_WIDTH);
          int height = toPixelUnits(BANNER_HEIGHT);
          RelativeLayout.LayoutParams bannerLayoutParams = new RelativeLayout.LayoutParams(width, height);
          bannerLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
          bannerLayoutParams.addRule(RelativeLayout.CENTER_HORIZONTAL);

          //bottomBannerView.addView( applovin_adView, new android.widget.FrameLayout.LayoutParams( ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, Gravity.CENTER ) );
          bottomBannerView.addView( vungleBanner,bannerLayoutParams);


        }
      });
    }

    private void performInitialization(final String sdkKey, final Context context, final Callback callback)
    {
      // Guard against running init logic multiple times
      if ( isPluginInitialized ) return;

      isPluginInitialized = true;


      // If SDK key passed in is empty
      if ( TextUtils.isEmpty( sdkKey ) )
      {
        throw new IllegalStateException( "Unable to initialize Unity Ads SDK - no SDK key provided!" );
      }

      // Initialize SDK
      mInitCallback = callback;
      Vungle.init(sdkKey, sCurrentActivity.getApplicationContext(), new InitCallback() {
        @Override
        public void onSuccess() {
          // SDK has successfully initialized
          Log.d(TAG, "SDK initialized" );
          isSdkInitialized = true;
          mInitCallback.invoke( "success" );
        }

        @Override
        public void onError(VungleException exception) {
          // SDK has failed to initialize
          mInitCallback.invoke( "failed: "+ exception.getLocalizedMessage() );
        }

        @Override
        public void onAutoCacheAdAvailable(String placementId) {
          // Ad has become available to play for a cache optimized placement
        }
      });

    }

    // React Native Bridge
    private void sendReactNativeEvent(final String name, @Nullable final WritableMap params)
    {
      getReactApplicationContext()
        .getJSModule( RCTDeviceEventEmitter.class )
        .emit( name, params );
    }
}
