import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/suscripcion.dart';
import '../../models/cliente.dart';
import '../../models/plataforma.dart';
import '../../models/perfil.dart';
import '../../services/supabase_service.dart';

class ReactivarSuscripcionDialog extends StatefulWidget {
  final Suscripcion suscripcion;
  final Cliente cliente;
  final Plataforma plataforma;
  final Perfil perfil;

  const ReactivarSuscripcionDialog({
    super.key,
    required this.suscripcion,
    required this.cliente,
    required this.plataforma,
    required this.perfil,
  });

  @override
  State<ReactivarSuscripcionDialog> createState() =>
      _ReactivarSuscripcionDialogState();
}

class _ReactivarSuscripcionDialogState
    extends State<ReactivarSuscripcionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  final _montoController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _notasController = TextEditingController();

  DateTime _fechaProximoPago = DateTime.now().add(const Duration(days: 30));
  String _metodoPago = 'efectivo';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _montoController.text = widget.suscripcion.precio.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaProximoPago,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fechaSeleccionada != null) {
      setState(() => _fechaProximoPago = fechaSeleccionada);
    }
  }

  Future<void> _reactivar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _supabaseService.reactivarSuscripcion(
        suscripcionId: widget.suscripcion.id,
        clienteId: widget.cliente.id,
        nuevaFechaPago: _fechaProximoPago,
        monto: double.parse(_montoController.text),
        metodoPago: _metodoPago,
        referencia: _referenciaController.text.trim().isEmpty
            ? null
            : _referenciaController.text.trim(),
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suscripción reactivada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reactivar: $e'),
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

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorPlataforma, colorPlataforma.withOpacity(0.7)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Reactivar Suscripción',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenido
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info cliente
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
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
                              widget.cliente.nombreCompleto,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.perfil.nombrePerfil,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Fecha próximo pago
                      InkWell(
                        onTap: _seleccionarFecha,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Próximo Pago',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_month),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_fechaProximoPago),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Monto
                      TextFormField(
                        controller: _montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          prefixText: 'L ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa el monto';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Monto inválido';
                          }
                          if (double.parse(value) <= 0) {
                            return 'El monto debe ser mayor a 0';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Método de pago
                      DropdownButtonFormField<String>(
                        value: _metodoPago,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'efectivo',
                            child: Text('Efectivo'),
                          ),
                          DropdownMenuItem(
                            value: 'transferencia',
                            child: Text('Transferencia'),
                          ),
                          DropdownMenuItem(
                            value: 'deposito',
                            child: Text('Depósito'),
                          ),
                          DropdownMenuItem(value: 'otro', child: Text('Otro')),
                        ],
                        onChanged: (value) =>
                            setState(() => _metodoPago = value!),
                      ),

                      const SizedBox(height: 16),

                      // Referencia
                      TextFormField(
                        controller: _referenciaController,
                        decoration: const InputDecoration(
                          labelText: 'Referencia (opcional)',
                          hintText: 'Número de transacción',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notas
                      TextFormField(
                        controller: _notasController,
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border(top: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _reactivar,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Reactivar y Pagar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
