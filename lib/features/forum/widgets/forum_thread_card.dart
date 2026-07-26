import 'package:flutter/material.dart';

import '../../../core/constants/areas.dart';
import '../../../core/theme/app_theme.dart';
import '../models/forum_thread.dart';
import 'forum_thread_detail_sheet.dart';
import 'forum_user_avatar.dart';

class ForumThreadCard extends StatelessWidget {
  const ForumThreadCard({super.key, required this.thread});

  final ForumThread thread;

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ForumThreadDetailSheet(thread: thread),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = areaColor(thread.area);
    return InkWell(
      onTap: () => _openDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(thread.authorName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        Text(
                          '${thread.authorMeta} • ${_relativeTime(thread.createdAt)}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(thread.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                thread.content,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.muted, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Chip(
                      label: Text(
                          thread.area.isEmpty ? 'General' : thread.area)),
                  ...thread.tags.map((tag) => Chip(label: Text(tag))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 5),
                  Text('${thread.replyCount} comentarios',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
  if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
