part of 'forum_view.dart';

class _ThreadComposerSheet extends ConsumerStatefulWidget {
  const _ThreadComposerSheet();

  @override
  ConsumerState<_ThreadComposerSheet> createState() =>
      _ThreadComposerSheetState();
}

class _ThreadComposerSheetState extends ConsumerState<_ThreadComposerSheet> {
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleCtrl,
                  decoration:
                      const InputDecoration(hintText: 'Titulo de la duda'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un titulo'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _area,
                  isExpanded: true,
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
                const SizedBox(height: 12),
                RichTextEditorToolbar(
                  controller: _contentCtrl,
                  enabled: !_saving,
                ),
                TextFormField(
                  controller: _contentCtrl,
                  minLines: 8,
                  maxLines: 12,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                      hintText: 'Describe el problema o hallazgo'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el contenido'
                      : null,
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    ..._tags.map(
                      (tag) => InputChip(
                        label: Text(tag),
                        onDeleted: _saving
                            ? null
                            : () => setState(() {
                                  _tags.remove(tag);
                                  _tagError = null;
                                }),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _tagCtrl,
                  enabled: !_saving && _tags.length < maxSocialTags,
                  maxLength: maxSocialTagLength,
                  decoration: InputDecoration(
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
                  const SizedBox(height: 12),
                  Text(
                    _inlineError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
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
