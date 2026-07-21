import 'dart:js_interop';
import 'dart:typed_data';

@JS('URL.createObjectURL')
external String _createObjectURL(JSObject blob);

@JS('Blob')
external JSObject _createBlob(JSArray sequence, [JSObject? options]);

@JS('window.open')
external void _windowOpen(String url, String target);

void openFileWeb(Uint8List bytes, String filename, String contentType) {
  final sequence = [bytes.toJS].toJS;
  final options = {'type': contentType}.jsify() as JSObject;
  final blob = _createBlob(sequence, options);
  final url = _createObjectURL(blob);
  _windowOpen(url, '_blank');
}

void openFileStub(Uint8List bytes, String filename, String contentType) {}
