// ignore_for_file: deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a browser download of [bytes] named [fileName].
Future<void> downloadBytes(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.document.body?.append(
    html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none'
      ..click(),
  );
  html.Url.revokeObjectUrl(url);
}
