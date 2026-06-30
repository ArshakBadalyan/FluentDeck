import 'dart:html' as html;

Future<String> saveAndShareBytes({
  required String filename,
  required List<int> bytes,
  String? mimeType,
}) async {
  downloadBytesInBrowser(
    filename: filename,
    bytes: bytes,
    mimeType: mimeType ?? 'application/octet-stream',
  );
  return filename;
}

void downloadBytesInBrowser({
  required String filename,
  required List<int> bytes,
  required String mimeType,
}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor =
      html.AnchorElement(href: url)
        ..download = filename
        ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
