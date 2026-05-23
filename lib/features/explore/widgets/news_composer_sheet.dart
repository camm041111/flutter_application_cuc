import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/correct_snackbar.dart';
import '../providers/explore_providers.dart';

class NewsComposerSheet extends ConsumerStatefulWidget {
  const NewsComposerSheet({super.key});

  @override
  ConsumerState<NewsComposerSheet> createState() => _NewsComposerSheetState();
}

class _NewsComposerSheetState extends ConsumerState<NewsComposerSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  XFile? _selectedImage;
  bool _saving = false;
  String? _inlineError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    await HapticFeedback.lightImpact();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Galería de fotos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Tomar fotografía', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      final sizeInBytes = await image.length();
      // Validación preventiva: 5 megabytes = 5,242,880 bytes
      if (sizeInBytes > 5 * 1024 * 1024) {
        setState(() => _inlineError = 'La imagen excede el límite permitido de 5MB.');
        return;
      }
      setState(() {
        _selectedImage = image;
        _inlineError = null;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(exploreActionsProvider).createNews(
        NewsInput(
          title: _titleCtrl.text,
          content: _contentCtrl.text,
          imageFile: _selectedImage,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);

      CucSnackBar.show(
        context,
        icon: Icons.check_circle_outline,
        iconColor: AppColors.primary,
        message: 'Noticia publicada con éxito.',
      );
    } catch (e) {
      setState(() => _inlineError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.muted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PUBLICAR NOTICIA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Imagen promocional (Máx 5MB)'),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _saving ? null : _pickImage,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _selectedImage == null
                        ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: AppColors.muted, size: 28),
                        SizedBox(height: 8),
                        Text(
                          'Seleccionar archivo (JPEG, PNG o WEBP)',
                          style: TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    )
                        : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close, color: Colors.white, size: 16),
                              onPressed: () => setState(() => _selectedImage = null),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Título de la noticia'),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Ej. Gran Cierre de Convocatorias'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa un título válido' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Contenido del comunicado'),
                TextFormField(
                  controller: _contentCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 600,
                  decoration: const InputDecoration(hintText: 'Escribe el mensaje oficial aquí...'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'El contenido no puede estar vacío' : null,
                ),

                if (_inlineError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _inlineError!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_outlined),
                    label: const Text('PUBLICAR COMUNICADO'),
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