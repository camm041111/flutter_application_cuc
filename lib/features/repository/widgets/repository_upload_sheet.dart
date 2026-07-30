import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/social_tag_utils.dart';
import '../../../core/widgets/rich_text_editor_toolbar.dart';
import '../providers/repository_providers.dart';
import 'repository_filter_sheet.dart';

class RepositoryUploadSheet extends ConsumerStatefulWidget {
  const RepositoryUploadSheet({
    super.key,
    this.documentToEdit,
  });

  final RepositoryDocument? documentToEdit;

  @override
  ConsumerState<RepositoryUploadSheet> createState() =>
      RepositoryUploadSheetState();
}

class RepositoryUploadSheetState extends ConsumerState<RepositoryUploadSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _tags = <String>[];
  String _category = repositoryCategoryOptions.keys.first;
  String _area = repositoryAreaOptions.keys.first;
  final List<PlatformFile> _files = [];
  bool _uploading = false;
  String? _tagError;
  String? _inlineError;

  bool get _isEditing => widget.documentToEdit != null;

  @override
  void initState() {
    super.initState();
    final document = widget.documentToEdit;
    if (document == null) return;

    _titleController.text = document.title;
    _descriptionController.text = document.description;
    _category = repositoryCategoryOptions.containsKey(document.category)
        ? document.category
        : repositoryCategoryOptions.keys.first;
    _area = repositoryAreaOptions.containsKey(document.area)
        ? document.area
        : repositoryAreaOptions.keys.first;
    _tags.addAll(document.tags.take(maxSocialTags));
  }

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
      allowMultiple: true,
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
    final selectedFiles = result?.files ?? const <PlatformFile>[];
    if (selectedFiles.isEmpty) {
      return;
    }

    final oversizedFiles = selectedFiles
        .where((file) => file.size > repositoryFileLimitBytes)
        .map((file) => file.name)
        .toList();
    if (oversizedFiles.isNotEmpty) {
      setState(() {
        _inlineError =
            'Cada archivo debe pesar máximo 10MB. Revisa: ${oversizedFiles.join(', ')}.';
      });
      return;
    }

    final newFiles = selectedFiles.where((selected) {
      return !_files.any(
        (current) =>
            current.name == selected.name && current.size == selected.size,
      );
    }).toList();
    if (_files.length + newFiles.length > 3) {
      setState(() {
        _inlineError = 'Puedes adjuntar un máximo de 3 archivos.';
      });
      return;
    }

    setState(() {
      _files.addAll(newFiles);
      _inlineError = null;
    });
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      _files.remove(file);
      _inlineError = null;
    });
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
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;

    if ((!_isEditing && _files.isEmpty) || _files.length > 3) return;
    if (_tagsController.text.trim().isNotEmpty &&
        !_addTags(_tagsController.text)) {
      return;
    }

    setState(() => _uploading = true);
    try {
      final actions = ref.read(repositoryActionsProvider);
      late final String status;
      if (_isEditing) {
        await actions.resubmitDocument(
          document: widget.documentToEdit!,
          title: _titleController.text,
          description: _descriptionController.text,
          replacementFiles: List.unmodifiable(_files),
        );
        status = 'pendiente';
      } else {
        status = await actions.uploadDocument(
          RepositoryUploadInput(
            title: _titleController.text,
            description: _descriptionController.text,
            category: _category,
            area: _area,
            tags: _tags,
            files: List.unmodifiable(_files),
          ),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Documento corregido y reenviado a revisión.'
                : status == 'aprobado'
                    ? 'Documento publicado.'
                    : 'Documento enviado a revisión.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final cleanError = error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _inlineError = cleanError.isEmpty
            ? 'No se pudo completar la subida. Inténtalo nuevamente.'
            : 'No se pudo completar la subida. $cleanError';
      });
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'CORREGIR DOCUMENTO' : 'SUBIR DOCUMENTO',
                  style: const TextStyle(
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
                TextFormField(
                  controller: _titleController,
                  decoration: repositoryInputDecoration(
                    hintText: 'Título',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el título del documento'
                      : null,
                  onChanged: (_) {
                    if (_inlineError != null) {
                      setState(() => _inlineError = null);
                    }
                  },
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
                  maxLength: 250,
                  decoration: repositoryInputDecoration(
                    hintText: 'Descripción breve',
                  ),
                ),
                const SizedBox(height: 12),
                RepositoryFilterDropdown(
                  label: 'CATEGORÍA',
                  value: _category,
                  options: repositoryCategoryOptions,
                  onChanged: _isEditing
                      ? null
                      : (value) {
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
                            onDeleted: _uploading || _isEditing
                                ? null
                                : () => _removeTag(tag),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _tagsController,
                  enabled: !_uploading &&
                      !_isEditing &&
                      _tags.length < maxSocialTags,
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
                      onPressed: _uploading ||
                              _isEditing ||
                              _tags.length >= maxSocialTags
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
                  onChanged: _isEditing
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _area = value);
                          }
                        },
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'La categoría, el área y las etiquetas se conservan. '
                    'Puedes corregir el título, la descripción y reemplazar '
                    'los archivos.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _files.isEmpty
                        ? _isEditing
                            ? 'Conservar archivos actuales o elegir reemplazos'
                            : 'Seleccionar archivos (1 a 3, máx. 10MB c/u)'
                        : _files.map((file) => file.name).join('\n'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_files.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _files
                        .map(
                          (file) => InputChip(
                            avatar: const Icon(
                              Icons.description_outlined,
                              size: 16,
                            ),
                            label: Text(file.name),
                            onDeleted:
                                _uploading ? null : () => _removeFile(file),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_files.length}/3 archivos seleccionados',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
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
                    onPressed: _uploading ||
                            (!_isEditing && _files.isEmpty) ||
                            _files.length > 3
                        ? null
                        : _submit,
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
                    label: Text(
                      _isEditing ? 'CORREGIR Y REENVIAR' : 'ENVIAR A REVISIÓN',
                    ),
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
