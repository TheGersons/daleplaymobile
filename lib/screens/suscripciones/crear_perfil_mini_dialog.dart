import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/perfil.dart';
import '../../models/cuenta_correo.dart';
import '../../services/supabase_service.dart';

class CrearPerfilMiniDialog extends StatefulWidget {
  final CuentaCorreo cuenta;

  const CrearPerfilMiniDialog({
    super.key,
    required this.cuenta,
  });

  @override
  State<CrearPerfilMiniDialog> createState() => _CrearPerfilMiniDialogState();
}

class _CrearPerfilMiniDialogState extends State<CrearPerfilMiniDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  
  final _nombreController = TextEditingController();
  final _pinController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final perfil = Perfil(
        id: '00000000-0000-0000-0000-000000000000',
        cuentaId: widget.cuenta.id,
        nombrePerfil: _nombreController.text.trim(),
        pin: _pinController.text.trim().isEmpty ? null : _pinController.text.trim(),
        estado: 'disponible',
        fechaCreacion: DateTime.now(),
      );

      await _supabaseService.crearPerfil(perfil);

      if (mounted) {
        // Recargar y devolver perfil creado
        final perfiles = await _supabaseService.obtenerPerfiles();
        final perfilCreado = perfiles.firstWhere(
          (p) => p.nombrePerfil == perfil.nombrePerfil && p.cuentaId == widget.cuenta.id,
        );
        
        Navigator.pop(context, perfilCreado);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nuevo Perfil',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.cuenta.email,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Perfil *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                  hintText: 'Ej: Principal, Kids, etc.',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => v?.trim().isEmpty == true ? 'Campo requerido' : null,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              
              // PIN (opcional)
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                  hintText: '4 dígitos',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (v) {
  // Si está vacío, es válido (porque es opcional)
  if (v == null || v.isEmpty) {
    return null; 
  }
  // Si tiene algo, entonces sí debe tener 4 dígitos
  if (v.length != 4) {
    return 'El PIN debe tener 4 dígitos';
  }
  return null;
},
                enabled: !_isLoading,
              ),
              const SizedBox(height: 20),
              
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _guardar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Crear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}