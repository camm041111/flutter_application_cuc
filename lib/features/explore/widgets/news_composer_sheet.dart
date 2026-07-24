import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/social_tag_utils.dart';
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
  final _tagCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _tags = <String>[];

  XFile? _selectedImage;
  bool _saving = false;
  String? _inlineError;
  String? _tagError;

  void _wrapSelection(String prefix, String suffix,
      {String placeholder = 'texto'}) {
    final value = _contentCtrl.value;
    final selection = value.selection;
    final hasSelection = selection.isValid && !selection.isCollapsed;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final selected =
        hasSelection ? value.text.substring(start, end) : placeholder;
    final replacement = '$prefix$selected$suffix';

    _contentCtrl.value = value.copyWith(
      text: value.text.replaceRange(start, end, replacement),
      selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: start + prefix.length + selected.length),
      composing: TextRange.empty,
    );
  }

  Future<void> _insertLink() async {
    final selection = _contentCtrl.selection;
    final start =
        selection.isValid ? selection.start : _contentCtrl.text.length;
    final end = selection.isValid ? selection.end : start;
    final selectedText =
        start != end ? _contentCtrl.text.substring(start, end) : '';

    final result = await showModalBottomSheet<({String label, String url})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LinkEditorSheet(initialLabel: selectedText),
    );

    if (result == null || !mounted) return;
    final markup = '[${result.label}](${result.url})';
    _contentCtrl.value = _contentCtrl.value.copyWith(
      text: _contentCtrl.text.replaceRange(start, end, markup),
      selection: TextSelection.collapsed(offset: start + markup.length),
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  bool _addTags(String rawValue) {
    final values = rawValue.split(',');
    var error = '';
    var addedAny = false;

    for (final value in values) {
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

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _tagError = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    unawaited(HapticFeedback.lightImpact());

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
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Galería de fotos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Tomar fotografía',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
        setState(() =>
            _inlineError = 'La imagen excede el límite permitido de 5MB.');
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
    if (_tagCtrl.text.trim().isNotEmpty && !_addTags(_tagCtrl.text)) return;

    setState(() => _saving = true);
    try {
      await ref.read(exploreActionsProvider).createNews(
            NewsInput(
              title: _titleCtrl.text,
              content: _contentCtrl.text,
              imageFile: _selectedImage,
              tags: List.unmodifiable(_tags),
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
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.94,
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
                  _buildFieldLabel('Título de la noticia'),
                  TextFormField(
                    controller: _titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                        hintText: 'Ej. Gran Cierre de Convocatorias'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa un título válido'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildFieldLabel('Contenido del comunicado'),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _FormatButton(
                          tooltip: 'Negrita',
                          icon: Icons.format_bold,
                          onPressed: () => _wrapSelection('**', '**'),
                        ),
                        _FormatButton(
                          tooltip: 'Cursiva',
                          icon: Icons.format_italic,
                          onPressed: () => _wrapSelection('_', '_'),
                        ),
                        Container(
                            width: 1,
                            height: 26,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            color: AppColors.border),
                        _FormatButton(
                          tooltip: 'Agregar enlace',
                          icon: Icons.link,
                          label: 'Enlace',
                          onPressed: _insertLink,
                        ),
                      ],
                    ),
                  ),
                  TextFormField(
                    controller: _contentCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 10,
                    maxLines: 14,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                        hintText: 'Escribe el mensaje oficial aquí...'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'El contenido no puede estar vacío'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _buildFieldLabel('Etiquetas (opcional)'),
                  if (_tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _tags
                          .map(
                            (tag) => InputChip(
                              label: Text(tag),
                              onDeleted: _saving ? null : () => _removeTag(tag),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: _tagCtrl,
                    enabled: !_saving && _tags.length < maxSocialTags,
                    textInputAction: TextInputAction.done,
                    maxLength: maxSocialTagLength,
                    decoration: InputDecoration(
                      hintText: 'Ej. inteligencia artificial, convocatoria',
                      helperText:
                          'Enter o coma para agregar · ${_tags.length}/$maxSocialTags',
                      errorText: _tagError,
                      prefixIcon: const Icon(Icons.tag),
                      suffixIcon: IconButton(
                        tooltip: 'Agregar etiqueta',
                        onPressed: _saving || _tags.length >= maxSocialTags
                            ? null
                            : () => _addTags(_tagCtrl.text),
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
                  const SizedBox(height: 8),
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
                                Icon(Icons.add_a_photo_outlined,
                                    color: AppColors.muted, size: 28),
                                SizedBox(height: 8),
                                Text(
                                  'Seleccionar archivo (JPEG, PNG o WEBP)',
                                  style: TextStyle(
                                      color: AppColors.muted, fontSize: 11),
                                ),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(File(_selectedImage!.path),
                                      fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.close,
                                          color: Colors.white, size: 16),
                                      onPressed: () =>
                                          setState(() => _selectedImage = null),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_inlineError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _inlineError!,
                              style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
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
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_outlined),
                      label: const Text('PUBLICAR COMUNICADO'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton(
      {required this.tooltip,
      required this.icon,
      required this.onPressed,
      this.label});

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 21, color: AppColors.onSurface),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(label!,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkEditorSheet extends StatefulWidget {
  const _LinkEditorSheet({required this.initialLabel});

  final String initialLabel;

  @override
  State<_LinkEditorSheet> createState() => _LinkEditorSheetState();
}

class _LinkEditorSheetState extends State<_LinkEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  final _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final rawUrl = _urlCtrl.text.trim();
    Navigator.pop(context, (
      label: _labelCtrl.text.trim(),
      url: rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
          ? rawUrl
          : 'https://$rawUrl',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.link, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Agregar enlace',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _labelCtrl,
                    autofocus: widget.initialLabel.isEmpty,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Texto visible',
                      hintText: 'Ej. Consulta la convocatoria',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe el texto del enlace'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _urlCtrl,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Dirección web',
                      hintText: 'https://ejemplo.com',
                    ),
                    validator: (value) {
                      final raw = value?.trim() ?? '';
                      final normalized = raw.startsWith('http://') ||
                              raw.startsWith('https://')
                          ? raw
                          : 'https://$raw';
                      final uri = Uri.tryParse(normalized);
                      return uri == null ||
                              !uri.hasAuthority ||
                              uri.host.isEmpty
                          ? 'Ingresa una dirección web válida'
                          : null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCELAR'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.add_link),
                          label: const Text('AGREGAR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
