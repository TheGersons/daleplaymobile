import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/pago.dart';
import '../../models/cliente.dart';
import '../../models/suscripcion.dart';
import '../../models/plataforma.dart';
import '../../services/supabase_service.dart';

class GestionPagosClientesScreen extends StatefulWidget {
  const GestionPagosClientesScreen({super.key});

  @override
  State<GestionPagosClientesScreen> createState() =>
      _GestionPagosClientesScreenState();
}

class _GestionPagosClientesScreenState
    extends State<GestionPagosClientesScreen> {
  final _supabaseService = SupabaseService();

  
  List<Cliente> _clientes = [];
  List<Suscripcion> _suscripciones = [];
  List<Suscripcion> _suscripcionesFiltradas = [];
  List<Plataforma> _plataformas = [];

  bool _isLoading = true;

  // Filtros básicos
  final _searchController = TextEditingController();
  String _filtroCliente = 'todos';
  String _filtroMetodoPago = 'todos';
  String _filtroPlataforma = 'todas';
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  // Filtros avanzados
  String _ordenarPor = 'fecha_pago';
  bool _ordenDescendente = true;


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
      final clientes = await _supabaseService.obtenerClientes();
      final suscripciones = await _supabaseService.obtenerSuscripciones();
      final plataformas = await _supabaseService.obtenerPlataformas();

      setState(() {
        _clientes = clientes;
        _suscripciones = suscripciones
            .where((s) => s.estado == 'activa')
            .toList();
        _plataformas = plataformas;
        _aplicarFiltros();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar pagos: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _aplicarFiltros() {
    var filtradas = _suscripciones;

    // Búsqueda por texto
    final query = _searchController.text.toLowerCase().replaceAll('-', '');
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
        return cliente.nombreCompleto.toLowerCase().contains(query) ||
            cliente.telefono.replaceAll('-', '').contains(query);
      }).toList();
    }

    // Filtro por cliente
    if (_filtroCliente != 'todos') {
      filtradas = filtradas
          .where((s) => s.clienteId == _filtroCliente)
          .toList();
    }

    // Filtro por plataforma
    if (_filtroPlataforma != 'todas') {
      filtradas = filtradas
          .where((s) => s.plataformaId == _filtroPlataforma)
          .toList();
    }

    // Ordenar por fecha próximo pago (más cercano primero)
    filtradas.sort((a, b) => a.fechaProximoPago.compareTo(b.fechaProximoPago));

    setState(() => _suscripcionesFiltradas = filtradas);
  }

  void _limpiarFiltros() {
    setState(() {
      _searchController.clear();
      _filtroCliente = 'todos';
      _filtroMetodoPago = 'todos';
      _filtroPlataforma = 'todas';
      _fechaDesde = null;
      _fechaHasta = null;
      _ordenarPor = 'fecha_pago';
      _ordenDescendente = true;
      _aplicarFiltros();
    });
  }

  bool get _tieneFiltrosActivos =>
      _searchController.text.isNotEmpty ||
      _filtroCliente != 'todos' ||
      _filtroMetodoPago != 'todos' ||
      _filtroPlataforma != 'todas' ||
      _fechaDesde != null ||
      _fechaHasta != null ||
      _ordenarPor != 'fecha_pago' ||
      _ordenDescendente != true;

  void _mostrarFiltrosAvanzados() {
    showDialog(
      context: context,
      builder: (context) => FiltrosAvanzadosDialog(
        ordenarPor: _ordenarPor,
        ordenDescendente: _ordenDescendente,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
        filtroPlataforma: _filtroPlataforma,
        plataformas: _plataformas,
        onAplicar: (ordenar, descendente, desde, hasta, plataforma) {
          setState(() {
            _ordenarPor = ordenar;
            _ordenDescendente = descendente;
            _fechaDesde = desde;
            _fechaHasta = hasta;
            _filtroPlataforma = plataforma;
            _aplicarFiltros();
          });
        },
      ),
    );
  }

  void _mostrarDialogoPago([Pago? pago, Suscripcion? suscripcion]) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => PagoDialog(
        pago: pago,
        suscripcionPreseleccionada: suscripcion,
        clientes: _clientes,
        suscripciones: _suscripciones,
        plataformas: _plataformas,
      ),
    );

    if (resultado == true) {
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Resumen compacto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Row(
              //detalle cuentas cobrasdas
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pagos Pendientes',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'L ${_suscripcionesFiltradas.fold(0.0, (sum, s) => sum + s.precio).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.account_balance_wallet,
                  size: 32,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),

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
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por cliente o referencia...',
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
                          fillColor: Colors.black,
                        ),
                        onChanged: (_) => _aplicarFiltros(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Badge(
                      label: Text(_tieneFiltrosActivos ? '!' : ''),
                      isLabelVisible: _tieneFiltrosActivos,
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
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _filtroCliente,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Cliente',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'todos',
                            child: Text('Todos'),
                          ),
                          ..._clientes.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.nombreCompleto,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _filtroCliente = v!;
                            _aplicarFiltros();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroMetodoPago,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Método',
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
                            value: 'efectivo',
                            child: Text('Efectivo'),
                          ),
                          DropdownMenuItem(
                            value: 'transferencia',
                            child: Text('Transfer.'),
                          ),
                          DropdownMenuItem(
                            value: 'deposito',
                            child: Text('Depósito'),
                          ),
                          DropdownMenuItem(value: 'otro', child: Text('Otro')),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _filtroMetodoPago = v!;
                            _aplicarFiltros();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_tieneFiltrosActivos)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: const Text('Filtros aplicados'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: _limpiarFiltros,
                    ),
                  ),
              ],
            ),
          ),

          // Lista de pagos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suscripcionesFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _suscripciones.isEmpty
                              ? 'No hay pagos pendientes'
                              : 'No se encontraron pagos pendientes',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _suscripciones.isEmpty
                              ? 'Registra tu primer cobro'
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
                          orElse: () => Plataforma(
                            id: '',
                            nombre: 'N/A',
                            icono: '',
                            precioBase: 0,
                            maxPerfiles: 0,
                            color: '#999999',
                            estado: '',
                            fechaCreacion: DateTime.now(),
                          ),
                        );

                        return _ProximoCobroCard(
                          suscripcion: suscripcion,
                          cliente: cliente,
                          plataforma: plataforma,
                          onCobrar: () =>
                              _mostrarDialogoPago(null, suscripcion),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),

      // Continuará con Card, Dialogs...
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_pagos",
        onPressed: () => _mostrarDialogoPago(),
        icon: const Icon(Icons.add),
        label: const Text('Registrar Pago'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ==================== PAGO CARD ====================

class _ProximoCobroCard extends StatelessWidget {
  final Suscripcion suscripcion;
  final Cliente cliente;
  final Plataforma plataforma;
  final VoidCallback onCobrar;

  const _ProximoCobroCard({
    required this.suscripcion,
    required this.cliente,
    required this.plataforma,
    required this.onCobrar,
  });

  @override
  Widget build(BuildContext context) {
    final diasRestantes = suscripcion.fechaProximoPago
        .difference(DateTime.now())
        .inDays;

    // Colores según urgencia
    Color urgenciaColor;
    String estadoTexto;

    if (diasRestantes < 0) {
      urgenciaColor = Colors.red.shade400;
      estadoTexto = 'VENCIDO';
    } else if (diasRestantes == 0) {
      urgenciaColor = Colors.orange.shade400;
      estadoTexto = 'HOY';
    } else if (diasRestantes <= 3) {
      urgenciaColor = Colors.amber.shade400;
      estadoTexto = 'URGENTE';
    } else if (diasRestantes <= 7) {
      urgenciaColor = Colors.blue.shade400;
      estadoTexto = 'PRÓXIMO';
    } else {
      urgenciaColor = Colors.green.shade400;
      estadoTexto = 'AL DÍA';
    }

    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Header - MANTENER ESTILO EXACTO
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(
                int.parse(plataforma.color.replaceFirst('#', '0xFF')),
              ).withOpacity(0.15),
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
                        plataforma.nombre,
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: urgenciaColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estadoTexto,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Próximo Pago',
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(suscripcion.fechaProximoPago),
                        Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        'Monto',
                        'L ${suscripcion.precio.toStringAsFixed(2)}',
                        Icons.attach_money,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // NUEVO: Días restantes
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: urgenciaColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: urgenciaColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: urgenciaColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          diasRestantes < 0
                              ? 'Vencido hace ${diasRestantes.abs()} días'
                              : diasRestantes == 0
                              ? 'Vence HOY'
                              : 'En $diasRestantes días',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: urgenciaColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                // Botón cobrar - MANTENER ESTILO
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onCobrar,
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Cobrar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // MÉTODO _buildLogo - Agregar dentro de la clase _ProximoCobroCard (o _PagoCard)
  // Ubicación: Después del método _buildInfoItem

  Widget _buildLogo(Plataforma plataforma) {
    // Mapa de logos de plataformas conocidas
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
      // Si existe logo, mostrarlo
      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) =>
              const FaIcon(FontAwesomeIcons.tv, size: 16, color: Colors.grey),
        ),
      );
    }

    // Fallback: círculo con color de plataforma
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Color(int.parse(plataforma.color.replaceFirst('#', '0xFF'))),
        shape: BoxShape.circle,
      ),
      child: const FaIcon(FontAwesomeIcons.tv, size: 16, color: Colors.white),
    );
  }
}
// ==================== FILTROS AVANZADOS DIALOG ====================

class FiltrosAvanzadosDialog extends StatefulWidget {
  final String ordenarPor;
  final bool ordenDescendente;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final String filtroPlataforma;
  final List<Plataforma> plataformas;
  final Function(String, bool, DateTime?, DateTime?, String) onAplicar;

  const FiltrosAvanzadosDialog({
    super.key,
    required this.ordenarPor,
    required this.ordenDescendente,
    this.fechaDesde,
    this.fechaHasta,
    required this.filtroPlataforma,
    required this.plataformas,
    required this.onAplicar,
  });

  @override
  State<FiltrosAvanzadosDialog> createState() => _FiltrosAvanzadosDialogState();
}

class _FiltrosAvanzadosDialogState extends State<FiltrosAvanzadosDialog> {
  late String _ordenarPor;
  late bool _ordenDescendente;
  late DateTime? _fechaDesde;
  late DateTime? _fechaHasta;
  late String _filtroPlataforma;

  @override
  void initState() {
    super.initState();
    _ordenarPor = widget.ordenarPor;
    _ordenDescendente = widget.ordenDescendente;
    _fechaDesde = widget.fechaDesde;
    _fechaHasta = widget.fechaHasta;
    _filtroPlataforma = widget.filtroPlataforma;
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
                  value: 'fecha_pago',
                  child: Text('Fecha de Pago'),
                ),
                DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                DropdownMenuItem(value: 'monto', child: Text('Monto')),
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
              'Plataforma',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _filtroPlataforma,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem(value: 'todas', child: Text('Todas')),
                ...widget.plataformas.map(
                  (p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)),
                ),
              ],
              onChanged: (v) => setState(() => _filtroPlataforma = v!),
            ),
            const Divider(height: 24),
            const Text(
              'Rango de Fechas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _fechaDesde == null
                    ? 'Desde: No establecido'
                    : 'Desde: ${DateFormat('dd/MM/yyyy').format(_fechaDesde!)}',
                style: const TextStyle(fontSize: 14),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaDesde ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (fecha != null) {
                  setState(() => _fechaDesde = fecha);
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _fechaHasta == null
                    ? 'Hasta: No establecido'
                    : 'Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaHasta!)}',
                style: const TextStyle(fontSize: 14),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaHasta ?? DateTime.now(),
                  firstDate: _fechaDesde ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (fecha != null) {
                  setState(() => _fechaHasta = fecha);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onAplicar('fecha_pago', true, null, null, 'todas');
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
              _fechaDesde,
              _fechaHasta,
              _filtroPlataforma,
            );
            Navigator.pop(context);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

// ==================== PAGO DIALOG (CREAR/EDITAR) ====================

class PagoDialog extends StatefulWidget {
  final Pago? pago;
  final Suscripcion? suscripcionPreseleccionada;
  final List<Cliente> clientes;
  final List<Suscripcion> suscripciones;
  final List<Plataforma> plataformas;

  const PagoDialog({
    super.key,
    this.pago,
    this.suscripcionPreseleccionada,
    required this.clientes,
    required this.suscripciones,
    required this.plataformas,
  });

  @override
  State<PagoDialog> createState() => _PagoDialogState();
}

class _PagoDialogState extends State<PagoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  late TextEditingController _montoController;
  late TextEditingController _referenciaController;
  late TextEditingController _notasController;

  Cliente? _clienteSeleccionado;
  Suscripcion? _suscripcionSeleccionada;

  DateTime _fechaPago = DateTime.now();
  String _metodoPago = 'efectivo';
  bool _isLoading = false;
  bool _esEdicion = false;
  bool _esCobro = false;

  List<Suscripcion> _suscripcionesFiltradas = [];

  @override
  void initState() {
    super.initState();

    _esEdicion = widget.pago != null;
    _esCobro = widget.suscripcionPreseleccionada != null && widget.pago == null;
    _montoController = TextEditingController();
    _referenciaController = TextEditingController();
    _notasController = TextEditingController();

    if (_esEdicion) {
      _cargarDatosEdicion();
    } else if (widget.suscripcionPreseleccionada != null) {
      // Precargar suscripción para cobro rápido
      _suscripcionSeleccionada = widget.suscripcionPreseleccionada;
      _clienteSeleccionado = widget.clientes.firstWhere(
        (c) => c.id == widget.suscripcionPreseleccionada!.clienteId,
      );
      _montoController.text = widget.suscripcionPreseleccionada!.precio
          .toStringAsFixed(2);
      _filtrarSuscripciones();
    }
  }

  void _cargarDatosEdicion() {
    final p = widget.pago!;

    _clienteSeleccionado = widget.clientes.firstWhere(
      (c) => c.id == p.clienteId,
    );
    _suscripcionSeleccionada = widget.suscripciones.firstWhere(
      (s) => s.id == p.suscripcionId,
    );

    _montoController.text = p.monto.toStringAsFixed(2);
    _fechaPago = p.fechaPago;
    _metodoPago = p.metodoPago;
    _referenciaController.text = p.referencia ?? '';
    _notasController.text = p.notas ?? '';

    _filtrarSuscripciones();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _filtrarSuscripciones() {
    if (_clienteSeleccionado != null) {
      setState(() {
        _suscripcionesFiltradas = widget.suscripciones
            .where((s) => s.clienteId == _clienteSeleccionado!.id)
            .toList();
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clienteSeleccionado == null) {
      _mostrarError('Selecciona un cliente');
      return;
    }
    if (_suscripcionSeleccionada == null) {
      _mostrarError('Selecciona una suscripción');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pago = Pago(
        id: widget.pago?.id ?? '',
        suscripcionId: _suscripcionSeleccionada!.id,
        clienteId: _clienteSeleccionado!.id,
        monto: double.parse(_montoController.text),
        fechaPago: _fechaPago,
        metodoPago: _metodoPago,
        referencia: _referenciaController.text.trim().isEmpty
            ? null
            : _referenciaController.text.trim(),
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
        registradoPor: null, // Se asignará por trigger o en el backend
      );

      if (_esEdicion) {
        print('Actualizando pago: ${pago.id}');
        await _supabaseService.actualizarPago(pago);
      } else {
        print('Creando nuevo pago para suscripción: ${pago.suscripcionId}');
        await _supabaseService.crearPago(pago);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion ? 'Pago actualizado' : 'Pago registrado'),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
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
                    Icons.payments,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _esEdicion ? 'Editar Pago' : 'Registrar Pago',
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
                        onChanged: _isLoading || _esCobro
                            ? null
                            : (v) {
                                setState(() {
                                  _clienteSeleccionado = v;
                                  _suscripcionSeleccionada = null;
                                  _filtrarSuscripciones();
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      // Suscripción
                      DropdownButtonFormField<Suscripcion>(
                        value: _suscripcionSeleccionada,
                        decoration: InputDecoration(
                          labelText: 'Suscripción *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.subscriptions),
                          helperText: _suscripcionesFiltradas.isEmpty
                              ? 'Selecciona un cliente primero'
                              : null,
                        ),
                        items: _suscripcionesFiltradas.map((s) {
                          final plataforma = widget.plataformas.firstWhere(
                            (p) => p.id == s.plataformaId,
                            orElse: () => Plataforma(
                              id: '',
                              nombre: 'N/A',
                              icono: '',
                              precioBase: 0,
                              maxPerfiles: 0,
                              color: '',
                              estado: '',
                              fechaCreacion: DateTime.now(),
                            ),
                          );

                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              '${plataforma.nombre} - L${s.precio.toStringAsFixed(2)}',
                            ),
                          );
                        }).toList(),
                        onChanged:
                            _isLoading ||
                                _suscripcionesFiltradas.isEmpty ||
                                _esCobro
                            ? null
                            : (v) =>
                                  setState(() => _suscripcionSeleccionada = v),
                      ),
                      const SizedBox(height: 16),

                      // Monto
                      TextFormField(
                        controller: _montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto *',
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
                        enabled: !_isLoading && !_esCobro,
                      ),
                      const SizedBox(height: 16),

                      // Fecha de pago
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fecha de Pago *'),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(_fechaPago),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _isLoading
                            ? null
                            : () async {
                                final fecha = await showDatePicker(
                                  context: context,
                                  initialDate: _fechaPago,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (fecha != null) {
                                  setState(() => _fechaPago = fecha);
                                }
                              },
                      ),
                      const SizedBox(height: 16),

                      // Método de pago
                      DropdownButtonFormField<String>(
                        value: _metodoPago,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
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
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _metodoPago = v!),
                      ),
                      const SizedBox(height: 16),

                      // Referencia
                      TextFormField(
                        controller: _referenciaController,
                        decoration: const InputDecoration(
                          labelText: 'Referencia',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt_long),
                          helperText: 'Número de referencia o comprobante',
                        ),
                        enabled: !_isLoading,
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
                        maxLines: 2,
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
