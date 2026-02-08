import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/suscripcion.dart';
import '../../models/cliente.dart';
import '../../models/plataforma.dart';
import '../../services/supabase_service.dart';

class RenovarSuscripcionDialog extends StatefulWidget {
  final Suscripcion suscripcion;
  final Cliente cliente;
  final Plataforma plataforma;
  final VoidCallback onRenovada;

  const RenovarSuscripcionDialog({
    super.key,
    required this.suscripcion,
    required this.cliente,
    required this.plataforma,
    required this.onRenovada,
  });

  @override
  State<RenovarSuscripcionDialog> createState() => _RenovarSuscripcionDialogState();
}

class _RenovarSuscripcionDialogState extends State<RenovarSuscripcionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  
  late DateTime _fechaProximoPago;
  String _metodoPago = 'efectivo';
  final _referenciaController = TextEditingController();
  final _notasController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Calcular próxima fecha de pago (mismo día del mes)
    _fechaProximoPago = _calcularProximaFechaPago();
  }

  @override
  void dispose() {
    _referenciaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  /// Calcula la próxima fecha de pago manteniendo el mismo día del mes
  DateTime _calcularProximaFechaPago() {
    final hoy = DateTime.now();
    final diaOriginal = widget.suscripcion.fechaInicio.day;
    
    // Intentar usar el día original del mes
    var proximaFecha = DateTime(hoy.year, hoy.month, diaOriginal);
    
    // Si la fecha ya pasó este mes, usar el próximo mes
    if (proximaFecha.isBefore(hoy)) {
      proximaFecha = DateTime(hoy.year, hoy.month + 1, diaOriginal);
    }
    
    // Manejar casos donde el día no existe en el mes (ej: 31 en febrero)
    // Ajustar al último día del mes si es necesario
    while (proximaFecha.day != diaOriginal && proximaFecha.month != hoy.month + 1) {
      proximaFecha = proximaFecha.subtract(const Duration(days: 1));
    }
    
    return proximaFecha;
  }

  Future<void> _seleccionarFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaProximoPago,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(
                int.parse(widget.plataforma.color.replaceFirst('#', '0xFF')),
              ),
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() => _fechaProximoPago = fechaSeleccionada);
    }
  }

  Future<void> _renovar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _supabaseService.renovarSuscripcion(
        suscripcionId: widget.suscripcion.id,
        clienteId: widget.cliente.id,
        nuevaFechaPago: _fechaProximoPago,
        monto: widget.suscripcion.precio,
        metodoPago: _metodoPago,
        referencia: _referenciaController.text.trim().isEmpty
            ? null
            : _referenciaController.text.trim(),
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suscripción renovada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRenovada();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al renovar: $e'),
            backgroundColor: Colors.red,
          ),
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
    final colorPlataforma = Color(
      int.parse(widget.plataforma.color.replaceFirst('#', '0xFF')),
    );

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
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
                  const Icon(Icons.autorenew, size: 32, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Renovar Suscripción',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.cliente.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info de la suscripción
                      _buildInfoSection(),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Fecha de próximo pago
                      const Text(
                        'Próxima Fecha de Pago',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _seleccionarFecha,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Fecha seleccionada',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('EEEE, dd MMMM yyyy', 'es_ES')
                                          .format(_fechaProximoPago),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit, color: Colors.blue, size: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Método de pago
                      DropdownButtonFormField<String>(
                        value: _metodoPago,
                        decoration: InputDecoration(
                          labelText: 'Método de Pago',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.payment),
                        ),
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
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
                          DropdownMenuItem(
                            value: 'otro',
                            child: Text('Otro'),
                          ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _metodoPago = v!),
                      ),

                      const SizedBox(height: 16),

                      // Referencia
                      TextFormField(
                        controller: _referenciaController,
                        decoration: InputDecoration(
                          labelText: 'Referencia (opcional)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Ej: Transf. #12345',
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.receipt),
                        ),
                        style: const TextStyle(color: Colors.white),
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Notas
                      TextFormField(
                        controller: _notasController,
                        decoration: InputDecoration(
                          labelText: 'Notas (opcional)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Observaciones adicionales',
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.note),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer con botones
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
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _renovar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isLoading ? 'Procesando...' : 'Renovar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorPlataforma,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
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

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Plataforma', widget.plataforma.nombre, Icons.tv),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Cliente',
            widget.cliente.nombreCompleto,
            Icons.person,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Teléfono',
            widget.cliente.telefono,
            Icons.phone,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Precio Mensual',
            'L ${widget.suscripcion.precio.toStringAsFixed(2)}',
            Icons.attach_money,
            valueColor: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Día de Pago Original',
            widget.suscripcion.fechaInicio.day.toString(),
            Icons.event,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}