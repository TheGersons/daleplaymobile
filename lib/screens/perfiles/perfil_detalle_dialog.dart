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

class PerfilDetalleDialog extends StatelessWidget {
  final Perfil perfil;
  final CuentaCorreo cuenta;
  final Plataforma plataforma;
  final Suscripcion? suscripcion;
  final Cliente? cliente;
  final String estadoReal; // NUEVO: estado calculado
  final VoidCallback onEdit;

  const PerfilDetalleDialog({
    super.key,
    required this.perfil,
    required this.cuenta,
    required this.plataforma,
    this.suscripcion,
    this.cliente,
    required this.estadoReal, // NUEVO
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorPlataforma = Color(
      int.parse(plataforma.color.replaceFirst('#', '0xFF')),
    );

    final esDisponible = estadoReal == 'disponible'; // USAR estadoReal

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
                  colors: [
                    colorPlataforma,
                    colorPlataforma.withOpacity(0.7),
                  ],
                ),
              ),
              child: Row(
                children: [
                  _buildLogo(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perfil.nombrePerfil,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plataforma.nombre,
                          style: const TextStyle(
                            fontSize: 16,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estado
                    _buildEstadoChip(esDisponible),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Credenciales de la cuenta
                    _buildSeccionCredenciales(context),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Información del perfil
                    _buildSeccionInformacion(context),

                    if (!esDisponible && cliente != null) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      _buildSeccionCliente(context),
                    ],
                  ],
                ),
              ),
            ),

            // Footer con botón de editar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border(top: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Perfil'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorPlataforma,
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

  Widget _buildLogo() {
    final logos = {
      'Netflix':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Netflix_2015_logo.svg/330px-Netflix_2015_logo.svg.png',
      'Mega Premium - Netflix':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Netflix_2015_logo.svg/330px-Netflix_2015_logo.svg.png',
      'Disney+':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Disney%2B_logo.svg/330px-Disney%2B_logo.svg.png',
      'HBO':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/HBO_logo.svg/330px-HBO_logo.svg.png',
      'HBO Max':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/HBO_Max_Logo.svg/330px-HBO_Max_Logo.svg.png',
      'Max':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/HBO_Max_Logo.svg/330px-HBO_Max_Logo.svg.png',
      'Prime Video':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Prime_Video_logo_%282024%29.svg/640px-Prime_Video_logo_%282024%29.svg.png',
      'Spotify':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Spotify_logo_without_text.svg/168px-Spotify_logo_without_text.svg.png',
      'YouTube Premium':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/YouTube_social_white_circle_%282017%29.svg/640px-YouTube_social_white_circle_%282017%29.svg.png',
      'Paramount+':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Paramount_Plus.svg/330px-Paramount_Plus.svg.png',
      'Apple TV+':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Apple_TV_Plus_Logo.svg/330px-Apple_TV_Plus_Logo.svg.png',
      'Vix':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/ViX_Logo.png/1280px-ViX_Logo.png?20220404085413',
      'Viki':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Rakuten_Viki_logo.svg/640px-Rakuten_Viki_logo.svg.png',
      'Crunchyroll':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Crunchyroll_logo_2018_vertical.png/640px-Crunchyroll_logo_2018_vertical.png',
    };

    final logoUrl = logos[plataforma.nombre];

    if (logoUrl != null) {
      return Container(
        width: 64,
        height: 64,
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
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

  Widget _buildEstadoChip(bool esDisponible) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: esDisponible
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
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
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              esDisponible ? 'DISPONIBLE' : 'OCUPADO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: esDisponible ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          cuenta.email,
          Icons.email,
          Colors.blue,
          copiable: true,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          'Contraseña',
          cuenta.password,
          Icons.lock,
          Colors.orange,
          copiable: true,
          oscurable: true,
        ),
      ],
    );
  }

  Widget _buildSeccionInformacion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información del Perfil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        if (perfil.pin != null && perfil.pin!.isNotEmpty)
          _buildInfoRow(
            context,
            'PIN',
            perfil.pin!,
            Icons.pin,
            Colors.purple,
            copiable: true,
          ),
        if (perfil.pin != null && perfil.pin!.isNotEmpty)
          const SizedBox(height: 12),
        _buildInfoRow(
          context,
          'Fecha de Creación',
          DateFormat('dd/MM/yyyy HH:mm').format(perfil.fechaCreacion),
          Icons.calendar_today,
          Colors.grey,
        ),
      ],
    );
  }

  Widget _buildSeccionCliente(BuildContext context) {
    if (cliente == null || suscripcion == null) return const SizedBox();

    // Calcular días para próximo pago
    final hoy = DateTime.now();
    final diasRestantes = suscripcion!.fechaProximoPago.difference(hoy).inDays;
    
    Color colorDias;
    if (diasRestantes < 0) {
      colorDias = Colors.red[900]!;
    } else if (diasRestantes == 0) {
      colorDias = Colors.red;
    } else if (diasRestantes == 1) {
      colorDias = Colors.orange;
    } else if (diasRestantes <= 3) {
      colorDias = Colors.blue;
    } else {
      colorDias = Colors.green;
    }

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
          cliente!.nombreCompleto,
          Icons.person,
          Colors.white,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          'Teléfono',
          cliente!.telefono,
          Icons.phone,
          Colors.white,
          copiable: true,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          'Precio Mensual',
          'L ${suscripcion!.precio.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          'Próximo Pago',
          DateFormat('dd/MM/yyyy').format(suscripcion!.fechaProximoPago),
          Icons.calendar_month,
          colorDias,
        ),
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
                  diasRestantes == 0
                      ? 'Vence HOY'
                      : diasRestantes == 1
                          ? 'Vence MAÑANA'
                          : 'Faltan $diasRestantes días',
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
}

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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
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