import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/areas.dart';
import '../../../core/theme/app_theme.dart';
import '../models/forum_thread.dart';
import '../providers/forum_providers.dart';

class ForumThreadComposer extends ConsumerStatefulWidget {
  const ForumThreadComposer({super.key});

  @override
  ConsumerState<ForumThreadComposer> createState() =>
      _ForumThreadComposerState();
}

class _ForumThreadComposerState extends ConsumerState<ForumThreadComposer> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _tags = <String>[];
  String _area = areaOptions.keys.first;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final tag = value.trim();
    if (tag.isEmpty || _tags.contains(tag) || _tags.length >= 3) return;
    setState(() {
      _tags.add(tag);
      _tagCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hilo publicado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar: $error')),
      );
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
                const Text('Nuevo hilo',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
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
                  items: areaOptions.entries
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
                TextFormField(
                  controller: _contentCtrl,
                  minLines: 4,
                  maxLines: 8,
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
                        onDeleted: () => setState(() => _tags.remove(tag)),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _tagCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Agregar etiqueta, maximo 3'),
                  onSubmitted: _addTag,
                ),
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
