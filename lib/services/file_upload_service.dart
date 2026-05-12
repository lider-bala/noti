import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadedSchoolFile {
  final String fileName;
  final String sizeLabel;
  final String storagePath;
  final String downloadUrl;
  final String? contentType;

  const UploadedSchoolFile({
    required this.fileName,
    required this.sizeLabel,
    required this.storagePath,
    required this.downloadUrl,
    this.contentType,
  });
}

class FileUploadService {
  static const int maxUploadBytes = 25 * 1024 * 1024;
  final FirebaseStorage _storage;

  FileUploadService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<UploadedSchoolFile?> pickAndUpload({
    required String folder,
    required String ownerId,
  }) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    if (file.size > maxUploadBytes) {
      throw StateError('Файл слишком большой. Максимум 25 МБ.');
    }
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Не удалось прочитать выбранный файл.');
    }

    final cleanName = _safeSegment(file.name);
    final cleanFolder = _safePath(folder);
    final cleanOwner = _safeSegment(ownerId);
    final storagePath =
        'schools/default/$cleanFolder/$cleanOwner/${DateTime.now().microsecondsSinceEpoch}_$cleanName';
    final contentType = _contentType(file.name);
    final ref = _storage.ref(storagePath);

    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'originalName': file.name,
          'ownerId': ownerId,
        },
      ),
    );

    return UploadedSchoolFile(
      fileName: file.name,
      sizeLabel: _formatBytes(file.size),
      storagePath: storagePath,
      downloadUrl: await ref.getDownloadURL(),
      contentType: contentType,
    );
  }

  String _safeSegment(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9А-Яа-яёЁ._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  String _safePath(String value) {
    return value
        .split('/')
        .map(_safeSegment)
        .where((segment) => segment.isNotEmpty)
        .join('/');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes Б';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} КБ';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} МБ';
  }

  String? _contentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return null;
  }
}
