import 'package:flutter/foundation.dart';
import 'file_viewer_stub.dart'
    if (dart.library.js_interop) 'file_viewer_web.dart'
    as platform;

void openOrDownloadFile(Uint8List bytes, String filename, String contentType) {
  if (kIsWeb) {
    platform.openFileWeb(bytes, filename, contentType);
  } else {
    platform.openFileStub(bytes, filename, contentType);
  }
}
