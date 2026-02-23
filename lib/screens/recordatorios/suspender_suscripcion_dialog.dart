import 'package:flutter/material.dart';
import '../../models/suscripcion.dart';
import '../../models/cliente.dart';
import '../../models/plataforma.dart';
import '../../models/perfil.dart';
import '../../services/supabase_service.dart';

class SuspenderSuscripcionDialog extends StatefulWidget {
  final Suscripcion suscripcion;
  final Cliente cliente;
  final Plataforma plataforma;
  final Perfil perfil;

  const SuspenderSuscripcionDialog({
    super.key,
    required this.suscripcion,
    required this.cliente,
    required this.plataforma,
    required this.perfil,
  });

  @override
  State<SuspenderSuscripcionDialog> createState() =>
      _SuspenderSuscripcionDialogState();
}

class _SuspenderSuscripcionDialogState
    extends State<SuspenderSuscripcionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  final _motivoController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _suspender() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _supabaseService.suspenderSuscripcion(
        widget.suscripcion.id,
        motivo: _motivoController.text.trim().isEmpty
            ? null
            : _motivoController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suscripción suspendida exitosamente'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al suspender: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorPlataforma = Color(
      int.parse(widget.plataforma.color.replaceFirst('#', '0xFF')),
    );

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.pause_circle, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(child: Text('Suspender Suscripción')),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info de la suscripción
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorPlataforma.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorPlataforma.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plataforma.nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorPlataforma,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.cliente.nombreCompleto} - ${widget.perfil.nombrePerfil}',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'L ${widget.suscripcion.precio.toStringAsFixed(2)}/mes',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Explicación
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '¿Qué significa suspender?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• El cliente NO tendrá acceso\n'
                      '• El perfil NO se libera para otros\n'
                      '• Puedes reactivar o cancelar después',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Motivo (opcional)
              TextFormField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  hintText: 'Ej: Cliente solicita pausa temporal',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _suspender,
          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Suspender'),
        ),
      ],
    );
  }
}
