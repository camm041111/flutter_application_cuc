import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
  String _category = repositoryCategoryOptions.keys.first;
  String _area = repositoryAreaOptions.keys.first;
  PlatformFile? _file;
  bool _uploading = false;

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

  Future<void> _submit() async {
    final file = _file;
    if (_titleController.text.trim().isEmpty || file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega título y archivo.')),
      );
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
              tags: parseRepositoryTags(_tagsController.text),
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
                'Subir documento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                maxLength: 250,
                decoration: const InputDecoration(
                  hintText: 'Descripción breve',
                  counterText: '',
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
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  hintText: 'Etiquetas separadas por coma (máx. 4)',
                ),
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

List<String> parseRepositoryTags(String value) {
  return value
      .split(',')
      .map((tag) => tag.trim().replaceFirst(RegExp(r'^#+'), ''))
      .where((tag) => tag.isNotEmpty)
      .take(4)
      .toList();
}
