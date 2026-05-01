import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cuc_text_field.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  // Opciones hardcodeadas para Dropdowns según especificaciones
  final List<String> _divisiones = ['DAIS', 'DACEA', 'DAMJ', 'DACS', 'DACB'];
  final List<String> _clubes = ['Biotech Innovators', 'Quantum Lab', 'Robotics Club'];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CucTextField(
            label: 'NOMBRE COMPLETO',
            hint: 'Ej. Ivana Sanchez',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo requerido';
              if (value.length < 3) return 'Mínimo 3 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CucTextField(
            label: 'MATRÍCULA INSTITUCIONAL',
            hint: '202L961214',
            prefixIcon: Icons.badge_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo requerido';
              if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) return 'Solo caracteres alfanuméricos';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CucTextField(
            label: 'CORREO INSTITUCIONAL',
            hint: 'usuario@alumno.ujat.mx',
            prefixIcon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo requerido';
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@(alumno\.ujat\.mx|ujat\.mx)$').hasMatch(value)) {
                return 'Use un correo institucional válido (@alumno.ujat.mx o @ujat.mx)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CucTextField(
            label: 'CONTRASEÑA',
            hint: '••••••••',
            prefixIcon: Icons.key_outlined,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo requerido';
              if (value.length < 8) return 'Mínimo 8 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildDropdown(label: 'DIVISIÓN ACADÉMICA', items: _divisiones, icon: Icons.school_outlined),
          const SizedBox(height: 16),
          _buildDropdown(label: 'CLUB DE INTERÉS', items: _clubes, icon: Icons.science_outlined),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Lógica futura de Supabase
                }
              },
              child: const Text('REGISTRARME'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String label, required List<String> items, required IconData icon}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        labelStyle: const TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: (val) {},
    );
  }
}