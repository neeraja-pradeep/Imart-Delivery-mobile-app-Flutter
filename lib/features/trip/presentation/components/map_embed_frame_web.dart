import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Web: a real `<iframe>`, identical to the design prototype.
Widget buildMapFrame(String url) {
  return HtmlElementView.fromTagName(
    key: ValueKey<String>(url),
    tagName: 'iframe',
    onElementCreated: (Object element) {
      final web.HTMLIFrameElement frame = element as web.HTMLIFrameElement
        ..src = url
        ..title = 'map';
      frame.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%';
    },
  );
}
