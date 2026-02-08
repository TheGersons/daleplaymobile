import 'package:flutter/material.dart';
import '../../models/cuenta_correo.dart';
import '../../models/plataforma.dart';
import '../../services/supabase_service.dart';

class CrearCuentaMiniDialog extends StatefulWidget {
  final Plataforma plataforma;

  const CrearCuentaMiniDialog({super.key, required this.plataforma});

  @override
  State<CrearCuentaMiniDialog> createState() => _CrearCuentaMiniDialogState();
}

class _CrearCuentaMiniDialogState extends State<CrearCuentaMiniDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cuenta = CuentaCorreo(
        id: '00000000-0000-0000-0000-000000000000',
        email: _emailController.text.trim(),
        password: _passwordController.text,
        plataformaId: widget.plataforma.id,
        estado: 'activo',
        fechaCreacion: DateTime.now(),
        notas: null,
      );

      // crearCuenta() ahora retorna el ID y crea los perfiles automáticamente
      final cuentaId = await _supabaseService.crearCuenta(cuenta);

      if (mounted) {
        // Recargar cuentas y perfiles
        final cuentas = await _supabaseService.obtenerCuentas();
        final cuentaCreada = cuentas.firstWhere((c) => c.id == cuentaId);

        // Mostrar éxito con info de perfiles creados
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cuenta creada con ${widget.plataforma.maxPerfiles} perfiles disponibles',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, cuentaCreada);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
                  Icon(
                    Icons.email,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nueva Cuenta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.plataforma.nombre,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.trim().isEmpty == true) return 'Campo requerido';
                  if (!v!.contains('@')) return 'Email inválido';
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Campo requerido' : null,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
