import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_theme.dart';

class RepositoryFileDownloadTile extends StatefulWidget {
  const RepositoryFileDownloadTile({
    super.key,
    required this.fileUrl,
  });

  final String fileUrl;

  @override
  State<RepositoryFileDownloadTile> createState() =>
      RepositoryFileDownloadTileState();
}

class RepositoryFileDownloadTileState
    extends State<RepositoryFileDownloadTile> {
  bool _downloading = false;

  String get _fileName => repositoryFileNameFromUrl(widget.fileUrl);
  String get _extension => repositoryFileExtension(_fileName);

  Future<void> _downloadOrOpen() async {
    if (_downloading) {
      return;
    }

    setState(() => _downloading = true);
    try {
      final file = await downloadRepositoryFile(widget.fileUrl);

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el archivo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              repositoryFileIcon(_extension),
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _extension,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Descargar',
            onPressed: _downloading ? null : _downloadOrOpen,
            icon: _downloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.download_rounded,
                    size: 21,
                    color: AppColors.primary,
                  ),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

Future<File> downloadRepositoryFile(String fileUrl) async {
  final repositoryDirectory = await repositoryDownloadDirectory();

  final fileName = repositoryFileNameFromUrl(fileUrl);
  final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  final urlPrefix = fileUrl.hashCode.toUnsigned(32).toRadixString(16);
  final file = File('${repositoryDirectory.path}/${urlPrefix}_$safeName');
  if (await file.exists()) return file;

  final request = await HttpClient().getUrl(Uri.parse(fileUrl));
  final response = await request.close();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('No se pudo descargar "$fileName".');
  }
  await response.pipe(file.openWrite());
  return file;
}

Future<Directory> repositoryDownloadDirectory() async {
  Directory? downloadsDirectory;
  try {
    downloadsDirectory = await getDownloadsDirectory();
  } catch (_) {
    // Algunas plataformas no exponen una carpeta pública de descargas.
  }
  final baseDirectory =
      downloadsDirectory ?? await getApplicationDocumentsDirectory();
  final repositoryDirectory = Directory('${baseDirectory.path}/repositorio');
  if (!await repositoryDirectory.exists()) {
    await repositoryDirectory.create(recursive: true);
  }
  return repositoryDirectory;
}

String repositoryFileNameFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.pathSegments.isEmpty) {
    return 'documento';
  }

  final encodedName = uri.pathSegments.last;
  try {
    return Uri.decodeComponent(encodedName);
  } on FormatException {
    return encodedName;
  }
}

String repositoryFileExtension(String fileName) {
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
    return 'ARCHIVO';
  }
  return fileName.substring(dotIndex + 1).toUpperCase();
}

IconData repositoryFileIcon(String extension) {
  switch (extension) {
    case 'PDF':
      return Icons.picture_as_pdf_outlined;
    case 'JPG':
    case 'JPEG':
    case 'PNG':
    case 'WEBP':
      return Icons.image_outlined;
    case 'DOC':
    case 'DOCX':
      return Icons.description_outlined;
    case 'TXT':
      return Icons.notes_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}
