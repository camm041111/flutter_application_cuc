import 'package:cuc_research_portal/features/explore/widgets/news_rich_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta texto plano y los tres formatos del comunicado', () {
    final segments = parseNewsText(
      'Inicio **importante**, _énfasis_ y [sitio](https://example.com).',
    );

    expect(
        segments.map((segment) => segment.style),
        containsAllInOrder([
          NewsTextStyle.plain,
          NewsTextStyle.bold,
          NewsTextStyle.plain,
          NewsTextStyle.italic,
          NewsTextStyle.plain,
          NewsTextStyle.link,
          NewsTextStyle.plain,
        ]));
    expect(
        segments
            .firstWhere((segment) => segment.style == NewsTextStyle.link)
            .url,
        'https://example.com');
  });

  test('conserva como texto los enlaces con protocolos no permitidos', () {
    final segments = parseNewsText('[archivo](file:///privado)');

    expect(segments, hasLength(1));
    expect(segments.single.style, NewsTextStyle.plain);
    expect(segments.single.text, '[archivo](file:///privado)');
  });
}
