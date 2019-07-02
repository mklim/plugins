// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.content.Context;
import android.view.View;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.view.FlutterView;

import java.util.Map;

public class WebViewFactory extends PlatformViewFactory {
  private final BinaryMessenger messenger;
  private View flutterView;

  public WebViewFactory(BinaryMessenger messenger, View flutterView) {
    super(StandardMessageCodec.INSTANCE);
    this.messenger = messenger;
    this.flutterView = flutterView;
  }

  @SuppressWarnings("unchecked")
  @Override
  public PlatformView create(Context context, int id, Object args) {
    Map<String, Object> params = (Map<String, Object>) args;
    return new FlutterWebView(context, messenger, id, params, flutterView);
  }
}
