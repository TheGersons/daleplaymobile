import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/cliente.dart';
import '../../services/supabase_service.dart';

class CrearClienteMiniDialog extends StatefulWidget {
  const CrearClienteMiniDialog({super.key});

  @override
  State<CrearClienteMiniDialog> createState() => _CrearClienteMiniDialogState();
}

class _CrearClienteMiniDialogState extends State<CrearClienteMiniDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cliente = Cliente(
        id: '00000000-0000-0000-0000-000000000000',
        nombreCompleto: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        estado: 'activo',
        fechaRegistro: DateTime.now(),
        notas: null,
      );

      await _supabaseService.crearCliente(cliente);

      if (mounted) {
        // Recargar lista de clientes
        final clientes = await _supabaseService.obtenerClientes();
        final clienteCreado = clientes.firstWhere(
          (c) => c.nombreCompleto == cliente.nombreCompleto && c.telefono == cliente.telefono,
        );
        
        Navigator.pop(context, clienteCreado); // Devolver cliente creado
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
                  const Text(
                    'Nuevo Cliente',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => v?.trim().isEmpty == true ? 'Campo requerido' : null,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              
              // Teléfono
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '0000-0000',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: (v) {
                  if (v?.trim().isEmpty == true) return 'Campo requerido';
                  if (v!.length != 8) return 'Debe tener 8 dígitos';
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