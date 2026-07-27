import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Markdown formatting controls shared by social content composers.
class RichTextEditorToolbar extends StatelessWidget {
  const RichTextEditorToolbar({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;

  void _wrapSelection(String prefix, String suffix, String placeholder) {
    final value = controller.value;
    final selection = value.selection;
    final isValid = selection.isValid;
    final start = isValid ? selection.start : value.text.length;
    final end = isValid ? selection.end : value.text.length;
    final selected = isValid && !selection.isCollapsed
        ? value.text.substring(start, end)
        : placeholder;
    final replacement = '$prefix$selected$suffix';

    controller.value = value.copyWith(
      text: value.text.replaceRange(start, end, replacement),
      selection: TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selected.length,
      ),
      composing: TextRange.empty,
    );
  }

  Future<void> _insertLink(BuildContext context) async {
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : controller.text.length;
    final end = selection.isValid ? selection.end : start;
    final selected = start != end ? controller.text.substring(start, end) : '';
    final result = await showModalBottomSheet<RichTextLink>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RichTextLinkEditor(initialLabel: selected),
    );
    if (result == null || !context.mounted) return;

    final markup = '[${result.label}](${result.url})';
    controller.value = controller.value.copyWith(
      text: controller.text.replaceRange(start, end, markup),
      selection: TextSelection.collapsed(offset: start + markup.length),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            tooltip: 'Negrita',
            icon: Icons.format_bold,
            onPressed:
                enabled ? () => _wrapSelection('**', '**', 'texto') : null,
          ),
          _ToolbarButton(
            tooltip: 'Cursiva',
            icon: Icons.format_italic,
            onPressed: enabled ? () => _wrapSelection('_', '_', 'texto') : null,
          ),
          Container(
            width: 1,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: AppColors.border,
          ),
          _ToolbarButton(
            tooltip: 'Agregar enlace',
            icon: Icons.link,
            label: 'Enlace',
            onPressed: enabled ? () => _insertLink(context) : null,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.label,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
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
                Icon(
                  icon,
                  size: 21,
                  color:
                      onPressed == null ? AppColors.muted : AppColors.onSurface,
                ),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RichTextLink {
  const RichTextLink({required this.label, required this.url});

  final String label;
  final String url;
}

class RichTextLinkEditor extends StatefulWidget {
  const RichTextLinkEditor({super.key, required this.initialLabel});

  final String initialLabel;

  @override
  State<RichTextLinkEditor> createState() => _RichTextLinkEditorState();
}

class _RichTextLinkEditorState extends State<RichTextLinkEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final rawUrl = _urlController.text.trim();
    Navigator.pop(
      context,
      RichTextLink(
        label: _labelController.text.trim(),
        url: rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
            ? rawUrl
            : 'https://$rawUrl',
      ),
    );
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
                      Text(
                        'Agregar enlace',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _labelController,
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
                    controller: _urlController,
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
