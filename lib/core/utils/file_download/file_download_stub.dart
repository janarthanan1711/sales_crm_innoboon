import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Mobile/desktop fallback — `file_picker`'s save dialog writes [bytes] to
/// the chosen location directly on mobile platforms.
Future<void> downloadBytes(Uint8List bytes, String fileName) async {
  await FilePicker.platform.saveFile(fileName: fileName, bytes: bytes);
}
