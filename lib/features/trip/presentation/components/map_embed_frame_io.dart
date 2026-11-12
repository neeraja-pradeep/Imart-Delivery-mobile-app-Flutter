import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Android / iOS: the embed inside a WebView; other platforms: blank.
Widget buildMapFrame(String url) {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return const SizedBox.expand();
  }
  return _MapWebView(key: ValueKey<String>(url), url: url);
}

class _MapWebView extends StatefulWidget {
  const _MapWebView({super.key, required this.url});

  final String url;

  @override
  State<_MapWebView> createState() => _MapWebViewState();
}

class _MapWebViewState extends State<_MapWebView> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(widget.url));

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
