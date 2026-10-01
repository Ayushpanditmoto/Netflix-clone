import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/movie.dart';
import 'embed_player_view.dart';

/// Unawaited, for handing off links to the system browser from the delegate.
void unawaited(Future<void> future) {}

/// In-app playback for CineSrc-style embed pages.
///
/// The embed is rendered by a WebView rather than a raw <iframe>: Flutter on
/// Android and iOS has no iframe element, and a WebView gives the same result.
/// It also sidesteps the two blocks that stop direct HLS playback in a plain
/// browser. Because the embed page itself is served from the provider's own
/// origin, its media requests carry `Origin: https://cinesrc.st`, which the CDN
/// accepts, and they originate from this device's IP rather than a data-centre
/// one. Flutter web cannot host a WebView; open the provider page there.
class WebPlayerScreen extends StatefulWidget {
  const WebPlayerScreen({super.key, required this.movie, this.url});

  final Movie movie;
  final Uri? url;

  @override
  State<WebPlayerScreen> createState() => _WebPlayerScreenState();
}

class _WebPlayerScreenState extends State<WebPlayerScreen> {
  WebViewController? _controller;
  int _loadingProgress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final controller = WebViewController.fromPlatformCreationParams(
      buildEmbedParams(),
    );
    await configureEmbedPlatform(
      controller,
      onProgress: (progress) {
        if (mounted) setState(() => _loadingProgress = progress);
      },
    );
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (progress) {
          if (mounted) setState(() => _loadingProgress = progress);
        },
        onWebResourceError: (error) {
          // Sub-resource failures are noisy on these embed pages, so only
          // surface a failure of the main document.
          if (error.isForMainFrame != true) return;
          if (mounted) setState(() => _error = 'Could not load this source.');
        },
        onNavigationRequest: (request) {
          // These embed pages navigate themselves: a server redirect or a
          // script may send the frame to a host unrelated to the provider.
          // Loading anything web-like in the player keeps playback in-app;
          // only non-web schemes (intent://, market://, tel:) leave the app.
          final uri = Uri.tryParse(request.url);
          if (uri == null) return NavigationDecision.prevent;
          if (uri.scheme == 'http' || uri.scheme == 'https') {
            return NavigationDecision.navigate;
          }
          unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
          return NavigationDecision.prevent;
        },
      ),
    );

    if (!mounted) return;
    setState(() => _controller = controller);

    await controller.loadRequest(widget.url ?? Uri.parse(_defaultUrl));
  }

  String get _defaultUrl =>
      'https://cinesrc.st/embed/${widget.movie.mediaType}/${widget.movie.id}';

Future<void> _goBack() async {
    final controller = _controller;
    if (controller == null || !await controller.canGoBack()) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await controller.goBack();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBack,
        ),
        title: Text(widget.movie.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.black,
        actions: [
          if (controller != null)
            IconButton(
              tooltip: 'Reload',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => controller.reload(),
            ),
        ],
        bottom: _loadingProgress > 0 && _loadingProgress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  minHeight: 2,
                  backgroundColor: Colors.white12,
                  color: const Color(0xFFE50914),
                ),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: controller == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  WebViewWidget(controller: controller),
                  if (_error != null)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black87,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () {
                                    setState(() => _error = null);
                                    controller.reload();
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
