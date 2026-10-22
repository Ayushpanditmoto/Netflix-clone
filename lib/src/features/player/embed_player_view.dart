import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  void Function(String url)? onPageFinished,
}) async {
  await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
  await controller.setBackgroundColor(const Color(0xFF000000));
  if (onProgress != null || onPageFinished != null) {
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: onProgress,
        onPageFinished: onPageFinished,
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
  const EmbedPlayerView({
    super.key,
    required this.url,
    this.onProgress,
    this.requiresIframe = false,
  });

  final Uri url;
  final ProgressCallback? onProgress;
  final bool requiresIframe;

  @override
  State<EmbedPlayerView> createState() => _EmbedPlayerViewState();
}

class _EmbedPlayerViewState extends State<EmbedPlayerView> {
  WebViewController? _controller;
  bool _isFullscreen = false;

  static const _portraitOrientations = <DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ];

  static const _landscapeOrientations = <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance == null) return;
    _load();
  }

  Future<void> _load() async {
    final controller = WebViewController.fromPlatformCreationParams(
      buildEmbedParams(),
    );
    await controller.addJavaScriptChannel(
      'fullscreenChannel',
      onMessageReceived: (message) {
        _setFullscreen(message.message == 'enter');
      },
    );
    await configureEmbedPlatform(
      controller,
      onProgress: widget.onProgress,
      onPageFinished: (_) => controller.runJavaScript(_fullscreenScript),
    );
    if (!mounted) return;
    setState(() => _controller = controller);
    if (widget.requiresIframe) {
      final escapedUrl = _escapeHtmlAttribute(widget.url.toString());
      await controller.loadHtmlString('''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      html, body, iframe { width: 100%; height: 100%; margin: 0; border: 0; }
      body { overflow: hidden; background: #000; }
    </style>
  </head>
  <body>
    <iframe
      src="$escapedUrl"
      title="Video player"
      allow="autoplay; fullscreen; encrypted-media; picture-in-picture"
      allowfullscreen>
    </iframe>
  </body>
</html>
        ''', baseUrl: 'https://vidbolt.pro/');
    } else {
      await controller.loadRequest(widget.url);
    }
  }

  void _setFullscreen(bool fullscreen) {
    if (!mounted || _isFullscreen == fullscreen) return;
    _isFullscreen = fullscreen;
    SystemChrome.setEnabledSystemUIMode(
      fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    SystemChrome.setPreferredOrientations(
      fullscreen ? _landscapeOrientations : _portraitOrientations,
    );
  }

  @override
  void dispose() {
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(_portraitOrientations);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const ColoredBox(color: Colors.black);
    return WebViewWidget(controller: controller);
  }
}

const _fullscreenScript = '''
  (function () {
    if (window.__flutterFullscreenListenerInstalled) return;
    window.__flutterFullscreenListenerInstalled = true;
    document.addEventListener('fullscreenchange', function () {
      if (window.fullscreenChannel) {
        window.fullscreenChannel.postMessage(
          document.fullscreenElement ? 'enter' : 'exit'
        );
      }
    });
  })();
''';

String _escapeHtmlAttribute(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
