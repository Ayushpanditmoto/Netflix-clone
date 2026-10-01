import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Desktop Chrome UA. Some embed providers serve a degraded player to
/// recognisable mobile WebView agents.
const embedUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

/// Creation params that let the page play video inline instead of taking
/// over the whole screen on iOS.
PlatformWebViewControllerCreationParams buildEmbedParams() {
  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    return WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
  }
  return const PlatformWebViewControllerCreationParams();
}

/// Applies the settings every embed needs: autoplay with sound, a desktop UA
/// and permissive mixed content (many providers mix https and http assets).
Future<void> configureEmbedPlatform(
  WebViewController controller, {
  ProgressCallback? onProgress,
}) async {
  await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
  await controller.setBackgroundColor(const Color(0xFF000000));
  if (onProgress != null) {
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: onProgress,
        onNavigationRequest: (request) {
          // Embed pages navigate themselves via script or redirect to hosts
          // unrelated to the provider. Load anything web-like here so playback
          // stays in-app; only non-web schemes leave the app.
          final uri = Uri.tryParse(request.url);
          if (uri == null) return NavigationDecision.prevent;
          if (uri.scheme == 'http' || uri.scheme == 'https') {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ),
    );
  }

  final platform = controller.platform;
  if (platform is AndroidWebViewController) {
    AndroidWebViewController.enableDebugging(false);
    await platform.setMediaPlaybackRequiresUserGesture(false);
    await platform.setUserAgent(embedUserAgent);
    await platform.setMixedContentMode(MixedContentMode.alwaysAllow);
  } else if (platform is WebKitWebViewController) {
    await platform.setAllowsBackForwardNavigationGestures(false);
  }
}

/// A single live embed player.
///
/// The underlying platform WebView is released when this widget leaves the
/// tree, so swapping [url] by changing this widget's [key] tears the old player
/// down and stops its audio before a new one starts. Holding several of these
/// at once would keep every audio track alive and waste a lot of memory.
class EmbedPlayerView extends StatefulWidget {
  const EmbedPlayerView({super.key, required this.url, this.onProgress});

  final Uri url;
  final ProgressCallback? onProgress;

  @override
  State<EmbedPlayerView> createState() => _EmbedPlayerViewState();
}

class _EmbedPlayerViewState extends State<EmbedPlayerView> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = WebViewController.fromPlatformCreationParams(
      buildEmbedParams(),
    );
    await configureEmbedPlatform(controller, onProgress: widget.onProgress);
    if (!mounted) return;
    setState(() => _controller = controller);
    await controller.loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const ColoredBox(color: Colors.black);
    return WebViewWidget(controller: controller);
  }
}