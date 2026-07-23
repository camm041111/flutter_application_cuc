import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

enum NewsTextStyle { plain, bold, italic, link }

class NewsTextSegment {
  const NewsTextSegment(this.text, this.style, {this.url});

  final String text;
  final NewsTextStyle style;
  final String? url;
}

/// Interpreta el formato ligero que se guarda en `noticias.contenido`.
/// El texto plano publicado antes de esta funcionalidad sigue funcionando.
List<NewsTextSegment> parseNewsText(String source) {
  final segments = <NewsTextSegment>[];
  final token = RegExp(
      r'\[([^\]\n]+)\]\((https?:\/\/[^\s)]+)\)|\*\*([^*\n]+)\*\*|_([^_\n]+)_');
  var offset = 0;

  for (final match in token.allMatches(source)) {
    if (match.start > offset) {
      segments.add(NewsTextSegment(
          source.substring(offset, match.start), NewsTextStyle.plain));
    }
    if (match.group(1) != null) {
      segments.add(NewsTextSegment(match.group(1)!, NewsTextStyle.link,
          url: match.group(2)));
    } else if (match.group(3) != null) {
      segments.add(NewsTextSegment(match.group(3)!, NewsTextStyle.bold));
    } else {
      segments.add(NewsTextSegment(match.group(4)!, NewsTextStyle.italic));
    }
    offset = match.end;
  }

  if (offset < source.length) {
    segments
        .add(NewsTextSegment(source.substring(offset), NewsTextStyle.plain));
  }
  return segments;
}

class NewsRichText extends StatefulWidget {
  const NewsRichText({super.key, required this.content});

  final String content;

  @override
  State<NewsRichText> createState() => _NewsRichTextState();
}

class _NewsRichTextState extends State<NewsRichText> {
  final List<TapGestureRecognizer> _recognizers = [];
  late List<NewsTextSegment> _segments;
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _segments = parseNewsText(widget.content);
    _spans = _createSpans();
  }

  @override
  void didUpdateWidget(covariant NewsRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      for (final recognizer in _recognizers) {
        recognizer.dispose();
      }
      _recognizers.clear();
      _segments = parseNewsText(widget.content);
      _spans = _createSpans();
    }
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmAndOpen(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) return;

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.open_in_new, color: AppColors.primary),
        title: const Text('Abrir enlace externo'),
        content: const Text(
            'Estás a punto de salir de la aplicación. ¿Deseas continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (shouldOpen == true && mounted) {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No fue posible abrir el enlace.')),
        );
      }
    }
  }

  List<InlineSpan> _createSpans() {
    final spans = <InlineSpan>[];
    for (final segment in _segments) {
      switch (segment.style) {
        case NewsTextStyle.bold:
          spans.add(TextSpan(
              text: segment.text,
              style: const TextStyle(fontWeight: FontWeight.w700)));
        case NewsTextStyle.italic:
          spans.add(TextSpan(
              text: segment.text,
              style: const TextStyle(fontStyle: FontStyle.italic)));
        case NewsTextStyle.link:
          final recognizer = TapGestureRecognizer()
            ..onTap = () => _confirmAndOpen(segment.url!);
          _recognizers.add(recognizer);
          spans.add(TextSpan(
            text: segment.text,
            recognizer: recognizer,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ));
        case NewsTextStyle.plain:
          spans.add(TextSpan(text: segment.text));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    const baseStyle =
        TextStyle(fontSize: 13, color: AppColors.onSurface, height: 1.5);
    return Text.rich(TextSpan(style: baseStyle, children: _spans));
  }
}
