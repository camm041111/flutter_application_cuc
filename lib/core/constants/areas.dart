import 'package:flutter/material.dart';

const areaOptions = {
  'Ingeniería y Tecnología': 'Ingeniería y Tecnología',
  'Ciencias de la Salud': 'Ciencias de la Salud',
  'Ciencias Agropecuarias': 'Ciencias Agropecuarias',
  'Ciencias Sociales y Humanidades': 'Ciencias Sociales y Humanidades',
  'Ciencias Naturales y Exactas': 'Ciencias Naturales y Exactas',
  'Ciencias Económico Administrativas': 'Ciencias Económico Administrativas',
  'Educación y Artes': 'Educación y Artes',
};

Color areaColor(String area) {
  if (area.contains('Salud')) return const Color(0xFF6BD6FF);
  if (area.contains('Agro')) return const Color(0xFFFFC857);
  if (area.contains('Sociales')) return const Color(0xFFFF8C6B);
  if (area.contains('Naturales')) return const Color(0xFFB18CFF);
  if (area.contains('Econ')) return const Color(0xFFFFB86B);
  if (area.contains('Educ')) return const Color(0xFFFF7AB6);
  return const Color(0xFF6EE718);
}
