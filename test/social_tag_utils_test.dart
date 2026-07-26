import 'package:cuc_research_portal/core/utils/social_tag_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeSocialTags', () {
    test('normaliza espacios, hashtags y duplicados sin distinguir mayúsculas',
        () {
      final tags = sanitizeSocialTags([
        '  #Inteligencia   Artificial ',
        'inteligencia artificial',
        'Convocatoria',
      ]);

      expect(tags, ['Inteligencia Artificial', 'Convocatoria']);
    });

    test('mantiene las etiquetas opcionales y limita su cantidad', () {
      expect(sanitizeSocialTags(const []), isEmpty);
      expect(
        sanitizeSocialTags(['uno', 'dos', 'tres', 'cuatro']),
        ['uno', 'dos', 'tres'],
      );
    });
  });

  group('clubAbbreviation', () {
    test('crea iniciales ignorando conectores', () {
      expect(
        clubAbbreviation('Club de Inteligencia Artificial y Robótica'),
        'CIAR',
      );
    });

    test('usa un estado explícito cuando no existe club', () {
      expect(clubAbbreviation(null), 'SIN CLUB');
    });
  });
}
