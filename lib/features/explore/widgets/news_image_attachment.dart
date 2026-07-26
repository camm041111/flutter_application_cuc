import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import '../../../core/theme/app_theme.dart';

class NewsImageAttachment extends StatefulWidget {
  const NewsImageAttachment({
    super.key,
    required this.imageUrl,
    required this.newsId,
  });

  final String imageUrl;
  final String newsId;

  @override
  State<NewsImageAttachment> createState() => _NewsImageAttachmentState();
}

class _NewsImageAttachmentState extends State<NewsImageAttachment> {
  bool _downloading = false;

  String get _heroTag => 'news-image-${widget.newsId}';

  Future<void> _downloadImage() async {
    if (_downloading) return;
    setState(() => _downloading = true);

    try {
      final bytes = await _downloadImageBytes(widget.imageUrl);
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name:
            'cuc_noticia_${widget.newsId}_${DateTime.now().millisecondsSinceEpoch}',
      );
      final saved = result is Map &&
          (result['isSuccess'] == true || result['isSuccess'] == 'true');
      if (!saved) throw Exception('El dispositivo no pudo guardar la imagen.');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen guardada en tu galería.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la imagen. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _openViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NewsImageViewer(
          imageUrl: widget.imageUrl,
          heroTag: _heroTag,
          onDownload: _downloadImage,
          isDownloading: _downloading,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir imagen de la noticia',
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Material(
            color: AppColors.background,
            child: InkWell(
              onTap: _openViewer,
              child: Hero(
                tag: _heroTag,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => const AspectRatio(
                    aspectRatio: 4 / 3,
                    child: _NewsImageError(),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Guardar imagen',
                onPressed: _downloading ? null : _downloadImage,
                color: Colors.white,
                icon: _downloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsImageViewer extends StatelessWidget {
  const _NewsImageViewer({
    required this.imageUrl,
    required this.heroTag,
    required this.onDownload,
    required this.isDownloading,
  });

  final String imageUrl;
  final String heroTag;
  final VoidCallback onDownload;
  final bool isDownloading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Imagen de la noticia'),
        actions: [
          IconButton(
            tooltip: 'Guardar imagen',
            onPressed: isDownloading ? null : onDownload,
            icon: isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: Center(
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              placeholder: (_, __) => const CircularProgressIndicator(
                color: AppColors.primary,
              ),
              errorWidget: (_, __, ___) => const _NewsImageError(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsImageError extends StatelessWidget {
  const _NewsImageError();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image_outlined, color: AppColors.muted, size: 32),
        SizedBox(height: 8),
        Text(
          'No se pudo cargar la imagen',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

Future<Uint8List> _downloadImageBytes(String imageUrl) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(imageUrl));
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Respuesta HTTP ${response.statusCode}');
    }

    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  } finally {
    client.close(force: true);
  }
}
