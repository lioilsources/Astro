import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Shares [bytes] as a file named [name]. On phones through a temp file and the share sheet (as
/// before); on the web straight from memory (the Web Share API where the browser has it, otherwise
/// a download), since there is no file system.
Future<void> shareBytes(List<int> bytes, String name, String mimeType, {String? subject}) async {
  final XFile file;
  if (kIsWeb) {
    file = XFile.fromData(Uint8List.fromList(bytes), name: name, mimeType: mimeType);
  } else {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$name');
    await f.writeAsBytes(bytes, flush: true);
    file = XFile(f.path, mimeType: mimeType);
  }
  await SharePlus.instance.share(
    ShareParams(files: [file], subject: subject, fileNameOverrides: kIsWeb ? [name] : null),
  );
}
