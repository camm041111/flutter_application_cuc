import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/correct_snackbar.dart'; // Tu SnackBar CUC
import '../providers/explore_providers.dart';

class NewsComposerSheet extends ConsumerStatefulWidget {
  const NewsComposerSheet({super.key});

  @override
  ConsumerState<NewsComposerSheet> createState() => _NewsComposerSheetState();
}

class _NewsComposerSheetState extends ConsumerState<NewsComposerSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _inlineError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
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
              imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text,
            ),
          );

      if (!mounted) return;
      Navigator.pop(context);

      CucSnackBar.show(
        context,
        icon: Icons.campaign_outlined,
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.primary),
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Título de la noticia'),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Ej. Nueva convocatoria abierta'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa un título' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Contenido del comunicado'),
                TextFormField(
                  controller: _contentCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 800, // Límite razonable para noticias rápidas
                  decoration: const InputDecoration(hintText: 'Escribe los detalles aquí...'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el contenido' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('URL de Imagen (Opcional - Máx 5MB)'),
                TextFormField(
                  controller: _imageCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.image_outlined, size: 20),
                  ),
                ),

                if (_inlineError != null) ...[
                  const SizedBox(height: 20),
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
                          child: Text(_inlineError!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
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
                    label: const Text('PUBLICAR'),
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