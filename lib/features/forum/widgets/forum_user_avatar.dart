part of 'forum_view.dart';

class ForumUserAvatar extends StatelessWidget {
  const ForumUserAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.size,
    this.color = AppColors.primary,
  });

  final String name;
  final String imageUrl;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl.trim(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarInitials(
                initials: initials,
                color: color,
              ),
            )
          : _AvatarInitials(initials: initials, color: color),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.initials, required this.color});

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'CU';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(1, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _areaColor(String area) {
  if (area.contains('Salud')) return const Color(0xFF6BD6FF);
  if (area.contains('Agro')) return const Color(0xFFFFC857);
  if (area.contains('Sociales')) return const Color(0xFFFF8C6B);
  if (area.contains('Naturales')) return const Color(0xFFB18CFF);
  if (area.contains('Econ')) return const Color(0xFFFFB86B);
  if (area.contains('Educ')) return const Color(0xFFFF7AB6);
  return AppColors.primary;
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
  if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
