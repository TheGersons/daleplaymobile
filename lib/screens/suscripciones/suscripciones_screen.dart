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

class SuscripcionesScreen extends StatefulWidget {
  const SuscripcionesScreen({super.key});

  @override
  State<SuscripcionesScreen> createState() => _SuscripcionesScreenState();
}

class _SuscripcionesScreenState extends State<SuscripcionesScreen> {
  final _supabaseService = SupabaseService();

  List<Suscripcion> _suscripciones = [];
  List<Suscripcion> _suscripcionesFiltradas = [];
  List<Cliente> _clientes = [];
  List<Plataforma> _plataformas = [];
  List<Perfil> _perfiles = [];
  List<CuentaCorreo> _cuentas = [];

  bool _isLoading = true;

  // Filtros básicos
  final _searchController = TextEditingController();
  String _filtroPlataforma = 'todas';
  String _filtroEstado = 'todos';

  // Filtros avanzados
  String _ordenarPor = 'fecha_proximo_pago';
  bool _ordenDescendente = false;
  bool? _proximosAVencer; // true = próximos 7 días, false = todos

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final suscripciones = await _supabaseService.obtenerSuscripciones();
      final clientes = await _supabaseService.obtenerClientes();
      final plataformas = await _supabaseService.obtenerPlataformas();
      final perfiles = await _supabaseService.obtenerPerfiles();
      final cuentas = await _supabaseService.obtenerCuentas();

      setState(() {
        _suscripciones = suscripciones;
        _clientes = clientes;
        _plataformas = plataformas;
        _perfiles = perfiles;
        _cuentas = cuentas;
        _aplicarFiltros();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar suscripciones: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _aplicarFiltros() {
    var filtradas = _suscripciones;

    // Búsqueda por texto
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtradas = filtradas.where((s) {
        final cliente = _clientes.firstWhere(
          (c) => c.id == s.clienteId,
          orElse: () => Cliente(
            id: '',
            nombreCompleto: '',
            telefono: '',
            estado: '',
            fechaRegistro: DateTime.now(),
          ),
        );
        final plataforma = _plataformas.firstWhere(
          (p) => p.id == s.plataformaId,
          orElse: () => Plataforma(
            id: '',
            nombre: '',
            icono: '',
            precioBase: 0,
            maxPerfiles: 0,
            color: '',
            estado: '',
            fechaCreacion: DateTime.now(),
          ),
        );

        return cliente.nombreCompleto.toLowerCase().contains(query) ||
            plataforma.nombre.toLowerCase().contains(query) || 
            cliente.telefono.toLowerCase().contains(query);
      }).toList();
    }

    // Filtro por plataforma
    if (_filtroPlataforma != 'todas') {
      filtradas = filtradas
          .where((s) => s.plataformaId == _filtroPlataforma)
          .toList();
    }

    // Filtro por estado
    if (_filtroEstado != 'todos') {
      filtradas = filtradas.where((s) => s.estado == _filtroEstado).toList();
    }

    // Filtro próximos a vencer
    if (_proximosAVencer == true) {
      final hoy = DateTime.now();
      filtradas = filtradas.where((s) {
        final diasRestantes = s.fechaProximoPago.difference(hoy).inDays;
        return diasRestantes >= 0 && diasRestantes <= 7 && s.estado == 'activa';
      }).toList();
    }

    // Ordenamiento
    filtradas.sort((a, b) {
      int comparison = 0;

      switch (_ordenarPor) {
        case 'cliente':
          final clienteA = _clientes
              .firstWhere((c) => c.id == a.clienteId)
              .nombreCompleto;
          final clienteB = _clientes
              .firstWhere((c) => c.id == b.clienteId)
              .nombreCompleto;
          comparison = clienteA.compareTo(clienteB);
          break;
        case 'plataforma':
          final plataformaA = _plataformas
              .firstWhere((p) => p.id == a.plataformaId)
              .nombre;
          final plataformaB = _plataformas
              .firstWhere((p) => p.id == b.plataformaId)
              .nombre;
          comparison = plataformaA.compareTo(plataformaB);
          break;
        case 'fecha_inicio':
          comparison = a.fechaInicio.compareTo(b.fechaInicio);
          break;
        case 'fecha_proximo_pago':
          comparison = a.fechaProximoPago.compareTo(b.fechaProximoPago);
          break;
        case 'precio':
          comparison = a.precio.compareTo(b.precio);
          break;
      }

      return _ordenDescendente ? -comparison : comparison;
    });

    setState(() => _suscripcionesFiltradas = filtradas);
  }

  void _limpiarFiltrosAvanzados() {
    setState(() {
      _ordenarPor = 'fecha_proximo_pago';
      _ordenDescendente = false;
      _proximosAVencer = null;
      _aplicarFiltros();
    });
  }

  bool get _tieneFiltrosAvanzados =>
      _ordenarPor != 'fecha_proximo_pago' ||
      _ordenDescendente != false ||
      _proximosAVencer != null;

  void _mostrarFiltrosAvanzados() {
    showDialog(
      context: context,
      builder: (context) => FiltrosAvanzadosDialog(
        ordenarPor: _ordenarPor,
        ordenDescendente: _ordenDescendente,
        proximosAVencer: _proximosAVencer,
        onAplicar: (ordenar, descendente, proximos) {
          setState(() {
            _ordenarPor = ordenar;
            _ordenDescendente = descendente;
            _proximosAVencer = proximos;
            _aplicarFiltros();
          });
        },
      ),
    );
  }

  void _mostrarDialogoSuscripcion([Suscripcion? suscripcion]) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => SuscripcionDialog(
        suscripcion: suscripcion,
        clientes: _clientes,
        plataformas: _plataformas,
        cuentas: _cuentas,
        perfiles: _perfiles,
      ),
    );

    if (resultado == true) {
      _cargarDatos();
    }
  }

  void _mostrarDetalleSuscripcion(Suscripcion suscripcion) {
    showDialog(
      context: context,
      builder: (context) => SuscripcionDetalleDialog(
        suscripcion: suscripcion,
        cliente: _clientes.firstWhere((c) => c.id == suscripcion.clienteId),
        plataforma: _plataformas.firstWhere(
          (p) => p.id == suscripcion.plataformaId,
        ),
        perfil: _perfiles.firstWhere((p) => p.id == suscripcion.perfilId),
        cuenta: _cuentas.firstWhere(
          (c) =>
              c.id ==
              _perfiles
                  .firstWhere((p) => p.id == suscripcion.perfilId)
                  .cuentaId,
        ),
      ),
    );
  }

  Future<void> _eliminarSuscripcion(Suscripcion suscripcion) async {
    final cliente = _clientes.firstWhere((c) => c.id == suscripcion.clienteId);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Suscripción'),
        content: Text(
          '¿Estás seguro de eliminar la suscripción de "${cliente.nombreCompleto}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _supabaseService.eliminarSuscripcion(suscripcion.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Suscripción eliminada')),
          );
          _cargarDatos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Búsqueda + filtros avanzados
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.black),
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por cliente o plataforma...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _aplicarFiltros();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => _aplicarFiltros(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Badge(
                      label: Text(_tieneFiltrosAvanzados ? '!' : ''),
                      isLabelVisible: _tieneFiltrosAvanzados,
                      child: IconButton.filledTonal(
                        onPressed: _mostrarFiltrosAvanzados,
                        icon: const Icon(Icons.filter_list),
                        tooltip: 'Filtros avanzados',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filtros básicos
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _filtroPlataforma,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Plataforma',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'todas',
                            child: Text('Todas'),
                          ),
                          ..._plataformas.map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _filtroPlataforma = v!;
                            _aplicarFiltros();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _filtroEstado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'todos',
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: 'activa',
                            child: Text('Activas'),
                          ),
                          DropdownMenuItem(
                            value: 'vencida',
                            child: Text('Vencidas'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelada',
                            child: Text('Canceladas'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _filtroEstado = v!;
                            _aplicarFiltros();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_tieneFiltrosAvanzados)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: const Text('Filtros avanzados aplicados'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: _limpiarFiltrosAvanzados,
                    ),
                  ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suscripcionesFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.subscriptions_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _suscripciones.isEmpty
                              ? 'No hay suscripciones registradas'
                              : 'No se encontraron suscripciones',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _suscripciones.isEmpty
                              ? 'Agrega tu primera suscripción'
                              : 'Intenta con otros filtros',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _suscripcionesFiltradas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final suscripcion = _suscripcionesFiltradas[index];
                        final cliente = _clientes.firstWhere(
                          (c) => c.id == suscripcion.clienteId,
                        );
                        final plataforma = _plataformas.firstWhere(
                          (p) => p.id == suscripcion.plataformaId,
                        );
                        //controlamos la excepcion que no hay elementos

                        final perfil = _perfiles.firstWhere(
                        
                          (p) => p.id == suscripcion.perfilId,
                        );

                        return _SuscripcionCard(
                          suscripcion: suscripcion,
                          cliente: cliente,
                          plataforma: plataforma,
                          perfil: perfil,
                          onTap: () => _mostrarDetalleSuscripcion(suscripcion),
                          onEdit: () => _mostrarDialogoSuscripcion(suscripcion),
                          onDelete: () => _eliminarSuscripcion(suscripcion),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoSuscripcion(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Suscripción'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ==================== CARD ====================

class _SuscripcionCard extends StatelessWidget {
  final Suscripcion suscripcion;
  final Cliente cliente;
  final Plataforma plataforma;
  final Perfil perfil;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SuscripcionCard({
    required this.suscripcion,
    required this.cliente,
    required this.plataforma,
    required this.perfil,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final diasRestantes = suscripcion.fechaProximoPago
        .difference(DateTime.now())
        .inDays;

    Color estadoColor;
    Color diasColor;
    String diasTexto;

    // Color de estado
    switch (suscripcion.estado) {
      case 'activa':
        estadoColor = Colors.green;
        break;
      case 'vencida':
        estadoColor = Colors.red;
        break;
      case 'cancelada':
        estadoColor = Colors.grey;
        break;
      default:
        estadoColor = Colors.blue;
    }

    // Días restantes
    if (diasRestantes < 0) {
      diasTexto = 'Vencido hace ${diasRestantes.abs()} días';
      diasColor = Colors.red;
    } else if (diasRestantes == 0) {
      diasTexto = 'Vence hoy';
      diasColor = Colors.orange;
    } else if (diasRestantes <= 3) {
      diasTexto = 'En $diasRestantes días';
      diasColor = Colors.amber;
    } else {
      diasTexto = 'En $diasRestantes días';
      diasColor = Colors.green;
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(
                  int.parse(plataforma.color.replaceFirst('#', '0xFF')),
                ).withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Color(
                      int.parse(plataforma.color.replaceFirst('#', '0xFF')),
                    ),
                    width: 2,
                  ),
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
                          cliente.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${plataforma.nombre} • ${perfil.nombrePerfil}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
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
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: estadoColor),
                    ),
                    child: Text(
                      suscripcion.estado.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color.lerp(estadoColor, Colors.black, 0.3)!,
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
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Costo Mensual',
                          'L ${suscripcion.precio.toStringAsFixed(2)}',
                          Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          'Próximo Pago',
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(suscripcion.fechaProximoPago),
                          Icons.calendar_today,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: diasColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: diasColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: diasColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          diasTexto,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.lerp(diasColor, Colors.black, 0.3)!,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (suscripcion.estado == 'activa')
                        TextButton.icon(
                          onPressed: () async {
                            // Renovar suscripción
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Renovar Suscripción'),
                                content: Text(
                                  '¿Renovar la suscripción para el ${DateFormat('dd/MM/yyyy').format(DateTime(suscripcion.fechaProximoPago.year, suscripcion.fechaProximoPago.month + 1, suscripcion.fechaProximoPago.day))}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Renovar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmar == true) {
                              try {
                                final nuevaFecha = DateTime(
                                  suscripcion.fechaProximoPago.year,
                                  suscripcion.fechaProximoPago.month + 1,
                                  suscripcion.fechaProximoPago.day,
                                );

                                final suscripcionActualizada = Suscripcion(
                                  id: suscripcion.id,
                                  clienteId: suscripcion.clienteId,
                                  perfilId: suscripcion.perfilId,
                                  plataformaId: suscripcion.plataformaId,
                                  tipoSuscripcion: suscripcion.tipoSuscripcion,
                                  precio: suscripcion.precio,
                                  fechaInicio: suscripcion.fechaInicio,
                                  fechaProximoPago: nuevaFecha,
                                  fechaLimitePago: nuevaFecha,
                                  estado: 'activa',
                                  fechaCreacion: suscripcion.fechaCreacion,
                                  notas: suscripcion.notas,
                                );

                                await SupabaseService().actualizarSuscripcion(
                                  suscripcionActualizada,
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Suscripción renovada'),
                                    ),
                                  );
                                  // Forzar recarga de la lista
                                  (context
                                          .findAncestorStateOfType<
                                            _SuscripcionesScreenState
                                          >())
                                      ?._cargarDatos();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Renovar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
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
      decoration: BoxDecoration(
        color: Color(int.parse(plataforma.color.replaceFirst('#', '0xFF'))),
        shape: BoxShape.circle,
      ),
      child: const FaIcon(FontAwesomeIcons.tv, size: 20, color: Colors.white),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ==================== FILTROS AVANZADOS DIALOG ====================

class FiltrosAvanzadosDialog extends StatefulWidget {
  final String ordenarPor;
  final bool ordenDescendente;
  final bool? proximosAVencer;
  final Function(String, bool, bool?) onAplicar;

  const FiltrosAvanzadosDialog({
    super.key,
    required this.ordenarPor,
    required this.ordenDescendente,
    this.proximosAVencer,
    required this.onAplicar,
  });

  @override
  State<FiltrosAvanzadosDialog> createState() => _FiltrosAvanzadosDialogState();
}

class _FiltrosAvanzadosDialogState extends State<FiltrosAvanzadosDialog> {
  late String _ordenarPor;
  late bool _ordenDescendente;
  late String _proximosValue;

  @override
  void initState() {
    super.initState();
    _ordenarPor = widget.ordenarPor;
    _ordenDescendente = widget.ordenDescendente;
    _proximosValue = widget.proximosAVencer == null
        ? 'todos'
        : widget.proximosAVencer!
        ? 'proximos_7_dias'
        : 'todos';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtros y Ordenamiento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ordenar por',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _ordenarPor,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'fecha_proximo_pago',
                  child: Text('Próximo Pago'),
                ),
                DropdownMenuItem(
                  value: 'fecha_inicio',
                  child: Text('Fecha Inicio'),
                ),
                DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                DropdownMenuItem(
                  value: 'plataforma',
                  child: Text('Plataforma'),
                ),
                DropdownMenuItem(value: 'precio', child: Text('Precio')),
              ],
              onChanged: (v) => setState(() => _ordenarPor = v!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Orden descendente'),
              subtitle: Text(
                _ordenDescendente ? 'Mayor a menor' : 'Menor a mayor',
              ),
              value: _ordenDescendente,
              onChanged: (v) => setState(() => _ordenDescendente = v),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 24),
            const Text(
              'Vencimiento',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _proximosValue,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                DropdownMenuItem(
                  value: 'proximos_7_dias',
                  child: Text('Próximos 7 días'),
                ),
              ],
              onChanged: (v) => setState(() => _proximosValue = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onAplicar('fecha_proximo_pago', false, null);
            Navigator.pop(context);
          },
          child: const Text('Limpiar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            widget.onAplicar(
              _ordenarPor,
              _ordenDescendente,
              _proximosValue == 'proximos_7_dias' ? true : null,
            );
            Navigator.pop(context);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

// ==================== SUSCRIPCION DIALOG (CREAR/EDITAR) ====================

class SuscripcionDialog extends StatefulWidget {
  final Suscripcion? suscripcion;
  final List<Cliente> clientes;
  final List<Plataforma> plataformas;
  final List<CuentaCorreo> cuentas;
  final List<Perfil> perfiles;

  const SuscripcionDialog({
    super.key,
    this.suscripcion,
    required this.clientes,
    required this.plataformas,
    required this.cuentas,
    required this.perfiles,
  });

  @override
  State<SuscripcionDialog> createState() => _SuscripcionDialogState();
}

class _SuscripcionDialogState extends State<SuscripcionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  late TextEditingController _costoController;
  late TextEditingController _notasController;

  Cliente? _clienteSeleccionado;
  Plataforma? _plataformaSeleccionada;
  CuentaCorreo? _cuentaSeleccionada;
  Perfil? _perfilSeleccionado;

  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaProximoPago = DateTime.now().add(const Duration(days: 30));

  String _estadoSeleccionado = 'activa';
  bool _isLoading = false;
  bool _esEdicion = false;

  List<CuentaCorreo> _cuentasFiltradas = [];
  List<Perfil> _perfilesFiltrados = [];

  @override
  void initState() {
    super.initState();

    _esEdicion = widget.suscripcion != null;
    _costoController = TextEditingController();
    _notasController = TextEditingController();

    if (_esEdicion) {
      _cargarDatosEdicion();
    }
  }

  void _cargarDatosEdicion() {
    final s = widget.suscripcion!;

    _clienteSeleccionado = widget.clientes.firstWhere(
      (c) => c.id == s.clienteId,
    );
    _plataformaSeleccionada = widget.plataformas.firstWhere(
      (p) => p.id == s.plataformaId,
    );

    final perfil = widget.perfiles.firstWhere((p) => p.id == s.perfilId);
    _perfilSeleccionado = perfil;
    _cuentaSeleccionada = widget.cuentas.firstWhere(
      (c) => c.id == perfil.cuentaId,
    );

    _costoController.text = s.precio.toStringAsFixed(2);
    _fechaInicio = s.fechaInicio;
    _fechaProximoPago = s.fechaProximoPago;
    _estadoSeleccionado = s.estado;
    _notasController.text = s.notas ?? '';

    // Cargar cascadas
    _filtrarCuentas();
    _filtrarPerfiles();
  }

  @override
  void dispose() {
    _costoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _filtrarCuentas() {
    if (_plataformaSeleccionada != null) {
      setState(() {
        _cuentasFiltradas = widget.cuentas
            .where(
              (c) =>
                  c.plataformaId == _plataformaSeleccionada!.id &&
                  c.estado == 'activo',
            )
            .toList();
      });
    }
  }

  void _filtrarPerfiles() {
    if (_cuentaSeleccionada != null) {
      setState(() {
        _perfilesFiltrados = widget.perfiles.where((p) {
          if (p.cuentaId != _cuentaSeleccionada!.id) return false;

          // Si es edición, incluir el perfil actual aunque esté ocupado
          if (_esEdicion && p.id == widget.suscripcion!.perfilId) return true;

          // Solo perfiles disponibles
          return p.estado == 'disponible';
        }).toList();
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Validaciones de cascada
    if (_clienteSeleccionado == null) {
      _mostrarError('Selecciona un cliente');
      return;
    }
    if (_plataformaSeleccionada == null) {
      _mostrarError('Selecciona una plataforma');
      return;
    }
    if (_cuentaSeleccionada == null) {
      _mostrarError('Selecciona una cuenta');
      return;
    }
    if (_perfilSeleccionado == null) {
      _mostrarError('Selecciona un perfil disponible');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final suscripcion = Suscripcion(
        id: widget.suscripcion?.id ?? '',
        clienteId: _clienteSeleccionado!.id,
        perfilId: _perfilSeleccionado!.id,
        plataformaId: _plataformaSeleccionada!.id,
        tipoSuscripcion: 'perfil',
        precio: double.parse(_costoController.text),
        fechaInicio: _fechaInicio,
        fechaProximoPago: _fechaProximoPago,
        fechaLimitePago: _fechaProximoPago, // Igual que próximo pago
        estado: _estadoSeleccionado,
        fechaCreacion: widget.suscripcion?.fechaCreacion ?? DateTime.now(),
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
      );

      if (_esEdicion) {
        await _supabaseService.actualizarSuscripcion(suscripcion);
      } else {
        await _supabaseService.crearSuscripcion(suscripcion);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion ? 'Suscripción actualizada' : 'Suscripción creada',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.subscriptions,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _esEdicion ? 'Editar Suscripción' : 'Nueva Suscripción',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cliente
                      DropdownButtonFormField<Cliente>(
                        value: _clienteSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Cliente *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: widget.clientes
                            .where((c) => c.estado == 'activo')
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.nombreCompleto),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _clienteSeleccionado = v),
                      ),
                      const SizedBox(height: 16),

                      // Plataforma
                      DropdownButtonFormField<Plataforma>(
                        value: _plataformaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Plataforma *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tv),
                        ),
                        items: widget.plataformas
                            .where((p) => p.estado == 'activa')
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoading
                            ? null
                            : (v) {
                                setState(() {
                                  _plataformaSeleccionada = v;
                                  _cuentaSeleccionada = null;
                                  _perfilSeleccionado = null;
                                  _filtrarCuentas();
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      // Cuenta
                      DropdownButtonFormField<CuentaCorreo>(
                        value: _cuentaSeleccionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Cuenta *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        items: _cuentasFiltradas
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c.email,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    if (c.estado != 'activo')
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          '(${c.estado})',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoading || _cuentasFiltradas.isEmpty
                            ? null
                            : (v) {
                                setState(() {
                                  _cuentaSeleccionada = v;
                                  _perfilSeleccionado = null;
                                  _filtrarPerfiles();
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      // Perfil
                      DropdownButtonFormField<Perfil>(
                        value: _perfilSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Perfil *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_outline),
                          helperText: _perfilesFiltrados.isEmpty
                              ? 'No hay perfiles disponibles'
                              : null,
                        ),
                        items: _perfilesFiltrados
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text('${p.nombrePerfil} (${p.estado})'),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoading || _perfilesFiltrados.isEmpty
                            ? null
                            : (v) => setState(() => _perfilSeleccionado = v),
                      ),
                      const SizedBox(height: 16),

                      // Costo
                      TextFormField(
                        controller: _costoController,
                        decoration: const InputDecoration(
                          labelText: 'Costo Mensual *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: 'L ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Campo requerido';
                          if (double.tryParse(v!) == null)
                            return 'Número inválido';
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Fechas
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Fecha Inicio *',
                                style: TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy').format(_fechaInicio),
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _isLoading
                                  ? null
                                  : () async {
                                      final fecha = await showDatePicker(
                                        context: context,
                                        initialDate: _fechaInicio,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (fecha != null) {
                                        setState(() {
                                          _fechaInicio = fecha;
                                          // Auto-calcular próximo pago si no es edición
                                          if (!_esEdicion) {
                                            _fechaProximoPago = DateTime(
                                              fecha.year,
                                              fecha.month + 1,
                                              fecha.day,
                                            );
                                          }
                                        });
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Próximo Pago *',
                                style: TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_fechaProximoPago),
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _isLoading
                                  ? null
                                  : () async {
                                      final fecha = await showDatePicker(
                                        context: context,
                                        initialDate: _fechaProximoPago,
                                        firstDate: _fechaInicio,
                                        lastDate: DateTime(2030),
                                      );
                                      if (fecha != null) {
                                        setState(
                                          () => _fechaProximoPago = fecha,
                                        );
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Estado
                      DropdownButtonFormField<String>(
                        value: _estadoSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.toggle_on),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'activa',
                            child: Text('Activa'),
                          ),
                          DropdownMenuItem(
                            value: 'vencida',
                            child: Text('Vencida'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelada',
                            child: Text('Cancelada'),
                          ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _estadoSeleccionado = v!),
                      ),
                      const SizedBox(height: 16),

                      // Notas
                      TextFormField(
                        controller: _notasController,
                        decoration: const InputDecoration(
                          labelText: 'Notas',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _guardar,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
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

// ==================== SUSCRIPCION DETALLE DIALOG ====================

class SuscripcionDetalleDialog extends StatelessWidget {
  final Suscripcion suscripcion;
  final Cliente cliente;
  final Plataforma plataforma;
  final Perfil perfil;
  final CuentaCorreo cuenta;

  const SuscripcionDetalleDialog({
    super.key,
    required this.suscripcion,
    required this.cliente,
    required this.plataforma,
    required this.perfil,
    required this.cuenta,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSeccionInfo(),
                    const Divider(height: 32),
                    _buildSeccionPagos(context),
                    const Divider(height: 32),
                    _buildSeccionCliente(),
                    const Divider(height: 32),
                    _buildSeccionCredenciales(context),
                    if (suscripcion.notas?.isNotEmpty == true) ...[
                      const Divider(height: 32),
                      _buildSeccionNotas(),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    Color estadoColor;
    switch (suscripcion.estado) {
      case 'activa':
        estadoColor = Colors.green;
        break;
      case 'vencida':
        estadoColor = Colors.red;
        break;
      case 'cancelada':
        estadoColor = Colors.grey;
        break;
      default:
        estadoColor = Colors.blue;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse(plataforma.color.replaceFirst('#', '0xFF'))),
            Color(
              int.parse(plataforma.color.replaceFirst('#', '0xFF')),
            ).withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cliente.nombreCompleto,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${perfil.nombrePerfil} - ${plataforma.nombre}',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: estadoColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              suscripcion.estado.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de Suscripción',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Plataforma', plataforma.nombre, Icons.tv),
        _buildInfoRow('Perfil', perfil.nombrePerfil, Icons.person_outline),
        _buildInfoRow(
          'Costo Mensual',
          'L ${suscripcion.precio.toStringAsFixed(2)}',
          Icons.attach_money,
        ),
        _buildInfoRow(
          'Fecha Inicio',
          DateFormat('dd/MM/yyyy').format(suscripcion.fechaInicio),
          Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildSeccionPagos(BuildContext context) {
    final diasRestantes = suscripcion.fechaProximoPago
        .difference(DateTime.now())
        .inDays;
    final diasServicio = DateTime.now()
        .difference(suscripcion.fechaInicio)
        .inDays;

    Color diasColor;
    String diasTexto;

    if (diasRestantes < 0) {
      diasTexto = 'Vencido hace ${diasRestantes.abs()} días';
      diasColor = Colors.red;
    } else if (diasRestantes == 0) {
      diasTexto = 'Vence hoy';
      diasColor = Colors.orange;
    } else if (diasRestantes <= 3) {
      diasTexto = 'En $diasRestantes días';
      diasColor = Colors.amber;
    } else {
      diasTexto = 'En $diasRestantes días';
      diasColor = Colors.green;
    }

    String tiempoServicio;
    if (diasServicio < 30) {
      tiempoServicio = '$diasServicio días';
    } else if (diasServicio < 365) {
      final meses = diasServicio ~/ 30;
      tiempoServicio = '$meses ${meses == 1 ? 'mes' : 'meses'}';
    } else {
      final anios = diasServicio ~/ 365;
      final mesesRestantes = (diasServicio % 365) ~/ 30;
      tiempoServicio = mesesRestantes > 0
          ? '$anios ${anios == 1 ? 'año' : 'años'} y $mesesRestantes ${mesesRestantes == 1 ? 'mes' : 'meses'}'
          : '$anios ${anios == 1 ? 'año' : 'años'}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de Pagos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          'Próximo Pago',
          DateFormat('dd/MM/yyyy').format(suscripcion.fechaProximoPago),
          Icons.event,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: diasColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: diasColor),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: diasColor, size: 20),
              const SizedBox(width: 8),
              Text(
                diasTexto,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.lerp(diasColor, Colors.black, 0.3)!,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Tiempo de Servicio', tiempoServicio, Icons.history),
      ],
    );
  }

  Widget _buildSeccionCliente() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información del Cliente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Nombre', cliente.nombreCompleto, Icons.person),
        _buildInfoRow('Teléfono', cliente.telefono, Icons.phone),
      ],
    );
  }

  Widget _buildSeccionCredenciales(BuildContext context) {
    return _CredencialesSection(cuenta: cuenta);
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
          child: Text(suscripcion.notas!),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

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
                        color: Colors.black87, // AGREGA ESTO
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all<Color>(
                    Colors.blue,
                  ),
                ),
                onPressed: () => _copiar(widget.cuenta.email, 'Email'),
                tooltip: 'Copiar',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Contraseña
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
                        color: Colors.black87, // AGREGA ESTO
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all<Color>(
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
                  foregroundColor: MaterialStateProperty.all<Color>(
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
