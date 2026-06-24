import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> saveAndShareBytes({
  required String filename,
  required List<int> bytes,
  String? mimeType,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: mimeType)],
    subject: filename,
  );
  return file.path;
}

void downloadBytesInBrowser({
  required String filename,
  required List<int> bytes,
  required String mimeType,
}) {
  throw UnsupportedError('Use file_download_web on web');
}
