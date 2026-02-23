// ============================================
// PERFIL_DETALLE_DIALOG.DART - PARTE 1/5
// REEMPLAZAR TODO EL ARCHIVO
// ============================================

import 'package:daleplay/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/perfil.dart';
import '../../models/cuenta_correo.dart';
import '../../models/plataforma.dart';
import '../../models/suscripcion.dart';
import '../../models/cliente.dart';
import '../../services/supabase_service.dart';

class PerfilDetalleDialog extends StatefulWidget {
  final Perfil perfil;
  final CuentaCorreo cuenta;
  final Plataforma plataforma;
  final Suscripcion? suscripcion;
  final Cliente? cliente;
  final String estadoReal;
  final VoidCallback onEdit;

  const PerfilDetalleDialog({
    super.key,
    required this.perfil,
    required this.cuenta,
    required this.plataforma,
    this.suscripcion,
    this.cliente,
    required this.estadoReal,
    required this.onEdit,
  });

  @override
  State<PerfilDetalleDialog> createState() => _PerfilDetalleDialogState();
}

class _PerfilDetalleDialogState extends State<PerfilDetalleDialog> {
  final _supabaseService = SupabaseService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final colorPlataforma = Color(
      int.parse(widget.plataforma.color.replaceFirst('#', '0xFF')),
    );

    final esDisponible = widget.estadoReal == 'disponible';

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header con plataforma y logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorPlataforma, colorPlataforma.withOpacity(0.7)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primera fila: Logo y nombre
                  Row(
                    children: [
                      _buildLogo(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.perfil.nombrePerfil,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.plataforma.nombre,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Segunda fila: Chip de estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: esDisponible
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: esDisponible ? Colors.green : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          esDisponible ? Icons.check_circle : Icons.person,
                          color: esDisponible ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          esDisponible ? 'Disponible' : 'Ocupado',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: esDisponible ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSeccionCredenciales(context),
                    const SizedBox(height: 24),
                    if (widget.cliente != null && widget.suscripcion != null)
                      _buildSeccionCliente(context),
                  ],
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onEdit();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ============================================
  // PERFIL_DETALLE_DIALOG.DART - PARTE 2/5
  // Continuar pegando después de la Parte 1
  // ============================================

  Widget _buildSeccionCredenciales(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Credenciales de la Cuenta',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          context,
          'Email',
          widget.cuenta.email,
          Icons.email,
          Colors.blue,
          copiable: true,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          'Contraseña',
          widget.cuenta.password,
          Icons.lock,
          Colors.orange,
          copiable: true,
          oscurable: true,
        ),
        if (widget.perfil.pin != null && widget.perfil.pin!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            'PIN',
            widget.perfil.pin!,
            Icons.pin,
            Colors.purple,
            copiable: true,
          ),
        ],
      ],
    );
  }

  Widget _buildSeccionCliente(BuildContext context) {
    if (widget.cliente == null || widget.suscripcion == null) {
      return const SizedBox();
    }

    // Calcular días y color usando FechaUtils
    final diasRestantes = FechaUtils.diasRestantes(
      widget.suscripcion!.fechaProximoPago,
    );
    final colorDias = FechaUtils.colorSegunDias(
      widget.suscripcion!.fechaProximoPago,
    ).color;
    final textoVencimiento = FechaUtils.formatearSegunDias(
      widget.suscripcion!.fechaProximoPago,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cliente Asignado',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          context,
          'Nombre',
          widget.cliente!.nombreCompleto,
          Icons.person,
          Colors.white,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          'Teléfono',
          widget.cliente!.telefono,
          Icons.phone,
          Colors.white,
          copiable: true,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          'Precio Mensual',
          'L ${widget.suscripcion!.precio.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          'Próximo Pago',
          DateFormat('dd/MM/yyyy').format(widget.suscripcion!.fechaProximoPago),
          Icons.calendar_month,
          colorDias,
        ),

        // BOTÓN MARCAR INACTIVO (solo si está suspendida con cliente)
        if (widget.suscripcion!.estado == 'suspendida' &&
            widget.cliente != null &&
            widget.suscripcion!.clienteId != null) ...[
          const SizedBox(height: 16),

          // Advertencia
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Gestión Interna',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Al marcar como inactivo:\n'
                  '• Se desliga al cliente\n'
                  '• El perfil queda ocupado\n'
                  '• La suscripción sigue suspendida\n'
                  '• Luego se debe liberar manualmente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Botón
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isProcessing ? null : _marcarComoInactivo,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_remove),
              label: Text(
                _isProcessing ? 'Procesando...' : 'Marcar como Inactivo',
              ),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ),
        ],

        // Chip de vencimiento (solo si no está vencida)
        if (diasRestantes >= 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorDias.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorDias),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 16, color: colorDias),
                const SizedBox(width: 8),
                Text(
                  textoVencimiento,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorDias,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  // ============================================
  // PERFIL_DETALLE_DIALOG.DART - PARTE 3/5
  // Continuar pegando después de la Parte 2
  // ============================================

  Future<void> _marcarComoInactivo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_remove, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(child: Text('Marcar como Inactivo')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Desligar a ${widget.cliente!.nombreCompleto} de este perfil?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Esta acción:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildBullet('Desliga al cliente de la suscripción'),
                  _buildBullet('El perfil queda ocupado (uso interno)'),
                  _buildBullet('La suscripción sigue suspendida'),
                  _buildBullet('Debes liberar el perfil manualmente después'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Sí, marcar inactivo'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isProcessing = true);

    try {
      await _supabaseService.marcarSuscripcionInactiva(widget.suscripcion!.id);

      if (mounted) {
        Navigator.pop(context, true); // Cerrar diálogo y notificar cambio
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente desligado - Perfil queda ocupado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String valor,
    IconData icono,
    Color colorIcono, {
    bool copiable = false,
    bool oscurable = false,
  }) {
    return _InfoRowStateful(
      label: label,
      valor: valor,
      icono: icono,
      colorIcono: colorIcono,
      copiable: copiable,
      oscurable: oscurable,
    );
  }

  Widget _buildLogo() {
    final logos = {
      'Netflix':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Netflix_2015_logo.svg/330px-Netflix_2015_logo.svg.png',
      'Disney+':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Disney%2B_logo.svg/330px-Disney%2B_logo.svg.png',
      'HBO Max':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/HBO_Max_Logo.svg/330px-HBO_Max_Logo.svg.png',
      'Prime Video':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Prime_Video.png/320px-Prime_Video.png',
      'Spotify':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Spotify_logo_without_text.svg/168px-Spotify_logo_without_text.svg.png',
      'YouTube Premium':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/YouTube_full-color_icon_%282017%29.svg/240px-YouTube_full-color_icon_%282017%29.svg.png',
      'Paramount+':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Paramount_Plus.svg/330px-Paramount_Plus.svg.png',
      'Apple TV+':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Apple_TV_Plus_Logo.svg/330px-Apple_TV_Plus_Logo.svg.png',
      'Vix':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/ViX_Logo.png/320px-ViX_Logo.png',
      'Crunchyroll':
          'https://upload.wikimedia.org/wikipedia/en/thumb/9/99/Crunchyroll_logo.svg/320px-Crunchyroll_logo.svg.png',
    };

    final logoUrl = logos[widget.plataforma.nombre];

    if (logoUrl != null) {
      return Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) =>
              const FaIcon(FontAwesomeIcons.tv, size: 24, color: Colors.grey),
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const FaIcon(FontAwesomeIcons.tv, size: 24, color: Colors.grey),
    );
  }
}
// ============================================
// PERFIL_DETALLE_DIALOG.DART - PARTE 4/5
// Continuar pegando después de la Parte 3
// ============================================

// Widget Stateful para mostrar info con opciones de copiar y ocultar
class _InfoRowStateful extends StatefulWidget {
  final String label;
  final String valor;
  final IconData icono;
  final Color colorIcono;
  final bool copiable;
  final bool oscurable;

  const _InfoRowStateful({
    required this.label,
    required this.valor,
    required this.icono,
    required this.colorIcono,
    this.copiable = false,
    this.oscurable = false,
  });

  @override
  State<_InfoRowStateful> createState() => _InfoRowStatefulState();
}

class _InfoRowStatefulState extends State<_InfoRowStateful> {
  bool _mostrar = false;

  @override
  Widget build(BuildContext context) {
    final valorMostrar = widget.oscurable && !_mostrar
        ? '•' * widget.valor.length
        : widget.valor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(widget.icono, size: 20, color: widget.colorIcono),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                const SizedBox(height: 4),
                Text(
                  valorMostrar,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (widget.oscurable)
            IconButton(
              icon: Icon(
                _mostrar ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: Colors.grey[400],
              ),
              onPressed: () => setState(() => _mostrar = !_mostrar),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (widget.copiable) ...[
            if (widget.oscurable) const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.copy, size: 20, color: widget.colorIcono),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.valor));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.label} copiado'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
