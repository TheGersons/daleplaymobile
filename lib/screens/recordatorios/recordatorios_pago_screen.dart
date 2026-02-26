import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/suscripcion.dart';
import '../../models/cliente.dart';
import '../../models/plataforma.dart';
import '../../models/perfil.dart';
import '../../models/cuenta_correo.dart';
import '../../services/supabase_service.dart';
import 'renovar_suscripcion_dialog.dart';
import 'suspender_suscripcion_dialog.dart';
import 'reactivar_suscripcion_dialog.dart';

class RecordatoriosPagoScreen extends StatefulWidget {
  const RecordatoriosPagoScreen({super.key});

  @override
  State<RecordatoriosPagoScreen> createState() =>
      _RecordatoriosPagoScreenState();
}

class _RecordatoriosPagoScreenState extends State<RecordatoriosPagoScreen>
    with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  static const String CLIENTE_SIN_ASIGNAR =
      '00000000-0000-0000-0000-000000000001';

  late TabController _tabController;

  List<Suscripcion> _suscripcionesRecordatorio = [];
  List<Suscripcion> _suscripcionesEspera = [];
  List<Suscripcion> _suscripcionesSuspendidas = [];
  List<Cliente> _clientes = [];
  List<Plataforma> _plataformas = [];
  List<Perfil> _perfiles = [];
  List<CuentaCorreo> _cuentas = [];
  List<Suscripcion> _suscripciones = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final recordatorio = await _supabaseService
          .obtenerSuscripcionesParaRecordatorio();
      final espera = await _supabaseService.obtenerSuscripcionesEnEspera();
      final suspendidas = await _supabaseService
          .obtenerSuscripcionesSuspendidas();
      final clientes = await _supabaseService.obtenerClientes();
      final plataformas = await _supabaseService.obtenerPlataformas();
      final perfiles = await _supabaseService.obtenerPerfiles();
      final cuentas = await _supabaseService.obtenerCuentas();
      final todasSuscripciones = await _supabaseService.obtenerSuscripciones();

      setState(() {
        _suscripcionesRecordatorio = recordatorio;
        _suscripcionesEspera = espera;
        _clientes = clientes;
        _plataformas = plataformas;
        _suscripcionesSuspendidas = suspendidas;
        _perfiles = perfiles;
        _cuentas = cuentas;
        _suscripciones = todasSuscripciones;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Calcular días restantes comparando solo fechas (sin hora)
  int _diasRestantes(DateTime fechaVencimiento) {
    final hoy = DateTime.now();
    final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);
    final vencimientoSoloFecha = DateTime(
      fechaVencimiento.year,
      fechaVencimiento.month,
      fechaVencimiento.day,
    );

    return vencimientoSoloFecha.difference(hoySoloFecha).inDays;
  }

  Map<String, List<Suscripcion>> _agruparPorCuenta(
    List<Suscripcion> suscripciones,
  ) {
    final Map<String, List<Suscripcion>> agrupadas = {};

    for (final suscripcion in suscripciones) {
      // AGREGAR orElse para evitar "No element"
      final perfil = _perfiles.firstWhere(
        (p) => p.id == suscripcion.perfilId,
        orElse: () => Perfil(
          id: '',
          cuentaId: '',
          nombrePerfil: '',
          pin: '',
          estado: '',
          fechaCreacion: DateTime.now(),
        ),
      );

      // Validar que el perfil existe antes de continuar
      if (perfil.id.isEmpty) continue;

      final cuentaId = perfil.cuentaId;

      if (!agrupadas.containsKey(cuentaId)) {
        agrupadas[cuentaId] = [];
      }
      agrupadas[cuentaId]!.add(suscripcion);
    }

    return agrupadas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pagos'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Recordatorios'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('En Espera', style: TextStyle(fontSize: 14)),
                  if (_suscripcionesEspera.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_suscripcionesEspera.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Suspendidas', style: TextStyle(fontSize: 14)),
                  if (_suscripcionesSuspendidas.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_suscripcionesSuspendidas.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecordatoriosTab(),
                _buildEsperaTab(),
                _buildTabSuspendidas(),
              ],
            ),
    );
  }

  // ==================== TAB 1: RECORDATORIOS ====================

  Widget _buildRecordatoriosTab() {
    if (_suscripcionesRecordatorio.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay recordatorios pendientes',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Todos los recordatorios han sido enviados',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Agrupar por cliente
    final Map<String, List<Suscripcion>> suscripcionesPorCliente = {};
    for (final suscripcion in _suscripcionesRecordatorio) {
      if (!suscripcionesPorCliente.containsKey(suscripcion.clienteId)) {
        suscripcionesPorCliente[suscripcion.clienteId] = [];
      }
      suscripcionesPorCliente[suscripcion.clienteId]!.add(suscripcion);
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: suscripcionesPorCliente.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final clienteId = suscripcionesPorCliente.keys.elementAt(index);
          final suscripciones = suscripcionesPorCliente[clienteId]!;
          final cliente = _clientes.firstWhere((c) => c.id == clienteId);

          return _buildClienteRecordatorioCard(cliente, suscripciones);
        },
      ),
    );
  }

  Widget _buildClienteRecordatorioCard(
    Cliente cliente,
    List<Suscripcion> suscripciones,
  ) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            cliente.nombreCompleto[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          cliente.nombreCompleto,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cliente.telefono,
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: cliente.telefono));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teléfono copiado'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, size: 12, color: Colors.blue[300]),
                  const SizedBox(width: 4),
                  Text(
                    'Copiar',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[300],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 180,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(
                label: Text('${suscripciones.length}'),
                avatar: const Icon(Icons.subscriptions, size: 16),
                backgroundColor: Colors.orange.withOpacity(0.2),
                side: const BorderSide(color: Colors.orange),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () =>
                    _marcarTodasRecordatorio(cliente, suscripciones),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Todas'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        children: suscripciones
            .map((s) => _buildSuscripcionRecordatorioTile(s, cliente))
            .toList(),
      ),
    );
  }

  Widget _buildSuscripcionRecordatorioTile(
    Suscripcion suscripcion,
    Cliente cliente,
  ) {
    final plataforma = _plataformas.firstWhere(
      (p) => p.id == suscripcion.plataformaId,
    );
    final colorPlataforma = Color(
      int.parse(plataforma.color.replaceFirst('#', '0xFF')),
    );

    final dias = _diasRestantes(suscripcion.fechaProximoPago);
    final esHoy = dias == 0;
    final esManana = dias == 1;
    //final esManana = dias == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildLogo(plataforma),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plataforma.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: esHoy
                            ? Colors.red.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: esHoy ? Colors.red : Colors.orange,
                        ),
                      ),
                      child: Text(
                        esHoy ? 'HOY' : 'MAÑANA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: esHoy ? Colors.red : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.event, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(suscripcion.fechaProximoPago),
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.attach_money, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'L ${suscripcion.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _marcarRecordatorio(suscripcion, cliente),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Enviado', style: TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              backgroundColor: colorPlataforma,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _marcarRecordatorio(
    Suscripcion suscripcion,
    Cliente cliente,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Recordatorio'),
        content: Text(
          '¿Confirmas que enviaste el recordatorio de pago a ${cliente.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _supabaseService.marcarRecordatorioEnviado(suscripcion.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recordatorio marcado'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarDatos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _marcarTodasRecordatorio(
    Cliente cliente,
    List<Suscripcion> suscripciones,
  ) async {
    print(
      '🟢 [SCREEN] Iniciando marcado masivo para: ${cliente.nombreCompleto}',
    );
    print('🟢 [SCREEN] Total de suscripciones: ${suscripciones.length}');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Recordatorios'),
        content: Text(
          '¿Confirmas que enviaste los recordatorios de pago a ${cliente.nombreCompleto}?\n\n'
          'Se marcarán ${suscripciones.length} suscripción(es).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar Todo'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      print('🟢 [SCREEN] Usuario confirmó el marcado masivo');

      try {
        for (int i = 0; i < suscripciones.length; i++) {
          final suscripcion = suscripciones[i];
          print(
            '🟢 [SCREEN] Procesando suscripción ${i + 1}/${suscripciones.length}',
          );
          print('🟢 [SCREEN] ID: ${suscripcion.id}');
          print('🟢 [SCREEN] Estado actual: ${suscripcion.estado}');

          await _supabaseService.marcarRecordatorioEnviado(suscripcion.id);

          print('✅ [SCREEN] Suscripción ${i + 1} marcada exitosamente');
        }

        print('✅ [SCREEN] Todas las suscripciones fueron marcadas');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${suscripciones.length} recordatorio(s) marcado(s)',
              ),
              backgroundColor: Colors.green,
            ),
          );

          print('🟢 [SCREEN] Recargando datos...');
          await _cargarDatos();
          print('✅ [SCREEN] Datos recargados');
        }
      } catch (e, stackTrace) {
        print('❌ [SCREEN ERROR] Error en marcado masivo: $e');
        print('❌ [SCREEN ERROR] Stack trace: $stackTrace');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      print('🟡 [SCREEN] Usuario canceló el marcado masivo');
    }
  }

  // ==================== TAB 2: LISTA DE ESPERA ====================

  Widget _buildEsperaTab() {
    if (_suscripcionesEspera.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay pagos en espera pendientes',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay suscripciones esperando pago',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Agrupar por cuenta
    final agrupadas = _agruparPorCuenta(_suscripcionesEspera);

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: agrupadas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final cuentaId = agrupadas.keys.elementAt(index);
          final suscripciones = agrupadas[cuentaId]!;
          final cuenta = _cuentas.firstWhere((c) => c.id == cuentaId);
          final plataforma = _plataformas.firstWhere(
            (p) => p.id == cuenta.plataformaId,
          );

          return _buildCuentaEsperaCard(cuenta, plataforma, suscripciones);
        },
      ),
    );
  }

  Widget _buildCuentaEsperaCard(
    CuentaCorreo cuenta,
    Plataforma plataforma,
    List<Suscripcion> suscripcionesEnEspera,
  ) {
    final colorPlataforma = Color(
      int.parse(plataforma.color.replaceFirst('#', '0xFF')),
    );

    // Obtener TODOS los perfiles de esta cuenta
    final todosPerfiles = _obtenerTodosPerfilesDeCuenta(cuenta.id);

    // Separar por categorías
    final perfilesEnEspera = todosPerfiles.where((p) {
      final estado = _obtenerEstadoPerfil(
        p['perfil'] as Perfil,
        p['suscripcion'] as Suscripcion?,
      );
      return estado == 'esperando_pago';
    }).toList();

    final perfilesSuspendidos = todosPerfiles.where((p) {
      final estado = _obtenerEstadoPerfil(
        p['perfil'] as Perfil,
        p['suscripcion'] as Suscripcion?,
      );
      return estado == 'suspendida';
    }).toList();

    final perfilesSinCliente = todosPerfiles.where((p) {
      final estado = _obtenerEstadoPerfil(
        p['perfil'] as Perfil,
        p['suscripcion'] as Suscripcion?,
      );
      return estado == 'sin_cliente';
    }).toList();

    final perfilesActivos = todosPerfiles.where((p) {
      final estado = _obtenerEstadoPerfil(
        p['perfil'] as Perfil,
        p['suscripcion'] as Suscripcion?,
      );
      return estado == 'activa';
    }).toList();

    final perfilesDisponibles = todosPerfiles.where((p) {
      final estado = _obtenerEstadoPerfil(
        p['perfil'] as Perfil,
        p['suscripcion'] as Suscripcion?,
      );
      return estado == 'disponible';
    }).toList();

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: true,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorPlataforma, colorPlataforma.withOpacity(0.7)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildLogo(plataforma),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        plataforma.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text(
                        '${perfilesEnEspera.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCredencialRow(
                  Icons.email,
                  'Email',
                  cuenta.email,
                  context,
                ),
                const SizedBox(height: 8),
                _buildCredencialRow(
                  Icons.lock,
                  'Contraseña',
                  cuenta.password,
                  context,
                  oscurable: true,
                ),
              ],
            ),
          ),
          children: [
            if (perfilesEnEspera.isNotEmpty) ...[
              _buildSeccionHeader(
                '⚠️ REQUIEREN ATENCIÓN (${perfilesEnEspera.length})',
                Colors.orange,
              ),
              ...perfilesEnEspera.map((perfilInfo) {
                return _buildPerfilItem(
                  perfilInfo['perfil'] as Perfil,
                  perfilInfo['suscripcion'] as Suscripcion,
                  perfilInfo['cliente'] as Cliente?,
                  'esperando_pago',
                );
              }),
            ],
            if (perfilesSuspendidos.isNotEmpty) ...[
              _buildSeccionHeader(
                '⏸️ SUSPENDIDOS (${perfilesSuspendidos.length})',
                Colors.purple,
              ),
              ...perfilesSuspendidos.map((perfilInfo) {
                return _buildPerfilItem(
                  perfilInfo['perfil'] as Perfil,
                  perfilInfo['suscripcion'] as Suscripcion,
                  perfilInfo['cliente'] as Cliente?,
                  'suspendida',
                );
              }),
            ],
            if (perfilesSinCliente.isNotEmpty) ...[
              _buildSeccionHeader(
                '🔒 SIN CLIENTE (${perfilesSinCliente.length})',
                Colors.orange[700]!,
              ),
              ...perfilesSinCliente.map((perfilInfo) {
                return _buildPerfilItem(
                  perfilInfo['perfil'] as Perfil,
                  perfilInfo['suscripcion'] as Suscripcion,
                  null,
                  'sin_cliente',
                );
              }),
            ],
            if (perfilesActivos.isNotEmpty) ...[
              _buildSeccionHeader(
                '✅ ACTIVOS (${perfilesActivos.length})',
                Colors.green,
              ),
              ...perfilesActivos.map((perfilInfo) {
                return _buildPerfilItem(
                  perfilInfo['perfil'] as Perfil,
                  perfilInfo['suscripcion'] as Suscripcion,
                  perfilInfo['cliente'] as Cliente?,
                  'activa',
                );
              }),
            ],
            if (perfilesDisponibles.isNotEmpty) ...[
              _buildSeccionHeader(
                '🟢 DISPONIBLES (${perfilesDisponibles.length})',
                Colors.grey,
              ),
              ...perfilesDisponibles.map((perfilInfo) {
                return _buildPerfilItem(
                  perfilInfo['perfil'] as Perfil,
                  null,
                  null,
                  'disponible',
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCredencialRow(
    IconData icono,
    String label,
    String valor,
    BuildContext context, {
    bool oscurable = false,
  }) {
    return _CredencialRowStateful(
      icono: icono,
      label: label,
      valor: valor,
      oscurable: oscurable,
    );
  }

  Widget _buildSuscripcionEsperaItem(Suscripcion suscripcion) {
    final cliente = _clientes.firstWhere((c) => c.id == suscripcion.clienteId);
    final perfil = _perfiles.firstWhere((p) => p.id == suscripcion.perfilId);
    final plataforma = _plataformas.firstWhere(
      (p) => p.id == suscripcion.plataformaId,
    );

    final diasRestantes = _diasRestantes(suscripcion.fechaProximoPago);
    Color colorDias;
    if (diasRestantes < 0) {
      colorDias = Colors.red[900]!;
    } else if (diasRestantes == 0) {
      colorDias = Colors.red;
    } else if (diasRestantes == 1) {
      colorDias = Colors.orange;
    } else {
      colorDias = Colors.blue;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cliente y perfil
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  //agregamos tambien el numero de telefono del cliente y la opcion de copiar
                  child: Text(
                    "${cliente.nombreCompleto} - ${cliente.telefono}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                //aqui copia el numero de celular
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: cliente.telefono));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Número celular copiado')),
                    );
                  },
                  icon: Icon(Icons.copy),
                ),

                //permitir copiar el numero de celular
                Text(
                  perfil.nombrePerfil,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Información de pago
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.attach_money,
                    'L ${suscripcion.precio.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.calendar_month,
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(suscripcion.fechaProximoPago),
                    colorDias,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _suspenderSuscripcion(suscripcion),
                  icon: const Icon(Icons.pause_circle, size: 16),
                  label: const Text(
                    'Suspender',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () =>
                      _renovarSuscripcion(suscripcion, cliente, plataforma),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Renovar', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _cancelarSuscripcion(suscripcion, cliente),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSuspendidas() {
    if (_suscripcionesSuspendidas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay suscripciones suspendidas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Agrupar por cuenta
    final agrupadas = _agruparPorCuenta(_suscripcionesSuspendidas);

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: agrupadas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final cuentaId = agrupadas.keys.elementAt(index);
          final suscripciones = agrupadas[cuentaId]!;
          final cuenta = _cuentas.firstWhere((c) => c.id == cuentaId);
          final plataforma = _plataformas.firstWhere(
            (p) => p.id == cuenta.plataformaId,
          );

          return _buildCuentaSuspendidaCard(cuenta, plataforma, suscripciones);
        },
      ),
    );
  }

  Widget _buildCuentaSuspendidaCard(
    CuentaCorreo cuenta,
    Plataforma plataforma,
    List<Suscripcion> suscripciones,
  ) {
    //final colorPlataforma = Color(
    //  int.parse(plataforma.color.replaceFirst('#', '0xFF')),
    //);

    return Card(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.purple.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildLogo(plataforma),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        plataforma.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Text(
                        '${suscripciones.length} suspendidas',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Alerta si todos están inactivos
                FutureBuilder<bool>(
                  future: _supabaseService.todosPerfilesInactivos(cuenta.id),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    '⚠️ ATENCIÓN: Todos los perfiles están inactivos',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Es seguro cambiar las credenciales de esta cuenta',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () {
                                // TODO: Abrir diálogo para cambiar credenciales
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Función de cambiar credenciales próximamente',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Cambiar Credenciales'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const Divider(color: Colors.white30, height: 1),
                const SizedBox(height: 16),

                // Credenciales
                _buildCredencialRow(
                  Icons.email,
                  'Email',
                  cuenta.email,
                  context,
                ),
                const SizedBox(height: 12),
                _buildCredencialRow(
                  Icons.lock,
                  'Contraseña',
                  cuenta.password,
                  context,
                  oscurable: true,
                ),
              ],
            ),
          ),

          // Lista de suscripciones suspendidas
          ...suscripciones.map((suscripcion) {
            return _buildSuscripcionSuspendidaItem(suscripcion);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSuscripcionSuspendidaItem(Suscripcion suscripcion) {
    final cliente = _clientes.firstWhere((c) => c.id == suscripcion.clienteId);
    final perfil = _perfiles.firstWhere((p) => p.id == suscripcion.perfilId);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cliente y perfil
            Row(
              children: [
                const Icon(Icons.pause_circle, size: 16, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cliente.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  perfil.nombrePerfil,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.attach_money,
                    'L ${suscripcion.precio.toStringAsFixed(2)}',
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.pause_circle,
                    'Suspendida',
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _reactivarSuscripcion(suscripcion),
                  icon: const Icon(Icons.play_circle_filled, size: 18),
                  label: const Text('Reactivar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _cancelarSuscripcion(suscripcion, cliente),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancelar Definitivo'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _suspenderSuscripcion(Suscripcion suscripcion) async {
    final cliente = _clientes.firstWhere((c) => c.id == suscripcion.clienteId);
    final plataforma = _plataformas.firstWhere(
      (p) => p.id == suscripcion.plataformaId,
    );
    final perfil = _perfiles.firstWhere((p) => p.id == suscripcion.perfilId);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SuspenderSuscripcionDialog(
        suscripcion: suscripcion,
        cliente: cliente,
        plataforma: plataforma,
        perfil: perfil,
      ),
    );

    if (result == true) {
      _cargarDatos();
    }
  }

  Future<void> _reactivarSuscripcion(Suscripcion suscripcion) async {
    final cliente = _clientes.firstWhere((c) => c.id == suscripcion.clienteId);
    final plataforma = _plataformas.firstWhere(
      (p) => p.id == suscripcion.plataformaId,
    );
    final perfil = _perfiles.firstWhere((p) => p.id == suscripcion.perfilId);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReactivarSuscripcionDialog(
        suscripcion: suscripcion,
        cliente: cliente,
        plataforma: plataforma,
        perfil: perfil,
      ),
    );

    if (result == true) {
      _cargarDatos();
    }
  }

  Widget _buildInfoChip(IconData icono, String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuscripcionEsperaCard(Suscripcion suscripcion) {
    final cliente = _clientes.firstWhere((c) => c.id == suscripcion.clienteId);
    final plataforma = _plataformas.firstWhere(
      (p) => p.id == suscripcion.plataformaId,
    );
    final perfil = _perfiles.firstWhere((p) => p.id == suscripcion.perfilId);
    final cuenta = _cuentas.firstWhere((c) => c.id == perfil.cuentaId);

    final colorPlataforma = Color(
      int.parse(plataforma.color.replaceFirst('#', '0xFF')),
    );

    final diasEspera = _diasRestantes(suscripcion.fechaProximoPago);
    final diasTexto = diasEspera == 0
        ? 'Vence hoy'
        : diasEspera == 1
        ? 'Vencida hace 1 día'
        : 'Vencida hace $diasEspera días';

    final colorDias = diasEspera == 0
        ? Colors.orange
        : diasEspera <= 3
        ? Colors.red
        : Colors.red[900]!;

    return Card(
      child: Column(
        children: [
          // Header con plataforma
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
                        cliente.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 14,
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
                    color: colorDias.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorDias),
                  ),
                  child: Text(
                    diasTexto,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorDias,
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
                // Info del cliente
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cliente.telefono,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        size: 16,
                        color: Colors.blue,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // Detalles de suscripción
                _buildInfoRow(
                  'Cuenta',
                  cuenta.email,
                  Icons.email,
                  copiable: true,
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Perfil', perfil.nombrePerfil, Icons.person),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Precio',
                  'L ${suscripcion.precio.toStringAsFixed(2)}',
                  Icons.attach_money,
                  valueColor: Colors.green,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Vencimiento',
                  DateFormat('dd/MM/yyyy').format(suscripcion.fechaProximoPago),
                  Icons.event,
                  valueColor: colorDias,
                ),

                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _cancelarSuscripcion(suscripcion, cliente),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => _renovarSuscripcion(
                          suscripcion,
                          cliente,
                          plataforma,
                        ),
                        icon: const Icon(Icons.autorenew, size: 18),
                        label: const Text('Renovar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorPlataforma,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
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

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool copiable = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (copiable)
          IconButton(
            icon: const Icon(Icons.copy, size: 14, color: Colors.blue),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copiado'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
      ],
    );
  }
  // ============================================
  // PARTE 3/6: MÉTODOS HELPERS NUEVOS
  // UBICACIÓN: Agregar DESPUÉS del método _agruparPorCuenta (línea ~137)
  // O si prefieres, agregar antes de _buildCuentaEsperaCard
  // ============================================

  // Obtener TODOS los perfiles de una cuenta con su información completa
  List<Map<String, dynamic>> _obtenerTodosPerfilesDeCuenta(String cuentaId) {
    final perfilesCuenta = _perfiles
        .where((p) => p.cuentaId == cuentaId)
        .toList();

    final perfilesConInfo = <Map<String, dynamic>>[];

    for (final perfil in perfilesCuenta) {
      Suscripcion? suscripcion;
      Cliente? cliente;

      try {
        suscripcion = _suscripciones.firstWhere(
          (s) => s.perfilId == perfil.id && s.estado != 'cancelada',
        );

        if (suscripcion.clienteId != CLIENTE_SIN_ASIGNAR) {
          cliente = _clientes.firstWhere(
            (c) => c.id == suscripcion!.clienteId,
            orElse: () => Cliente(
              id: '',
              nombreCompleto: '',
              telefono: '',
              estado: '',
              fechaRegistro: DateTime.now(),
            ),
          );
          if (cliente.id.isEmpty) cliente = null;
        }
      } catch (e) {
        // No tiene suscripción activa
      }

      perfilesConInfo.add({
        'perfil': perfil,
        'suscripcion': suscripcion,
        'cliente': cliente,
      });
    }

    return perfilesConInfo;
  }

  // Determinar el estado visual de un perfil
  String _obtenerEstadoPerfil(Perfil perfil, Suscripcion? suscripcion) {
    if (suscripcion == null) {
      return 'disponible';
    }

    if (suscripcion.clienteId == CLIENTE_SIN_ASIGNAR) {
      return 'sin_cliente';
    }

    return suscripcion.estado;
  }

  // Widget para headers de sección
  Widget _buildSeccionHeader(String titulo, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.3))),
      ),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Obtener ícono por estado
  IconData _getIconoPorEstado(String estado) {
    switch (estado) {
      case 'esperando_pago':
        return Icons.warning;
      case 'suspendida':
        return Icons.pause_circle;
      case 'sin_cliente':
        return Icons.lock;
      case 'activa':
        return Icons.check_circle;
      case 'disponible':
        return Icons.radio_button_unchecked;
      default:
        return Icons.help;
    }
  }

  // Obtener color por estado
  Color _getColorPorEstado(String estado) {
    switch (estado) {
      case 'esperando_pago':
        return Colors.orange;
      case 'suspendida':
        return Colors.purple;
      case 'sin_cliente':
        return Colors.orange[700]!;
      case 'activa':
        return Colors.green;
      case 'disponible':
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  // ============================================
  // PARTE 4/6: MÉTODO _buildPerfilItem Y SUS HELPERS
  // UBICACIÓN: Agregar DESPUÉS de los helpers de la Parte 3
  // ============================================

  Widget _buildPerfilItem(
    Perfil perfil,
    Suscripcion? suscripcion,
    Cliente? cliente,
    String estadoVisual,
  ) {
    final plataforma = _plataformas.firstWhere(
      (p) =>
          p.id ==
          (suscripcion?.plataformaId ??
              _cuentas.firstWhere((c) => c.id == perfil.cuentaId).plataformaId),
    );

    int? diasRestantes;
    Color? colorDias;
    if (suscripcion != null) {
      diasRestantes = _diasRestantes(suscripcion.fechaProximoPago);
      if (diasRestantes < 0) {
        colorDias = Colors.red[900]!;
      } else if (diasRestantes == 0) {
        colorDias = Colors.red;
      } else if (diasRestantes == 1) {
        colorDias = Colors.orange;
      } else {
        colorDias = Colors.blue;
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconoPorEstado(estadoVisual),
                  size: 16,
                  color: _getColorPorEstado(estadoVisual),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cliente != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${cliente.nombreCompleto} - ${cliente.telefono}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
                              icon: const Icon(Icons.copy, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        perfil.nombrePerfil,
                        style: TextStyle(
                          fontSize: 14,
                          color: cliente != null
                              ? Colors.grey[400]
                              : Colors.white,
                          fontWeight: cliente != null
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (suscripcion != null)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.attach_money,
                      'L ${suscripcion.precio.toStringAsFixed(2)}',
                      Colors.green,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _getChipEstado(
                    estadoVisual,
                    suscripcion,
                    colorDias,
                    diasRestantes,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _getBotonesPorEstado(
              estadoVisual,
              suscripcion,
              perfil,
              cliente!,
              plataforma,
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Obtener chip de estado
  Widget _getChipEstado(
    String estadoVisual,
    Suscripcion? suscripcion,
    Color? colorDias,
    int? diasRestantes,
  ) {
    if (estadoVisual == 'disponible') {
      return _buildInfoChip(Icons.check_circle, 'Disponible', Colors.grey);
    }

    if (estadoVisual == 'sin_cliente') {
      return _buildInfoChip(Icons.lock, 'Sin Cliente', Colors.orange[700]!);
    }

    if (estadoVisual == 'suspendida') {
      return _buildInfoChip(Icons.pause_circle, 'Suspendida', Colors.purple);
    }

    if (estadoVisual == 'activa' && suscripcion != null) {
      return _buildInfoChip(
        Icons.check_circle,
        'Al día - ${DateFormat('dd/MM').format(suscripcion.fechaProximoPago)}',
        Colors.green,
      );
    }

    if (suscripcion != null && colorDias != null && diasRestantes != null) {
      String textoFecha;
      if (diasRestantes < 0) {
        textoFecha = 'Vencida hace ${diasRestantes.abs()} día(s)';
      } else if (diasRestantes == 0) {
        textoFecha = 'Vence HOY';
      } else if (diasRestantes == 1) {
        textoFecha = 'Vence MAÑANA';
      } else {
        textoFecha = DateFormat(
          'dd/MM/yyyy',
        ).format(suscripcion.fechaProximoPago);
      }

      return _buildInfoChip(Icons.calendar_today, textoFecha, colorDias);
    }

    return const SizedBox();
  }

  // Helper: Obtener botones según estado
  Widget _getBotonesPorEstado(
    String estadoVisual,
    Suscripcion? suscripcion,
    Perfil perfil,
    Cliente cliente,
    Plataforma plataforma,
  ) {
    if (estadoVisual == 'esperando_pago' && suscripcion != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: IconButton(
              onPressed: () => _suspenderSuscripcion(suscripcion),
              icon: const Icon(Icons.pause_circle, size: 20),
              color: Colors.orange,
              tooltip: 'Suspender',
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: IconButton(
              onPressed: () =>
                  _renovarSuscripcion(suscripcion, cliente, plataforma),
              icon: const Icon(Icons.refresh, size: 20),
              color: Colors.green,
              tooltip: 'Renovar',
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: IconButton(
              onPressed: () => _cancelarSuscripcion(suscripcion, cliente),
              icon: const Icon(Icons.cancel, size: 20),
              color: Colors.red,
              tooltip: 'Cancelar',
            ),
          ),
        ],
      );
    }

    if (estadoVisual == 'suspendida' && suscripcion != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: TextButton.icon(
              onPressed: () => _reactivarSuscripcion(suscripcion),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Reactivar', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: TextButton.icon(
              onPressed: () => _cancelarSuscripcion(suscripcion, cliente),
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Cancelar', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      );
    }

    if (estadoVisual == 'sin_cliente') {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          //boton por definir
          onPressed: () {},
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text('Asignar Cliente', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(foregroundColor: Colors.green),
        ),
      );
    }

    return const SizedBox();
  }

  Future<void> _renovarSuscripcion(
    Suscripcion suscripcion,
    Cliente cliente,
    Plataforma plataforma,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => RenovarSuscripcionDialog(
        suscripcion: suscripcion,
        cliente: cliente,
        plataforma: plataforma,
        onRenovada: _cargarDatos,
      ),
    );
  }

  Future<void> _cancelarSuscripcion(
    Suscripcion suscripcion,
    Cliente cliente,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Suscripción'),
        content: Text(
          '¿Estás seguro de cancelar la suscripción de ${cliente.nombreCompleto}?\n\n'
          'Esta acción:\n'
          '• Liberará el perfil\n'
          '• Eliminará las alertas\n'
          '• Marcará la suscripción como cancelada\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, mantener'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _supabaseService.cancelarSuscripcion(suscripcion.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Suscripción cancelada'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarDatos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ==================== HELPERS ====================

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
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) =>
              const FaIcon(FontAwesomeIcons.tv, size: 20, color: Colors.grey),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const FaIcon(FontAwesomeIcons.tv, size: 20, color: Colors.grey),
    );
  }
}

// Al final del archivo, antes del último }
class _CredencialRowStateful extends StatefulWidget {
  final IconData icono;
  final String label;
  final String valor;
  final bool oscurable;

  const _CredencialRowStateful({
    required this.icono,
    required this.label,
    required this.valor,
    this.oscurable = false,
  });

  @override
  State<_CredencialRowStateful> createState() => _CredencialRowStatefulState();
}

class _CredencialRowStatefulState extends State<_CredencialRowStateful> {
  bool _mostrar = false;

  @override
  Widget build(BuildContext context) {
    final valorMostrar = widget.oscurable && !_mostrar
        ? '•' * widget.valor.length
        : widget.valor;

    return Row(
      children: [
        Icon(widget.icono, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          '${widget.label}: ',
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        Expanded(
          child: Text(
            valorMostrar,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (widget.oscurable)
          IconButton(
            icon: Icon(
              _mostrar ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: Colors.white70,
            ),
            onPressed: () => setState(() => _mostrar = !_mostrar),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
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
    );
  }
}
