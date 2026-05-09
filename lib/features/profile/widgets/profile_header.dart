import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../club/screens/club_profile_screen.dart';
import '../../repository/repository_screen.dart';
import '../providers/profile_providers.dart';

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
      final bytes = await image.readAsBytes();
      const maxBytes = 10 * 1024 * 1024;
      if (bytes.length > maxBytes) {
        messenger.showSnackBar(
          const SnackBar(content: Text('La imagen no puede superar 10MB.')),
        );
        return;
      }

      final extension = image.name.split('.').last.toLowerCase();
      final safeExtension =
          extension == 'png' || extension == 'webp' ? extension : 'jpg';
      final contentType =
          safeExtension == 'jpg' ? 'image/jpeg' : 'image/$safeExtension';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${widget.profile.id}/avatar_$timestamp.$safeExtension';
      final supabase = ref.read(supabaseClientProvider);

      await supabase.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);
      await supabase
          .from('perfiles')
          .update({'url_avatar': publicUrl}).eq('id', widget.profile.id);

      ref.invalidate(profileProvider(widget.profile.id));
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.isOwner ? _pickAvatar : null,
            child: Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1B2B20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    image: profile.urlAvatar != null
                        ? DecorationImage(
                            image: NetworkImage(profile.urlAvatar!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profile.urlAvatar == null
                      ? const Icon(Icons.person,
                          color: AppColors.primary, size: 40)
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.nombreCompleto.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCBD5CE),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (profile.clubId != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 2),
                        child: Text(
                          'CUC ${profile.divisionAcronimo}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Text(
                    'SIN CLUB ASIGNADO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined,
                color: AppColors.primary, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RepositoryScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
