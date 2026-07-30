import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../club/screens/club_profile_screen.dart';
import '../../repository/providers/repository_providers.dart';
import '../../repository/screens/my_contributions_screen.dart';
import '../../repository/widgets/repository_view.dart';
import '../providers/profile_providers.dart';

enum _AvatarAction { view, change }

class ProfileHeader extends ConsumerStatefulWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isOwner,
  });

  final UserProfile profile;
  final bool isOwner;

  @override
  ConsumerState<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<ProfileHeader> {
  bool _uploadingAvatar = false;

  Future<void> _handleAvatarTap() async {
    final hasAvatar = widget.profile.urlAvatar?.isNotEmpty == true;

    if (!widget.isOwner) {
      if (hasAvatar) _openAvatarPreview();
      return;
    }

    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                enabled: hasAvatar,
                leading: const Icon(Icons.image_outlined),
                title: const Text('Ver foto'),
                onTap: hasAvatar
                    ? () => Navigator.pop(context, _AvatarAction.view)
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Cambiar foto'),
                onTap: () => Navigator.pop(context, _AvatarAction.change),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == _AvatarAction.view) _openAvatarPreview();
    if (action == _AvatarAction.change) await _pickAvatar();
  }

  void _openAvatarPreview() {
    final avatarUrl = widget.profile.urlAvatar;
    if (avatarUrl == null || avatarUrl.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.background,
        insetPadding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: InteractiveViewer(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.muted,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    if (!widget.isOwner || _uploadingAvatar) return;

    final messenger = ScaffoldMessenger.of(context);
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (image == null) return;

    setState(() => _uploadingAvatar = true);

    try {
      await ref
          .read(profileActionsProvider)
          .uploadAvatar(widget.profile, image);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Imagen de perfil actualizada.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la imagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.75),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _uploadingAvatar ? null : _handleAvatarTap,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.65),
                      width: 2.5,
                    ),
                    image: profile.urlAvatar != null
                        ? DecorationImage(
                            image: NetworkImage(profile.urlAvatar!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profile.urlAvatar == null
                      ? const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primary,
                          size: 42,
                        )
                      : null,
                ),
                if (widget.isOwner)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.background, width: 2),
                      ),
                      child: _uploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: AppColors.background,
                              size: 14,
                            ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                    height: 1.15,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    profile.rol.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.background,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                if (profile.clubId != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ClubProfileScreen(clubId: profile.clubId!),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.science_outlined,
                              size: 13,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'CUC ${profile.divisionAcronimo}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                  letterSpacing: 0.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.science_outlined,
                        size: 13,
                        color: AppColors.muted,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'SIN CLUB ASIGNADO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Ver publicaciones',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
              minimumSize: const Size(42, 42),
            ),
            icon: const Icon(
              Icons.folder_outlined,
              size: 21,
            ),
            onPressed: () {
              if (widget.isOwner) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyContributionsScreen(),
                  ),
                );
                return;
              }

              final filters = ref.read(repositoryFiltersProvider);
              ref.read(repositoryFiltersProvider.notifier).setFilters(
                    filters.copyWith(author: profile.nombreCompleto),
                  );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RepositoryView()),
              );
            },
          ),
        ],
      ),
    );
  }
}
