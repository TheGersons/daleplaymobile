import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/cuenta_correo.dart';
import '../../models/plataforma.dart';
import '../../models/perfil.dart';
import '../../models/cliente.dart';
import '../../models/suscripcion.dart';

class CuentaDetalleDialog extends StatelessWidget {
  final CuentaCorreo cuenta;
  final Plataforma plataforma;
  final List<Perfil> perfiles;
  final List<Cliente> clientes;
  final List<Suscripcion> suscripciones;
  final VoidCallback? onEditar;

  const CuentaDetalleDialog({
    super.key,
    required this.cuenta,
    required this.plataforma,
    required this.perfiles,
    required this.clientes,
    required this.suscripciones,
    this.onEditar,
  });

  // Calcular si un perfil está realmente disponible
  bool _perfilEstaDisponible(Perfil perfil) {
    return !suscripciones.any(
      (s) => s.perfilId == perfil.id && s.estado != 'cancelada',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorPlataforma = Color(
      int.parse(plataforma.color.replaceFirst('#', '0xFF')),
    );

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
                  colors: [colorPlataforma, colorPlataforma.withOpacity(0.7)],
                ),
              ),
              child: Row(
                children: [
                  _buildLogo(plataforma),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plataforma.nombre,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cuenta: ${cuenta.email}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón editar
                  IconButton.filledTonal(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar cuenta',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colorPlataforma,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colorPlataforma,
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
                    // Información de la cuenta
                    _buildSeccionCredenciales(context),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Estadísticas de perfiles
                    _buildEstadisticasPerfiles(),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Lista de perfiles
                    _buildSeccionPerfiles(context),

                    // Notas
                    if (cuenta.notas != null && cuenta.notas!.isNotEmpty) ...[
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

  Widget _buildSeccionCredenciales(BuildContext context) {
    return _CredencialesSection(cuenta: cuenta);
  }

  Widget _buildEstadisticasPerfiles() {
    final perfilesDeCuenta = perfiles.where((p) => p.cuentaId == cuenta.id);

    final perfilesDisponibles = perfilesDeCuenta
        .where((p) => _perfilEstaDisponible(p))
        .length;
    final perfilesOcupados = perfilesDeCuenta
        .where((p) => !_perfilEstaDisponible(p))
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildEstadisticaCard(
            'Total',
            perfiles.length.toString(),
            Icons.grid_view,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEstadisticaCard(
            'Disponibles',
            perfilesDisponibles.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEstadisticaCard(
            'Ocupados',
            perfilesOcupados.toString(),
            Icons.person,
            Colors.orange,
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
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSeccionPerfiles(BuildContext context) {
    if (perfiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay perfiles en esta cuenta',
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
          'Perfiles',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...perfiles.map((perfil) => _buildPerfilCard(perfil, context)),
      ],
    );
  }

  Widget _buildPerfilCard(Perfil perfil, BuildContext context) {
    // Buscar suscripción asociada al perfil
    final suscripcion = suscripciones.firstWhere(
      (s) => s.perfilId == perfil.id,
      orElse: () => Suscripcion(
        id: '',
        clienteId: '',
        perfilId: '',
        plataformaId: '',
        tipoSuscripcion: '',
        precio: 0,
        fechaInicio: DateTime.now(),
        fechaProximoPago: DateTime.now(),
        fechaLimitePago: DateTime.now(),
        estado: '',
        fechaCreacion: DateTime.now(),
      ),
    );

    Cliente? cliente;
    final esDisponible = _perfilEstaDisponible(perfil);

    if (!esDisponible && suscripcion.id.isNotEmpty) {
      cliente = clientes.firstWhere(
        (c) => c.id == suscripcion.clienteId,
        orElse: () => Cliente(
          id: '',
          nombreCompleto: 'Desconocido',
          telefono: '',
          estado: '',
          fechaRegistro: DateTime.now(),
        ),
      );
    }

    final colorEstado = esDisponible ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del perfil
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorEstado.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: colorEstado, width: 2),
                    ),
                    child: Icon(
                      esDisponible ? Icons.check_circle : Icons.person,
                      color: colorEstado,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorEstado.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorEstado),
                          ),
                          child: Text(
                            esDisponible ? 'Disponible' : 'Ocupado',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorEstado,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Información del cliente (solo si está ocupado)
              if (!esDisponible &&
                  cliente != null &&
                  cliente.id.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Cliente',
                  cliente.nombreCompleto,
                  Icons.person,
                  context,
                ),
                const SizedBox(height: 8),
                _buildInfoRowWithCopy(
                  'Teléfono',
                  cliente.telefono,
                  Icons.phone,
                  context,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Precio',
                  'L ${suscripcion.precio.toStringAsFixed(2)}',
                  Icons.attach_money,
                  context,
                ),
                const SizedBox(height: 8),
                _buildFechaProximoPago(suscripcion, context),
              ],

              // Fecha de creación del perfil
              const SizedBox(height: 12),
              Text(
                'Creado: ${DateFormat('dd/MM/yyyy').format(perfil.fechaCreacion)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.white)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithCopy(
    String label,
    String value,
    IconData icon,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.white)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copiado'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          tooltip: 'Copiar',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildFechaProximoPago(Suscripcion suscripcion, BuildContext context) {
    final hoy = DateTime.now();
    final dias = suscripcion.fechaProximoPago.difference(hoy).inDays;

    Color diasColor;
    String diasTexto;

    if (dias < 0) {
      diasColor = Colors.red;
      diasTexto = 'Vencida hace ${-dias} ${-dias == 1 ? 'día' : 'días'}';
    } else if (dias == 0) {
      diasColor = Colors.orange;
      diasTexto = 'Vence hoy';
    } else if (dias <= 3) {
      diasColor = Colors.orange;
      diasTexto = 'Vence en $dias ${dias == 1 ? 'día' : 'días'}';
    } else if (dias <= 7) {
      diasColor = Colors.blue;
      diasTexto = 'Vence en $dias días';
    } else {
      diasColor = Colors.green;
      diasTexto = 'Vence en $dias días';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: diasColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: diasColor),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: diasColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diasTexto,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: diasColor,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(suscripcion.fechaProximoPago),
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            cuenta.notas!,
            style: const TextStyle(color: Colors.black87),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Email
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.email, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correo Electrónico',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                    Text(
                      widget.cuenta.email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                ),
                onPressed: () => _copiar(widget.cuenta.email, 'Email'),
                tooltip: 'Copiar',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Contraseña
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contraseña',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                    Text(
                      _mostrarPassword ? widget.cuenta.password : '••••••••',
                      style: const TextStyle(
                        fontSize: 14,
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
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _mostrarPassword = !_mostrarPassword),
                tooltip: _mostrarPassword ? 'Ocultar' : 'Mostrar',
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all<Color>(
                    Colors.orange,
                  ),
                ),
                onPressed: () => _copiar(widget.cuenta.password, 'Contraseña'),
                tooltip: 'Copiar',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
