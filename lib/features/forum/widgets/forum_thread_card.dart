part of 'forum_view.dart';

class _ForumThreadCard extends StatelessWidget {
  const _ForumThreadCard({required this.thread});

  final ForumThread thread;

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ThreadDetailSheet(thread: thread),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _areaColor(thread.area);

    return InkWell(
      onTap: () => _openDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Fondo gris oscuro elegante (asumiendo que AppColors.surface está mapeado a un #121212 o #1E1E1E)
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // Borde perimetral muy tenue para mantener el minimalismo sin usar sombras
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ForumUserAvatar(
                  name: thread.authorName,
                  imageUrl: thread.authorAvatarUrl,
                  size: 36,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.authorName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          // Tipografía limpia sin serifas heredada del tema global
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${thread.authorMeta} • ${_relativeTime(thread.createdAt)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              thread.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2, // Ligero espaciado para lectura técnica
              ),
            ),
            const SizedBox(height: 8),
            Text(
              // 🛡️ STRIPPING: Limpiamos los asteriscos, guiones y sintaxis de enlaces para la vista previa
              thread.content.replaceAll(RegExp(r'(\*\*|_|\[|\]|\(.*?\))'), ''),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                NewsTag(
                  label: thread.area.isEmpty ? 'General' : thread.area,
                  // El tag hereda el color del área, pero puedes forzar el Pantone 362 C si es oficial
                ),
                ...thread.tags.map((tag) => NewsTag(label: tag)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.border),
            ),
            Row(
              children: [
                const Icon(Icons.forum_outlined, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  '${thread.replyCount} respuestas',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Ver discusión',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    // Pantone 356 C o 362 C institucional (Verde oscuro/medio) mapeado en tu AppColors.primary
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}