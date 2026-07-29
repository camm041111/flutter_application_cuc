import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/social_tag_utils.dart';
import '../../../core/widgets/correct_snackbar.dart';
import '../../../core/widgets/rich_text_editor_toolbar.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/forum_providers.dart';

class ThreadComposerSheet extends ConsumerStatefulWidget {
  const ThreadComposerSheet({super.key});

  @override
  ConsumerState<ThreadComposerSheet> createState() =>
      _ThreadComposerSheetState();
}

class _ThreadComposerSheetState extends ConsumerState<ThreadComposerSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _tags = <String>[];
  String _area = repositoryAreaOptions.keys.first;
  bool _saving = false;
  String? _inlineError;
  String? _tagError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  bool _addTags(String rawValue) {
    var error = '';
    var addedAny = false;
    for (final value in rawValue.split(',')) {
      final tag = normalizeSocialTag(value);
      if (tag.isEmpty) continue;
      if (tag.length > maxSocialTagLength) {
        error =
            'Cada etiqueta puede tener máximo $maxSocialTagLength caracteres.';
        continue;
      }
      if (containsSocialTag(_tags, tag)) {
        error = 'La etiqueta "$tag" ya fue agregada.';
        continue;
      }
      if (_tags.length >= maxSocialTags) {
        error = 'Puedes agregar hasta $maxSocialTags etiquetas.';
        break;
      }
      _tags.add(tag);
      addedAny = true;
    }
    setState(() {
      _tagError = error.isEmpty ? null : error;
      if (addedAny) _tagCtrl.clear();
    });
    return error.isEmpty;
  }

  Future<void> _submit() async {
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_tagCtrl.text.trim().isNotEmpty && !_addTags(_tagCtrl.text)) return;
    setState(() => _saving = true);
    try {
      await ref.read(forumActionsProvider).createThread(
            ForumThreadInput(
              title: _titleCtrl.text,
              content: _contentCtrl.text,
              area: _area,
              tags: _tags,
            ),
          );
      if (!mounted) return;
      Navigator.pop(context);
      CucSnackBar.show(
        context,
        icon: Icons.check_circle_outline,
        iconColor: AppColors.primary,
        message: 'Hilo publicado con éxito.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _inlineError = error.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NUEVO HILO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const ForumComposerLabel(label: 'TÍTULO DEL HILO'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: forumComposerInputDecoration(
                    hintText: 'Título de la duda',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un titulo'
                      : null,
                ),
                const SizedBox(height: 16),
                const ForumComposerLabel(label: 'ÁREA DE CONOCIMIENTO'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _area,
                  isExpanded: true,
                  dropdownColor: AppColors.background,
                  decoration: forumComposerInputDecoration(),
                  items: repositoryAreaOptions.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value,
                              overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _area = value ?? _area),
                ),
                const SizedBox(height: 16),
                const ForumComposerLabel(label: 'CONTENIDO'),
                const SizedBox(height: 8),
                RichTextEditorToolbar(
                  controller: _contentCtrl,
                  enabled: !_saving,
                ),
                TextFormField(
                  controller: _contentCtrl,
                  minLines: 8,
                  maxLines: 12,
                  maxLength: 1000,
                  decoration: forumComposerInputDecoration(
                    hintText: 'Describe el problema o hallazgo',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el contenido'
                      : null,
                ),
                const SizedBox(height: 8),
                const ForumComposerLabel(label: 'ETIQUETAS (OPCIONAL)'),
                const SizedBox(height: 8),
                if (_tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _tags
                        .map(
                          (tag) => InputChip(
                            label: Text(tag),
                            onDeleted: _saving
                                ? null
                                : () => setState(() {
                                      _tags.remove(tag);
                                      _tagError = null;
                                    }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _tagCtrl,
                  enabled: !_saving && _tags.length < maxSocialTags,
                  maxLength: maxSocialTagLength,
                  decoration: forumComposerInputDecoration(
                    hintText: 'Agregar etiqueta (opcional)',
                    errorText: _tagError,
                    prefixIcon: const Icon(Icons.tag),
                    suffixIcon: IconButton(
                      tooltip: 'Agregar etiqueta',
                      onPressed: _saving || _tags.length >= maxSocialTags
                          ? null
                          : () => _addTags(_tagCtrl.text),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    helperText:
                        'Enter o coma para agregar · ${_tags.length}/$maxSocialTags',
                  ),
                  onChanged: (_) {
                    if (_tagError != null) setState(() => _tagError = null);
                  },
                  onSubmitted: _addTags,
                ),
                if (_inlineError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _inlineError!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_outlined),
                    label: const Text('PUBLICAR HILO'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForumComposerLabel extends StatelessWidget {
  const ForumComposerLabel({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.muted,
      ),
    );
  }
}

InputDecoration forumComposerInputDecoration({
  String? hintText,
  String? helperText,
  String? errorText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide.none,
  );

  return InputDecoration(
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.background,
    border: border,
    enabledBorder: border,
    focusedBorder: border,
  );
}
