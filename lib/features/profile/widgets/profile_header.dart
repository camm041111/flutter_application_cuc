import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_providers.dart';
import '../../club/screens/club_profile_screen.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Row(
          children: [
          // 1. Avatar del Usuario
          Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1B2B20), // Fondo antracita
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            image: profile.urlAvatar != null
                ? DecorationImage(image: NetworkImage(profile.urlAvatar!), fit: BoxFit.cover)
                : null,
          ),
          child: profile.urlAvatar == null
              ? const Icon(Icons.person, color: AppColors.primary, size: 40)
              : null,
        ),
        const SizedBox(width: 16),

        // 2. Información y Enlace al Club
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
              profile.nombreCompleto.toUpperCase(),
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFCBD5CE)
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),

        // 🛡️ Lógica Condicional: Solo renderiza el enlace si pertenece a un club
        if (profile.clubId != null)
    Material(
      color: Colors.transparent, // Necesario para que el InkWell muestre el efecto ripple
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (_) => ClubProfileScreen(clubId: profile.clubId!)
             )
           );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
          child: Text(
            // Muestra el acrónimo según las especificaciones (ej. CUC DACyTI)
            'CUC ${profile.divisionAcronimo}',
            style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            decoration: TextDecoration.underline, // Indicador de enlace
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

    // 3. Botón de Portafolio
    IconButton(
    icon: const Icon(Icons.folder_outlined, color: AppColors.primary, size: 26),
    onPressed: () {
    // TODO: Lógica para ver el portafolio personal en el repositorio
    },
    ),
    ],
    ),
    );
    }
}