import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/social_tag_utils.dart';
import '../../../core/widgets/rich_text_editor_toolbar.dart';
import '../providers/repository_providers.dart';
import 'repository_filter_sheet.dart';

class RepositoryUploadSheet extends ConsumerStatefulWidget {
  const RepositoryUploadSheet({super.key});

  @override
  ConsumerState<RepositoryUploadSheet> createState() =>
      RepositoryUploadSheetState();
}

class RepositoryUploadSheetState extends ConsumerState<RepositoryUploadSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _tags = <String>[];
  String _category = repositoryCategoryOptions.keys.first;
  String _area = repositoryAreaOptions.keys.first;
  PlatformFile? _file;
  bool _uploading = false;
  String? _tagError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'txt',
        'jpg',
        'jpeg',
        'png',
      ],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) {
      return;
    }

    if (file.size > repositoryFileLimitBytes) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El archivo no puede superar 10MB.')),
      );
      return;
    }

    setState(() => _file = file);
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
      if (addedAny) _tagsController.clear();
    });
    return error.isEmpty;
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _tagError = null;
    });
  }

  Future<void> _submit() async {
    final file = _file;
    if (_titleController.text.trim().isEmpty || file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega título y archivo.')),
      );
      return;
    }
    if (_tagsController.text.trim().isNotEmpty &&
        !_addTags(_tagsController.text)) {
      return;
    }

    setState(() => _uploading = true);
    try {
      final status = await ref.read(repositoryActionsProvider).uploadDocument(
            RepositoryUploadInput(
              title: _titleController.text,
              description: _descriptionController.text,
              category: _category,
              area: _area,
              tags: _tags,
              file: file,
            ),
          );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'aprobado'
                ? 'Documento publicado.'
                : 'Documento enviado a revisión.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SUBIR DOCUMENTO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const RepositoryFilterLabel(
                label: 'TÍTULO DEL DOCUMENTO',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: repositoryInputDecoration(
                  hintText: 'Título',
                ),
              ),
              const SizedBox(height: 12),
              const RepositoryFilterLabel(
                label: 'DESCRIPCIÓN BREVE',
              ),
              const SizedBox(height: 8),
              RichTextEditorToolbar(
                controller: _descriptionController,
                enabled: !_uploading,
              ),
              TextField(
                controller: _descriptionController,
                minLines: 8,
                maxLines: 12,
                maxLength: 2000,
                decoration: repositoryInputDecoration(
                  hintText: 'Descripción breve',
                ),
              ),
              const SizedBox(height: 12),
              RepositoryFilterDropdown(
                label: 'CATEGORÍA',
                value: _category,
                options: repositoryCategoryOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              const RepositoryFilterLabel(
                label: 'ETIQUETAS',
              ),
              const SizedBox(height: 8),
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags
                      .map(
                        (tag) => InputChip(
                          label: Text(tag),
                          onDeleted: _uploading ? null : () => _removeTag(tag),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _tagsController,
                enabled: !_uploading && _tags.length < maxSocialTags,
                textInputAction: TextInputAction.done,
                maxLength: maxSocialTagLength,
                decoration: repositoryInputDecoration(
                  hintText: 'Ej. ciencia de datos, convocatoria',
                  helperText:
                      'Enter o coma para agregar · ${_tags.length}/$maxSocialTags',
                  errorText: _tagError,
                  prefixIcon: const Icon(Icons.tag),
                  suffixIcon: IconButton(
                    tooltip: 'Agregar etiqueta',
                    onPressed: _uploading || _tags.length >= maxSocialTags
                        ? null
                        : () => _addTags(_tagsController.text),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ),
                onChanged: (_) {
                  if (_tagError != null) {
                    setState(() => _tagError = null);
                  }
                },
                onSubmitted: _addTags,
              ),
              const SizedBox(height: 12),
              RepositoryFilterDropdown(
                label: 'ÁREA DE CONOCIMIENTO',
                value: _area,
                options: repositoryAreaOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _area = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _file == null
                      ? 'Seleccionar archivo (máx. 10MB)'
                      : _file!.name,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('ENVIAR A REVISIÓN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
