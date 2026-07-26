import 'package:flutter/material.dart';
import '../config/constants.dart';

class SkeuomorphicTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final bool obscure;
  final IconData? icon;
  final String? Function(String?)? validator;

  const SkeuomorphicTextField({
    this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.oscuro,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(-1, -1),
                blurRadius: 2,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            validator: validator,
            style: TextStyle(color: AppColors.texto, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textoSecundario.withOpacity(0.5)),
              filled: true,
              fillColor: AppColors.fondo,
              prefixIcon: icon != null
                  ? Icon(icon, color: AppColors.secundario, size: 20)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.superficie, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.superficie, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primario, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
