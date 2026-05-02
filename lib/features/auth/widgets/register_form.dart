import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cuc_text_field.dart';
import '../../../core/providers/catalogos_providers.dart'; // Importa los providers que creamos
import '../../../core/services/auth_service.dart'; // Importa tu servicio de auth

// 1. Transformamos a ConsumerStatefulWidget para que pueda escuchar a Riverpod
class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  // 2. Controladores: Los oídos de nuestro formulario
  final _nombreController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variables de estado
  String? _divisionSeleccionadaId;
  String? _clubSeleccionadoId;
  bool _isLoading = false;

  // 3. Gestión de Memoria (Obligatorio en Clean Architecture)
  @override
  void dispose() {
    _nombreController.dispose();
    _matriculaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 4. Lógica Asíncrona Segura
  Future<void> _ejecutarRegistro() async {
    // Validamos que los TextField cumplan las RegEx
    if (!_formKey.currentState!.validate()) return;

    // Validamos que no se hayan saltado los Dropdowns
    if (_divisionSeleccionadaId == null || _clubSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar tu División y tu Club')),
      );
      return;
    }

    // Bloqueamos la interfaz
    setState(() => _isLoading = true);

    // Llamamos al backend
    final error = await ref.read(authServiceProvider).registrarUsuario(
      correo: _emailController.text,
      contrasena: _passwordController.text,
      nombreCompleto: _nombreController.text,
      matricula: _matriculaController.text,
      idDivision: _divisionSeleccionadaId!,
      idClub: _clubSeleccionadoId!,
    );

    // Desbloqueamos la interfaz (si el widget sigue montado)
    if (mounted) {
      setState(() => _isLoading = false);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro exitoso! Pendiente de aprobación.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        // Regresamos al Login
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 5. Escuchamos los catálogos en tiempo real desde Supabase
    final divisionesAsync = ref.watch(divisionesProvider);
    final clubesAsync = ref.watch(clubesPorDivisionProvider(_divisionSeleccionadaId));

    return Form(
      key: _formKey,
      child: Column(
        children: [
          CucTextField(
            controller: _nombreController, // Conectamos el controlador
            label: 'NOMBRE COMPLETO',
            hint: 'Ej. Ivana Sanchez',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Campo requerido';
              if (value.trim().length < 3) return 'Mínimo 3 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CucTextField(
            controller: _matriculaController,
            label: 'MATRÍCULA INSTITUCIONAL',
            hint: '202L961214',
            prefixIcon: Icons.badge_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Campo requerido';
              if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) return 'Solo caracteres alfanuméricos';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CucTextField(
            controller: _emailController,
            label: 'CORREO INSTITUCIONAL',
            hint: 'usuario@alumno.ujat.mx',
            prefixIcon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Campo requerido';
              //prueba
              //if (!RegExp(r'^[a-zA-Z0-9._%+-]+@(alumno\.ujat\.mx|ujat\.mx)$').hasMatch(value.trim())) {
                //return 'Use un correo institucional válido';
              //}
              //fin prueba
              return null;
            },
          ),
          const SizedBox(height: 16),
          CucTextField(
            controller: _passwordController,
            label: 'CONTRASEÑA',
            hint: '••••••••',
            prefixIcon: Icons.key_outlined,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo requerido';
              // 6. Validación de Seguridad RNF02
              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d\w\W]{8,}$').hasMatch(value)) {
                return 'Mínimo 8 caracteres, 1 mayúscula, 1 minúscula y 1 número';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // 7. Dropdown Dinámico de Divisiones
          divisionesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, stack) => Text('Error al cargar divisiones: $err', style: const TextStyle(color: Colors.red)),
            data: (divisiones) => DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'DIVISIÓN ACADÉMICA',
                prefixIcon: Icon(Icons.school_outlined, size: 20, color: AppColors.primary),
                labelStyle: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              value: _divisionSeleccionadaId,
              items: divisiones.map((div) => DropdownMenuItem(
                value: div['id'].toString(),
                child: Text(div['acronimo'], style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (val) {
                setState(() {
                  _divisionSeleccionadaId = val;
                  _clubSeleccionadoId = null; // Reset del club al cambiar de división
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // 8. Dropdown Dinámico de Clubes (Dependiente del anterior)
          clubesAsync.when(
            loading: () => _divisionSeleccionadaId != null ? const LinearProgressIndicator() : const SizedBox.shrink(),
            error: (err, stack) => Text('Error al cargar clubes', style: const TextStyle(color: Colors.red)),
            data: (clubes) => DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'CLUB DE INTERÉS',
                prefixIcon: Icon(Icons.science_outlined, size: 20, color: AppColors.primary),
                labelStyle: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              value: _clubSeleccionadoId,
              items: clubes.isEmpty ? null : clubes.map((club) => DropdownMenuItem(
                value: club['id'].toString(),
                child: Text(club['nombre'], style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (val) => setState(() => _clubSeleccionadoId = val),
              hint: Text(clubes.isEmpty ? 'Selecciona una división primero' : 'Elige tu club'),
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _ejecutarRegistro, // Bloqueo de múltiples taps
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('REGISTRARME'),
            ),
          ),
        ],
      ),
    );
  }
}