import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../social/social_providers.dart';

class ForumReplyComposer extends StatelessWidget {
  const ForumReplyComposer({
    super.key,
    required this.profileAsync,
    required this.controller,
    required this.focusNode,
    required this.parentReplyAuthor,
    required this.saving,
    required this.onClearParent,
    required this.onSubmit,
  });

  final AsyncValue<SocialProfile?> profileAsync;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? parentReplyAuthor;
  final bool saving;
  final VoidCallback onClearParent;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: profileAsync.maybeWhen(
            data: (profile) {
              if (profile?.isActive != true) {
                return const Text(
                  'Tu perfil esta en modo solo lectura.',
                  style: TextStyle(color: AppColors.muted),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parentReplyAuthor != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InputChip(
                        label: Text('Respondiendo a $parentReplyAuthor'),
                        onDeleted: onClearParent,
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Escribe un comentario...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Enviar comentario',
                        onPressed: saving ? null : onSubmit,
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.background,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                      ),
                    ],
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
