import 'package:daleplay/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/cliente.dart';
import '../../models/suscripcion.dart';
import '../../models/plataforma.dart';
import '../../models/perfil.dart';
import '../../models/cuenta_correo.dart';

class ClienteDetalleDialog extends StatelessWidget {
  final Cliente cliente;
  final List<Suscripcion> suscripciones;
  final List<Plataforma> plataformas;
  final List<Perfil> perfiles;
  final List<CuentaCorreo> cuentas;
  final VoidCallback? onEditar;

  const ClienteDetalleDialog({
    super.key,
    required this.cliente,
    required this.suscripciones,
    required this.plataformas,
    required this.perfiles,
    required this.cuentas,
    this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrar suscripciones de este cliente
    final suscripcionesCliente = suscripciones
        .where((s) => s.clienteId == cliente.id)
        .toList();

    final isActivo = cliente.estado == 'activo';
    final colorEstado = isActivo ? Colors.green : Colors.grey;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorEstado, colorEstado.withOpacity(0.7)],
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      cliente.nombreCompleto.isNotEmpty
                          ? cliente.nombreCompleto[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorEstado,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                cliente.telefono,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              color: Colors.white70,
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: cliente.telefono),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Teléfono copiado'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              tooltip: 'Copiar teléfono',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Botón editar
                  if (onEditar != null)
                    IconButton.filledTonal(
                      onPressed: onEditar,
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar cliente',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: colorEstado,
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colorEstado,
                    ),
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
                    // Estadísticas
                    _buildEstadisticas(suscripcionesCliente),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Lista de suscripciones
                    _buildSeccionSuscripciones(suscripcionesCliente, context),

                    // Notas
                    if (cliente.notas != null && cliente.notas!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      _buildSeccionNotas(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticas(List<Suscripcion> suscripcionesCliente) {
    final activas = suscripcionesCliente
        .where((s) => s.estado == 'activa')
        .length;
    final vencidas = suscripcionesCliente
        .where((s) => s.estado == 'vencida')
        .length;
    final totalMensual = suscripcionesCliente
        .where((s) => s.estado == 'activa')
        .fold(0.0, (sum, s) => sum + s.precio);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de Suscripciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildEstadisticaCard(
                'Total',
                suscripcionesCliente.length.toString(),
                Icons.grid_view,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEstadisticaCard(
                'Activas',
                activas.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEstadisticaCard(
                'Vencidas',
                vencidas.toString(),
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple),
          ),
          child: Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.purple, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pago Mensual Total',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    'L ${totalMensual.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticaCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildSeccionSuscripciones(
    List<Suscripcion> suscripcionesCliente,
    BuildContext context,
  ) {
    if (suscripcionesCliente.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.subscriptions_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No tiene suscripciones registradas',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suscripciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...suscripcionesCliente.map(
          (suscripcion) => _buildSuscripcionCard(suscripcion, context),
        ),
      ],
    );
  }

  Widget _buildSuscripcionCard(Suscripcion suscripcion, BuildContext context) {
    final plataforma = plataformas.firstWhere(
      (p) => p.id == suscripcion.plataformaId,
      orElse: () => Plataforma(
        id: '',
        nombre: 'Desconocida',
        icono: '',
        precioBase: 0,
        maxPerfiles: 0,
        color: '#999999',
        estado: '',
        fechaCreacion: DateTime.now(),
      ),
    );

    final perfil = perfiles.firstWhere(
      (p) => p.id == suscripcion.perfilId,
      orElse: () => Perfil(
        id: '',
        cuentaId: '',
        nombrePerfil: 'Desconocido',
        pin: '',
        estado: '',
        fechaCreacion: DateTime.now(),
      ),
    );

    final cuenta = cuentas.firstWhere(
      (c) => c.id == perfil.cuentaId,
      orElse: () => CuentaCorreo(
        id: '',
        email: '',
        password: '',
        plataformaId: '',
        estado: '',
        fechaCreacion: DateTime.now(),
      ),
    );

    final colorPlataforma = Color(
      int.parse(plataforma.color.replaceFirst('#', '0xFF')),
    );

    final esActiva = suscripcion.estado == 'activa';
    final colorEstado = esActiva ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Header con logo de plataforma
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorPlataforma.withOpacity(0.8),
                  colorPlataforma.withOpacity(0.6),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _buildLogo(plataforma),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plataforma.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suscripcion.tipoSuscripcion == 'cuenta_completa'
                            ? 'Cuenta Completa'
                            : 'Perfil Individual',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    esActiva ? 'Activa' : 'Vencida',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorEstado,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Credenciales
                _CredencialesSection(cuenta: cuenta),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Información del perfil
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Perfil',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  perfil.nombrePerfil,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (perfil.pin != null &&
                                  perfil.pin!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                _buildPinChip(perfil.pin!, context),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Precio',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'L ${suscripcion.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Próximo pago
                _buildFechaProximoPago(suscripcion),

                const SizedBox(height: 12),

                // Fechas adicionales
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        'Inicio',
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(suscripcion.fechaInicio),
                        Icons.event_available,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        'Creada',
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(suscripcion.fechaCreacion),
                        Icons.access_time,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(Plataforma plataforma) {
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
        width: 56,
        height: 56,
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
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const FaIcon(FontAwesomeIcons.tv, size: 24, color: Colors.grey),
    );
  }

  Widget _buildPinChip(String pin, BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: pin));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN copiado'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 12, color: Colors.purple),
            const SizedBox(width: 4),
            Text(
              pin,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.copy, size: 12, color: Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildFechaProximoPago(Suscripcion suscripcion) {
    final dias = FechaUtils.diasRestantes(suscripcion.fechaProximoPago);
    final diasColor = FechaUtils.colorSegunDias(
      suscripcion.fechaProximoPago,
    ).color;
    final diasTexto = FechaUtils.formatearSegunDias(
      suscripcion.fechaProximoPago,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: diasColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: diasColor),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: diasColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próximo Pago',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
                const SizedBox(height: 2),
                Text(
                  diasTexto,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(suscripcion.fechaProximoPago),
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionNotas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            cliente.notas!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// Widget separado para las credenciales con estado
class _CredencialesSection extends StatefulWidget {
  final CuentaCorreo cuenta;

  const _CredencialesSection({required this.cuenta});

  @override
  State<_CredencialesSection> createState() => _CredencialesSectionState();
}

class _CredencialesSectionState extends State<_CredencialesSection> {
  bool _mostrarPassword = false;

  void _copiar(String texto, String tipo) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$tipo copiado al portapapeles'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Credenciales de Acceso',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Email
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.email, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correo',
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                    Text(
                      widget.cuenta.email,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                ),
                onPressed: () => _copiar(widget.cuenta.email, 'Email'),
                tooltip: 'Copiar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Contraseña
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contraseña',
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                    Text(
                      _mostrarPassword ? widget.cuenta.password : '••••••••',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all<Color>(
                    Colors.orange,
                  ),
                ),
                icon: Icon(
                  _mostrarPassword ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                ),
                onPressed: () =>
                    setState(() => _mostrarPassword = !_mostrarPassword),
                tooltip: _mostrarPassword ? 'Ocultar' : 'Mostrar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all<Color>(
                    Colors.orange,
                  ),
                ),
                onPressed: () => _copiar(widget.cuenta.password, 'Contraseña'),
                tooltip: 'Copiar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
