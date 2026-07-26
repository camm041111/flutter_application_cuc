const int maxSocialTags = 3;
const int maxSocialTagLength = 30;

String normalizeSocialTag(String value) {
  return value
      .trim()
      .replaceFirst(RegExp(r'^#+'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool containsSocialTag(Iterable<String> tags, String candidate) {
  final normalizedCandidate = normalizeSocialTag(candidate).toLowerCase();
  return tags.any(
    (tag) => normalizeSocialTag(tag).toLowerCase() == normalizedCandidate,
  );
}

List<String> sanitizeSocialTags(
  Iterable<String> values, {
  int limit = maxSocialTags,
}) {
  final result = <String>[];

  for (final value in values) {
    final tag = normalizeSocialTag(value);
    if (tag.isEmpty ||
        tag.length > maxSocialTagLength ||
        containsSocialTag(result, tag)) {
      continue;
    }
    result.add(tag);
    if (result.length == limit) break;
  }

  return result;
}

String clubAbbreviation(String? clubName) {
  final words = (clubName ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'SIN CLUB';

  const ignoredWords = {'de', 'del', 'la', 'las', 'el', 'los', 'y', 'e'};
  final meaningfulWords = words
      .where((word) => !ignoredWords.contains(word.toLowerCase()))
      .toList();
  final source = meaningfulWords.isEmpty ? words : meaningfulWords;

  if (source.length == 1) {
    final word = source.first.toUpperCase();
    return word.length <= 5 ? word : word.substring(0, 5);
  }

  return source
      .take(5)
      .map((word) => word.substring(0, 1).toUpperCase())
      .join();
}
