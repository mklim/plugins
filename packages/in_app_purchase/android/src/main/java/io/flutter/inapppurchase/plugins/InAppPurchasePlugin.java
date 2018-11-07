package io.flutter.plugins.inapppurchase;

import android.content.Context;
import android.support.annotation.Nullable;
import android.util.Log;

import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.SkuDetails;
import com.android.billingclient.api.SkuDetailsParams;
import com.android.billingclient.api.SkuDetailsResponseListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** Wraps a {@link BillingClient} instance and responds to Dart calls for it. */
public class InAppPurchasePlugin implements MethodCallHandler {
  private static final String TAG = "InAppPurchasePlugin";
  private final BillingClient mBillingClient;
  private final MethodChannel mChannel;
  private final OnPurchaseUpdatedListener mOnPurchaseUpdatedListener;
  private static final String ERROR_CODE_NOT_INITIALIZED = "not_initialized";
  private static final String ERROR_DESCRIPTION_NOT_INITIALIZED = "Billing client not initialized";

  private static class OnPurchaseUpdatedListener implements PurchasesUpdatedListener {
    public void onPurchasesUpdated(int responseCode, @Nullable List<Purchase> purchases) {
      Log.i(TAG, purchases.toString() + " updated with responseCode " + responseCode);
    }
  }

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "plugins.flutter.io/in_app_purchase");
    channel.setMethodCallHandler(new InAppPurchasePlugin(registrar.context(), channel));
  }

  public InAppPurchasePlugin(Context context, MethodChannel channel) {
    mOnPurchaseUpdatedListener = new OnPurchaseUpdatedListener();
    mBillingClient = BillingClient.newBuilder(context).setListener(mOnPurchaseUpdatedListener).build();
    mChannel = channel;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    switch (call.method) {
      case "isReady": {
        isReady(result);
        break;
      }
      case "startConnection": {
        startConnection((int) call.argument("handle"), result);
        break;
      }
      case "querySkuDetailsAsync": {
        querySkuDetailsAsync((String) call.argument("skuType"), (ArrayList<String>) call.argument("skusList"), result);
        break;
      }
      default: {
        result.notImplemented();
      }
    }
  }

  private void startConnection(final int handle, final Result result) {
    mBillingClient.startConnection(new BillingClientStateListener() {
      @Override
      public void onBillingSetupFinished(int responseCode) {
        result.success(responseCode);
      }

      @Override
      public void onBillingServiceDisconnected() {
        final Map<String, Object> arguments = new HashMap<>();
        arguments.put("handle", handle);
        mChannel.invokeMethod("onBillingServiceDisconnected", new HashMap<>());
      }
    });
  }

  private void querySkuDetailsAsync(String skuType, List<String> skusList, final Result result) {
    SkuDetailsParams params = SkuDetailsParams.newBuilder().setType(skuType).setSkusList(skusList).build();
    mBillingClient.querySkuDetailsAsync(params, new SkuDetailsResponseListener() {
      public void onSkuDetailsResponse(int responseCode, List<SkuDetails> skuDetailsList) {
        final Map<String, Object> skuDetailsResponse = new HashMap<>();
        skuDetailsResponse.put("responseCode", responseCode);
        ArrayList<HashMap<String, Object>> skuDetailsInfo = new ArrayList<>();
        for (SkuDetails detail : skuDetailsList) {
          skuDetailsInfo.add(skuDetailsToMap(detail));
        }
        skuDetailsResponse.put("skuDetailsList", skuDetailsInfo);
        result.success(skuDetailsResponse);
      }
    });
  }

  private void isReady(Result result) {
    result.success(mBillingClient.isReady());
  }

  private static HashMap<String, Object> skuDetailsToMap(SkuDetails detail) {
    HashMap<String, Object> info = new HashMap<>();
    info.put("title", detail.getTitle());
    info.put("description", detail.getDescription());
    info.put("freeTrailPeriod", detail.getFreeTrialPeriod());
    info.put("introductoryPrice", detail.getIntroductoryPrice());
    info.put("introductoryPriceAmountMicros", detail.getIntroductoryPriceAmountMicros());
    info.put("introductoryPriceCycles", detail.getIntroductoryPriceCycles());
    info.put("introductoryPricePeriod", detail.getIntroductoryPricePeriod());
    info.put("price", detail.getPrice());
    info.put("priceAmountMicros", detail.getPriceAmountMicros());
    info.put("priceCurrencyCode", detail.getPriceCurrencyCode());
    info.put("sku", detail.getSku());
    info.put("type", detail.getType());
    info.put("isRewarded", detail.isRewarded());
    return info;
  }
}
