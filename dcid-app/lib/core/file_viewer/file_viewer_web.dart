import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void openFileWeb(Uint8List bytes, String filename, String contentType) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: contentType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.target = '_blank';
  anchor.rel = 'noopener noreferrer';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();

  // Clean up object URL after 2 minutes to prevent memory leak
  Future.delayed(const Duration(minutes: 2), () {
    web.URL.revokeObjectURL(url);
  });
}

void openFileStub(Uint8List bytes, String filename, String contentType) {}
