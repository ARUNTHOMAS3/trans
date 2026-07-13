import 'package:file_picker/file_picker.dart';

/// A [PlatformFile] wrapper that safely permits accessing the `path` property on Web.
/// Standard [PlatformFile] throws an [UnimplementedError] on Web when accessing the `path` getter.
class WebSafePlatformFile extends PlatformFile {
  final String? _webSafePath;

  WebSafePlatformFile({
    String? path,
    required super.name,
    required super.size,
    super.bytes,
    super.readStream,
  })  : _webSafePath = path,
        super(path: path);

  @override
  String? get path => _webSafePath;
}
