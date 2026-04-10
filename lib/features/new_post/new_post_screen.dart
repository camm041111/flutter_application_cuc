import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Justificación StatefulWidget: administra estado de tags (lista mutable),
// repo seleccionado, dropdown de repos y visibilidad del selector.
class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _postCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final List<String> _tags = ['NEURONAL', 'BIOTECNOLOGÍA'];
  _RepoOption? _selectedRepo;
  bool _showRepoSelector = false;

  @override
  void dispose() {
    _postCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final tag = raw.trim().toUpperCase();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagCtrl.clear();
    });
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  void _selectRepo(_RepoOption repo) {
    setState(() {
      _selectedRepo = repo;
      _showRepoSelector = false;
    });
  }

  void _clearRepo() => setState(() => _selectedRepo = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _NewPostAppBar(onBack: () => Navigator.pop(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            Row(
              children: [
                const Text(
                  'NUEVA PUBLICACIÓN',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.muted),
                ),
                const SizedBox(width: 8),
                Text('/', style: TextStyle(color: AppColors.muted.withOpacity(0.4))),
                const SizedBox(width: 8),
                Text(
                  'EXPLORAR',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: AppColors.primary.withOpacity(0.6)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Composer card
            _ComposerCard(
              postCtrl: _postCtrl,
              tags: _tags,
              tagCtrl: _tagCtrl,
              selectedRepo: _selectedRepo,
              showRepoSelector: _showRepoSelector,
              onAddTag: _addTag,
              onRemoveTag: _removeTag,
              onToggleRepoSelector: () => setState(() => _showRepoSelector = !_showRepoSelector),
              onSelectRepo: _selectRepo,
              onClearRepo: _clearRepo,
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('CANCELAR'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('PUBLICAR'),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── AppBar personalizado ─────────────────────────────────────────────────────

class _NewPostAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _NewPostAppBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1D2616),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.science, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CUC', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1)),
              Text('RESEARCH PORTAL', style: TextStyle(fontSize: 9, color: AppColors.primary, letterSpacing: 1.2, height: 1.3)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined), color: Colors.white),
        IconButton(onPressed: () {}, icon: const Icon(Icons.account_circle_outlined), color: Colors.white),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.primary.withOpacity(0.1)),
      ),
    );
  }
}

// ── Composer Card ─────────────────────────────────────────────────────────────

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.postCtrl,
    required this.tags,
    required this.tagCtrl,
    required this.selectedRepo,
    required this.showRepoSelector,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onToggleRepoSelector,
    required this.onSelectRepo,
    required this.onClearRepo,
  });

  final TextEditingController postCtrl;
  final List<String> tags;
  final TextEditingController tagCtrl;
  final _RepoOption? selectedRepo;
  final bool showRepoSelector;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final VoidCallback onToggleRepoSelector;
  final ValueChanged<_RepoOption> onSelectRepo;
  final VoidCallback onClearRepo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Author row
          _AuthorRow(),
          // Text area
          _TextArea(controller: postCtrl),
          // Format toolbar
          _FormatToolbar(),
          // Tags
          _TagSection(
            tags: tags,
            controller: tagCtrl,
            onAdd: onAddTag,
            onRemove: onRemoveTag,
          ),
          // Repo reference
          _RepoSection(
            selected: selectedRepo,
            showSelector: showRepoSelector,
            onToggle: onToggleRepoSelector,
            onSelect: onSelectRepo,
            onClear: onClearRepo,
          ),
        ],
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.15),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Icon(Icons.person, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NOMBRE DE USUARIO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border.withOpacity(0.6)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.group, color: AppColors.primary, size: 13),
                    SizedBox(width: 5),
                    Text(
                      'NOMBRE CLUB',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextArea extends StatelessWidget {
  const _TextArea({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: 8,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, height: 1.6, color: AppColors.onBackground),
        decoration: const InputDecoration(
          hintText: '¿Cuáles son tus últimos hallazgos de investigación?',
          hintStyle: TextStyle(color: Color(0xFF3D5230), fontSize: 17),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _FormatToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          top: BorderSide(color: AppColors.primary.withOpacity(0.05)),
          left: BorderSide(color: AppColors.primary.withOpacity(0.05)),
          right: BorderSide(color: AppColors.primary.withOpacity(0.05)),
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.05)),
        ),
      ),
      child: const Row(
        children: [
          _FormatButton(icon: Icons.format_bold),
          SizedBox(width: 20),
          _FormatButton(icon: Icons.format_italic),
          SizedBox(width: 20),
          _FormatButton(icon: Icons.code),
          SizedBox(width: 20),
          _FormatButton(icon: Icons.format_list_bulleted),
          SizedBox(width: 20),
          _FormatButton(icon: Icons.link),
        ],
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Icon(icon, size: 19, color: AppColors.muted),
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({required this.tags, required this.controller, required this.onAdd, required this.onRemove});

  final List<String> tags;
  final TextEditingController controller;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.primary.withOpacity(0.05)),
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ETIQUETAS',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...tags.map((t) => _TagChip(label: t, onRemove: () => onRemove(t))),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  decoration: const InputDecoration(
                    hintText: 'Agregar etiqueta...',
                    hintStyle: TextStyle(color: Color(0xFF4A6040), fontSize: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    isDense: true,
                  ),
                  onSubmitted: onAdd,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 13, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Repo Reference Section ───────────────────────────────────────────────────

typedef _RepoOption = ({String name, IconData icon, String meta});

final _availableRepos = <_RepoOption>[
  (name: 'Análisis Genómico Avanzado', icon: Icons.biotech, meta: 'Metodología • Actualizado hace 2 días'),
  (name: 'Dataset Redes Neuronales CUC', icon: Icons.analytics, meta: 'Archivo de datos • Actualizado hace 5 días'),
  (name: 'Protocolo Biotecnológico V3', icon: Icons.science, meta: 'Metodología • Actualizado hace 8 días'),
];

class _RepoSection extends StatelessWidget {
  const _RepoSection({
    required this.selected,
    required this.showSelector,
    required this.onToggle,
    required this.onSelect,
    required this.onClear,
  });

  final _RepoOption? selected;
  final bool showSelector;
  final VoidCallback onToggle;
  final ValueChanged<_RepoOption> onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REPOSITORIO REFERENCIADO',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.muted),
          ),
          const SizedBox(height: 8),

          // Repo seleccionado o botón para abrir selector
          if (selected != null)
            _SelectedRepoCard(repo: selected!, onClear: onClear)
          else
            _RepoPickerButton(onTap: onToggle),

          // Dropdown de opciones
          if (showSelector && selected == null) ...[
            const SizedBox(height: 8),
            _RepoDropdown(onSelect: onSelect),
          ],
        ],
      ),
    );
  }
}

class _RepoPickerButton extends StatelessWidget {
  const _RepoPickerButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141C12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.folder_open, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vincular un repositorio del club',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Opcional — aparecerá como referencia en tu publicación',
                    style: TextStyle(fontSize: 10, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SelectedRepoCard extends StatelessWidget {
  const _SelectedRepoCard({required this.repo, required this.onClear});
  final _RepoOption repo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141C12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(repo.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(repo.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onBackground)),
                Text('Repositorio vinculado', style: TextStyle(fontSize: 10, color: AppColors.primary.withOpacity(0.7), letterSpacing: 0.5)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 18, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _RepoDropdown extends StatelessWidget {
  const _RepoDropdown({required this.onSelect});
  final ValueChanged<_RepoOption> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141C12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              style: TextStyle(fontSize: 13, color: AppColors.onBackground),
              decoration: InputDecoration(
                hintText: 'Buscar repositorio...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
                prefixIcon: Icon(Icons.search, size: 16, color: AppColors.muted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.primary.withOpacity(0.1)),
          ..._availableRepos.map(
            (r) => _RepoDropdownItem(repo: r, onSelect: onSelect),
          ),
        ],
      ),
    );
  }
}

class _RepoDropdownItem extends StatelessWidget {
  const _RepoDropdownItem({required this.repo, required this.onSelect});
  final _RepoOption repo;
  final ValueChanged<_RepoOption> onSelect;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelect(repo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.primary.withOpacity(0.05))),
        ),
        child: Row(
          children: [
            Icon(repo.icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onBackground)),
                  Text(repo.meta, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
