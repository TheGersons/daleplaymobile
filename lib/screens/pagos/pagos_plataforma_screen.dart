import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/pago_plataforma.dart';
import '../../models/historial_pago_plataforma.dart';
import '../../models/plataforma.dart';
import '../../models/cuenta_correo.dart';
import '../../services/supabase_service.dart';

class PagosPlataformaScreen extends StatefulWidget {
  const PagosPlataformaScreen({super.key});

  @override
  State<PagosPlataformaScreen> createState() => _PagosPlataformaScreenState();
}

class _PagosPlataformaScreenState extends State<PagosPlataformaScreen> {
  final _supabaseService = SupabaseService();

  List<PagoPlataforma> _pagos = [];
  List<PagoPlataforma> _pagosFiltrados = [];
  List<Plataforma> _plataformas = [];
  List<CuentaCorreo> _cuentas = [];

  bool _isLoading = true;

  // Filtros básicos
  final _searchController = TextEditingController();
  String _filtroPlataforma = 'todas';
  String _filtroEstado = 'todos';

  // Filtros avanzados
  String _ordenarPor = 'fecha_proximo_pago';
  bool _ordenDescendente = false;

  double _totalMensual = 0.0;

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
      final pagos = await _supabaseService.obtenerPagosPlataforma();
      final plataformas = await _supabaseService.obtenerPlataformas();
      final cuentas = await _supabaseService.obtenerCuentas();

      setState(() {
        _pagos = pagos;
        _plataformas = plataformas;
        _cuentas = cuentas;
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
    var filtrados = _pagos;

    // Búsqueda por plataforma
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtrados = filtrados.where((p) {
        final plataforma = _plataformas.firstWhere(
          (pl) => pl.id == p.plataformaId,
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

        return plataforma.nombre.toLowerCase().contains(query);
      }).toList();
    }

    // Filtro por plataforma
    if (_filtroPlataforma != 'todas') {
      filtrados = filtrados
          .where((p) => p.plataformaId == _filtroPlataforma)
          .toList();
    }

    // Filtro por estado
    if (_filtroEstado != 'todos') {
      filtrados = filtrados.where((p) => p.estado == _filtroEstado).toList();
    }

    // Ordenamiento
    filtrados.sort((a, b) {
      int comparison = 0;

      switch (_ordenarPor) {
        case 'fecha_proximo_pago':
          comparison = a.fechaProximoPago.compareTo(b.fechaProximoPago);
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
        case 'monto':
          comparison = a.montoMensual.compareTo(b.montoMensual);
          break;
      }

      return _ordenDescendente ? -comparison : comparison;
    });

    // Calcular estadísticas
    _totalMensual = filtrados.fold(0.0, (sum, p) => sum + p.montoMensual);

    setState(() => _pagosFiltrados = filtrados);
  }

  void _limpiarFiltros() {
    setState(() {
      _searchController.clear();
      _filtroPlataforma = 'todas';
      _filtroEstado = 'todos';
      _ordenarPor = 'fecha_proximo_pago';
      _ordenDescendente = false;
      _aplicarFiltros();
    });
  }

  bool get _tieneFiltrosActivos =>
      _searchController.text.isNotEmpty ||
      _filtroPlataforma != 'todas' ||
      _filtroEstado != 'todos' ||
      _ordenarPor != 'fecha_proximo_pago' ||
      _ordenDescendente != false;

  void _mostrarFiltrosAvanzados() {
    showDialog(
      context: context,
      builder: (context) => FiltrosAvanzadosDialog(
        ordenarPor: _ordenarPor,
        ordenDescendente: _ordenDescendente,
        onAplicar: (ordenar, descendente) {
          setState(() {
            _ordenarPor = ordenar;
            _ordenDescendente = descendente;
            _aplicarFiltros();
          });
        },
      ),
    );
  }

  void _mostrarDialogoPago([PagoPlataforma? pago]) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => PagoPlataformaDialog(
        pago: pago,
        plataformas: _plataformas,
        cuentas: _cuentas,
      ),
    );

    if (resultado == true) {
      _cargarDatos();
    }
  }

  void _mostrarHistorial(PagoPlataforma pago) async {
    await showDialog(
      context: context,
      builder: (context) => HistorialPagosDialog(
        pagoPlataforma: pago,
        plataforma: _plataformas.firstWhere((p) => p.id == pago.plataformaId),
        cuenta: _cuentas.firstWhere((c) => c.id == pago.cuentaId),
      ),
    );
  }

  void _registrarPago(PagoPlataforma pago) async {
    await showDialog(
      context: context,
      builder: (context) => RegistrarPagoDialog(
        pagoPlataforma: pago,
        plataforma: _plataformas.firstWhere((p) => p.id == pago.plataformaId),
      ),
    );
    _cargarDatos();
  }

  Future<void> _eliminarPago(PagoPlataforma pago) async {
    final plataforma = _plataformas.firstWhere(
      (p) => p.id == pago.plataformaId,
    );

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Pago a Plataforma'),
        content: Text(
          '¿Estás seguro de eliminar el pago de "${plataforma.nombre}"?\n\n'
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
        await _supabaseService.eliminarPagoPlataforma(pago.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Pago eliminado')));
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
          // Header con estadísticas
          Container(
            width: double.infinity,
            // Un poco de padding vertical para que respire
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              // Usamos el color del contenedor primario del tema (usualmente un tono suave del color principal)
              color: Theme.of(context).colorScheme.primaryContainer,
              // Opcional: Si quieres que tenga bordes redondeados en la parte inferior
              // borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lado Izquierdo: Cantidad de pagos
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_pagosFiltrados.length} ${_pagosFiltrados.length == 1 ? 'pago' : 'pagos'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),

                // Lado Derecho: Total monetario
                Text(
                  // He usado _totalMensual del código original.
                  // Si quieres que el total cambie según el filtro de búsqueda, usa _totalFiltrado si lo tienes calculado.
                  'Total: L ${_totalMensual.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por plataforma...',
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
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
                            value: 'al_dia',
                            child: Text('Al día'),
                          ),
                          DropdownMenuItem(
                            value: 'por_pagar',
                            child: Text('Por pagar'),
                          ),
                          DropdownMenuItem(
                            value: 'vencido',
                            child: Text('Vencido'),
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

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pagosFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pagos.isEmpty
                              ? 'No hay pagos a plataformas registrados'
                              : 'No se encontraron pagos',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _pagos.isEmpty
                              ? 'Agrega tu primer pago'
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
                      itemCount: _pagosFiltrados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final pago = _pagosFiltrados[index];
                        final plataforma = _plataformas.firstWhere(
                          (p) => p.id == pago.plataformaId,
                        );
                        final cuenta = _cuentas.firstWhere(
                          (c) => c.id == pago.cuentaId,
                        );

                        return _PagoPlataformaCard(
                          pago: pago,
                          plataforma: plataforma,
                          cuenta: cuenta,
                          onPagar: () => _registrarPago(pago),
                          onHistorial: () => _mostrarHistorial(pago),
                          onEdit: () => _mostrarDialogoPago(pago),
                          onDelete: () => _eliminarPago(pago),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoPago(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Pago'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ==================== PAGO PLATAFORMA CARD ====================

class _PagoPlataformaCard extends StatelessWidget {
  final PagoPlataforma pago;
  final Plataforma plataforma;
  final CuentaCorreo cuenta;
  final VoidCallback onPagar;
  final VoidCallback onHistorial;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PagoPlataformaCard({
    required this.pago,
    required this.plataforma,
    required this.cuenta,
    required this.onPagar,
    required this.onHistorial,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final diasRestantes = pago.fechaProximoPago
        .difference(DateTime.now())
        .inDays;

    // 1. Lógica de colores idéntica a tu referencia
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

    // Parseo seguro del color de la plataforma
    final plataformaColor = Color(
      int.parse(plataforma.color.replaceFirst('#', '0xFF')),
    );

    return Card(
      elevation: 2,
      // IMPORTANTE: Fondo blanco/superficie para que contraste bien con tu fondo oscuro
      color: Color(
        int.parse(plataforma.color.replaceFirst('#', '0xFF')),
      ).withOpacity(0.15),
      clipBehavior:
          Clip.antiAlias, // Para que el borde del header se recorte bien
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // 2. HEADER - Estilo idéntico a la referencia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: plataformaColor.withOpacity(0.15),
              border: Border(
                bottom: BorderSide(color: plataformaColor, width: 2),
              ),
            ),
            child: Row(
              children: [
                // Asumo que tienes este método o widget
                _buildLogo(plataforma),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plataforma.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        cuenta.email,
                        style: TextStyle(fontSize: 12, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Pill de estado (Pill sólida)
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

          // 3. CONTENIDO
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Fila de Monto y Fecha
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Monto Mensual',
                        'L ${pago.montoMensual.toStringAsFixed(2)}',
                        Icons.attach_money,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        'Próximo Pago',
                        DateFormat('dd/MM/yyyy').format(pago.fechaProximoPago),
                        Icons.calendar_today,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 4. CAJA DE DÍAS RESTANTES (Estilo copiado exactamente)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: urgenciaColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: urgenciaColor.withOpacity(0.5)),
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
                              : 'Vence en $diasRestantes días',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: urgenciaColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        'Día ${pago.diaPagoMes}',
                        style: TextStyle(
                          fontSize: 12,
                          color: urgenciaColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Info extra (Último pago y Notas) - Diseño sutil
                if (pago.fechaUltimoPago != null ||
                    (pago.notas?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 12),
                  if (pago.fechaUltimoPago != null)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Último pago: ${DateFormat('dd/MM/yyyy').format(pago.fechaUltimoPago!)}',
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ],
                    ),
                  if (pago.notas?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        pago.notas!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 16),

                // 5. BOTONES DE ACCIÓN
                // Botón principal grande (Pagar)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onPagar,
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Registrar Pago'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Botones secundarios (Historial, Editar, Borrar) en una fila limpia
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: onHistorial,
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text(
                        'Historial',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: Colors.blue[700],
                          tooltip: 'Editar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.red[700],
                          tooltip: 'Eliminar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
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

  // Helper idéntico al de tu referencia
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Color fuerte para contraste sobre blanco
          ),
        ),
      ],
    );
  }
}
// ==================== FILTROS AVANZADOS DIALOG ====================

class FiltrosAvanzadosDialog extends StatefulWidget {
  final String ordenarPor;
  final bool ordenDescendente;
  final Function(String, bool) onAplicar;

  const FiltrosAvanzadosDialog({
    super.key,
    required this.ordenarPor,
    required this.ordenDescendente,
    required this.onAplicar,
  });

  @override
  State<FiltrosAvanzadosDialog> createState() => _FiltrosAvanzadosDialogState();
}

class _FiltrosAvanzadosDialogState extends State<FiltrosAvanzadosDialog> {
  late String _ordenarPor;
  late bool _ordenDescendente;

  @override
  void initState() {
    super.initState();
    _ordenarPor = widget.ordenarPor;
    _ordenDescendente = widget.ordenDescendente;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ordenamiento'),
      content: Column(
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(
                value: 'fecha_proximo_pago',
                child: Text('Fecha Próximo Pago'),
              ),
              DropdownMenuItem(value: 'plataforma', child: Text('Plataforma')),
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onAplicar('fecha_proximo_pago', false);
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
            widget.onAplicar(_ordenarPor, _ordenDescendente);
            Navigator.pop(context);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

// ==================== PAGO PLATAFORMA DIALOG (CREAR/EDITAR) ====================

class PagoPlataformaDialog extends StatefulWidget {
  final PagoPlataforma? pago;
  final List<Plataforma> plataformas;
  final List<CuentaCorreo> cuentas;

  const PagoPlataformaDialog({
    super.key,
    this.pago,
    required this.plataformas,
    required this.cuentas,
  });

  @override
  State<PagoPlataformaDialog> createState() => _PagoPlataformaDialogState();
}

class _PagoPlataformaDialogState extends State<PagoPlataformaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  late TextEditingController _montoController;
  late TextEditingController _diasGraciaController;
  late TextEditingController _notasController;

  Plataforma? _plataformaSeleccionada;
  CuentaCorreo? _cuentaSeleccionada;

  int _diaPagoMes = 1;
  DateTime _fechaProximoPago = DateTime.now();
  String _metodoPagoPreferido = 'transferencia';
  bool _isLoading = false;
  bool _esEdicion = false;

  List<CuentaCorreo> _cuentasFiltradas = [];

  @override
  void initState() {
    super.initState();

    _esEdicion = widget.pago != null;
    _montoController = TextEditingController();
    _diasGraciaController = TextEditingController(text: '5');
    _notasController = TextEditingController();

    if (_esEdicion) {
      _cargarDatosEdicion();
    }
  }

  void _cargarDatosEdicion() {
    final p = widget.pago!;

    _plataformaSeleccionada = widget.plataformas.firstWhere(
      (pl) => pl.id == p.plataformaId,
    );
    _cuentaSeleccionada = widget.cuentas.firstWhere((c) => c.id == p.cuentaId);

    _montoController.text = p.montoMensual.toStringAsFixed(2);
    _diaPagoMes = p.diaPagoMes;
    _fechaProximoPago = p.fechaProximoPago;
    _diasGraciaController.text = p.diasGracia.toString();
    _metodoPagoPreferido = p.metodoPagoPreferido;
    _notasController.text = p.notas ?? '';

    _filtrarCuentas();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _diasGraciaController.dispose();
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_plataformaSeleccionada == null) {
      _mostrarError('Selecciona una plataforma');
      return;
    }
    if (_cuentaSeleccionada == null) {
      _mostrarError('Selecciona una cuenta');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Calcular fecha límite (próximo pago + días de gracia)
      final diasGracia = int.parse(_diasGraciaController.text);
      final fechaLimite = _fechaProximoPago.add(Duration(days: diasGracia));

      final pago = PagoPlataforma(
        id: widget.pago?.id ?? '00000000-0000-0000-0000-000000000000',
        cuentaId: _cuentaSeleccionada!.id,
        plataformaId: _plataformaSeleccionada!.id,
        montoMensual: double.parse(_montoController.text),
        diaPagoMes: _diaPagoMes,
        fechaProximoPago: _fechaProximoPago,
        fechaLimitePago: fechaLimite,
        diasGracia: diasGracia,
        estado: widget.pago?.estado ?? 'por_pagar',
        metodoPagoPreferido: _metodoPagoPreferido,
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
        fechaUltimoPago: widget.pago?.fechaUltimoPago,
        fechaCreacion: widget.pago?.fechaCreacion ?? DateTime.now(),
      );

      if (_esEdicion) {
        await _supabaseService.actualizarPagoPlataforma(pago);
      } else {
        await _supabaseService.crearPagoPlataforma(pago);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion ? 'Pago actualizado' : 'Pago creado'),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.shade700),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    _esEdicion ? 'Editar Pago' : 'Nuevo Pago a Plataforma',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                                  _filtrarCuentas();
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      // Cuenta
                      DropdownButtonFormField<CuentaCorreo>(
                        value: _cuentaSeleccionada,
                        decoration: InputDecoration(
                          labelText: 'Cuenta *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email),
                          helperText: _cuentasFiltradas.isEmpty
                              ? 'Selecciona una plataforma primero'
                              : null,
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
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoading || _cuentasFiltradas.isEmpty
                            ? null
                            : (v) => setState(() => _cuentaSeleccionada = v),
                      ),
                      const SizedBox(height: 16),

                      // Monto
                      TextFormField(
                        controller: _montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto Mensual *',
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

                      // Día de pago
                      DropdownButtonFormField<int>(
                        value: _diaPagoMes,
                        decoration: const InputDecoration(
                          labelText: 'Día de Pago del Mes *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        items: List.generate(31, (index) => index + 1)
                            .map(
                              (dia) => DropdownMenuItem(
                                value: dia,
                                child: Text('Día $dia'),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _diaPagoMes = v!),
                      ),
                      const SizedBox(height: 16),

                      // Fecha próximo pago
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fecha Próximo Pago *'),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(_fechaProximoPago),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _isLoading
                            ? null
                            : () async {
                                final fecha = await showDatePicker(
                                  context: context,
                                  initialDate: _fechaProximoPago,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
                                );
                                if (fecha != null) {
                                  setState(() => _fechaProximoPago = fecha);
                                }
                              },
                      ),
                      const SizedBox(height: 16),

                      // Días de gracia
                      TextFormField(
                        controller: _diasGraciaController,
                        decoration: const InputDecoration(
                          labelText: 'Días de Gracia',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timelapse),
                          helperText: 'Días extras después de la fecha de pago',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Campo requerido';
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Método de pago preferido
                      DropdownButtonFormField<String>(
                        value: _metodoPagoPreferido,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago Preferido',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'transferencia',
                            child: Text('Transferencia'),
                          ),
                          DropdownMenuItem(
                            value: 'efectivo',
                            child: Text('Efectivo'),
                          ),
                          DropdownMenuItem(
                            value: 'tarjeta',
                            child: Text('Tarjeta'),
                          ),
                          DropdownMenuItem(value: 'otro', child: Text('Otro')),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _metodoPagoPreferido = v!),
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

// ==================== REGISTRAR PAGO DIALOG ====================

class RegistrarPagoDialog extends StatefulWidget {
  final PagoPlataforma pagoPlataforma;
  final Plataforma plataforma;

  const RegistrarPagoDialog({
    super.key,
    required this.pagoPlataforma,
    required this.plataforma,
  });

  @override
  State<RegistrarPagoDialog> createState() => _RegistrarPagoDialogState();
}

class _RegistrarPagoDialogState extends State<RegistrarPagoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  late TextEditingController _montoController;
  late TextEditingController _referenciaController;
  late TextEditingController _notasController;

  DateTime _fechaPago = DateTime.now();
  String _metodoPago = 'transferencia';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: widget.pagoPlataforma.montoMensual.toStringAsFixed(2),
    );
    _referenciaController = TextEditingController();
    _notasController = TextEditingController();
    _metodoPago = widget.pagoPlataforma.metodoPagoPreferido;
  }

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _registrarPago() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Crear registro en historial
      final historial = HistorialPagoPlataforma(
        id: '00000000-0000-0000-0000-000000000000',
        pagoPlataformaId: widget.pagoPlataforma.id,
        montoPagado: double.parse(_montoController.text),
        fechaPago: _fechaPago,
        metodoPago: _metodoPago,
        referencia: _referenciaController.text.trim().isEmpty
            ? null
            : _referenciaController.text.trim(),
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
        registradoPor: null,
      );

      await _supabaseService.registrarPagoPlataforma(historial);

      // Actualizar pago_plataforma
      final nuevaFechaProximoPago = DateTime(
        widget.pagoPlataforma.fechaProximoPago.year,
        widget.pagoPlataforma.fechaProximoPago.month + 1,
        widget.pagoPlataforma.diaPagoMes,
      );

      final diasGracia = widget.pagoPlataforma.diasGracia;
      final nuevaFechaLimite = nuevaFechaProximoPago.add(
        Duration(days: diasGracia),
      );

      final pagoActualizado = PagoPlataforma(
        id: widget.pagoPlataforma.id,
        cuentaId: widget.pagoPlataforma.cuentaId,
        plataformaId: widget.pagoPlataforma.plataformaId,
        montoMensual: widget.pagoPlataforma.montoMensual,
        diaPagoMes: widget.pagoPlataforma.diaPagoMes,
        fechaProximoPago: nuevaFechaProximoPago,
        fechaLimitePago: nuevaFechaLimite,
        diasGracia: diasGracia,
        estado: 'al_dia',
        metodoPagoPreferido: widget.pagoPlataforma.metodoPagoPreferido,
        notas: widget.pagoPlataforma.notas,
        fechaUltimoPago: _fechaPago,
        fechaCreacion: widget.pagoPlataforma.fechaCreacion,
      );

      await _supabaseService.actualizarPagoPlataforma(pagoActualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado correctamente')),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.shade700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payment, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Registrar Pago',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.plataforma.nombre,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto Pagado *',
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
                                if (fecha != null)
                                  setState(() => _fechaPago = fecha);
                              },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _metodoPago,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'transferencia',
                            child: Text('Transferencia'),
                          ),
                          DropdownMenuItem(
                            value: 'efectivo',
                            child: Text('Efectivo'),
                          ),
                          DropdownMenuItem(
                            value: 'tarjeta',
                            child: Text('Tarjeta'),
                          ),
                          DropdownMenuItem(value: 'otro', child: Text('Otro')),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _metodoPago = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenciaController,
                        decoration: const InputDecoration(
                          labelText: 'Referencia',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt_long),
                        ),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
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
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _registrarPago,
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
                    label: const Text('Registrar Pago'),
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

// ==================== HISTORIAL PAGOS DIALOG ====================

class HistorialPagosDialog extends StatefulWidget {
  final PagoPlataforma pagoPlataforma;
  final Plataforma plataforma;
  final CuentaCorreo cuenta;

  const HistorialPagosDialog({
    super.key,
    required this.pagoPlataforma,
    required this.plataforma,
    required this.cuenta,
  });

  @override
  State<HistorialPagosDialog> createState() => _HistorialPagosDialogState();
}

class _HistorialPagosDialogState extends State<HistorialPagosDialog> {
  final _supabaseService = SupabaseService();

  List<HistorialPagoPlataforma> _historial = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);

    try {
      final historial = await _supabaseService.obtenerHistorialPagosPlataforma(
        widget.pagoPlataforma.id,
      );

      setState(() => _historial = historial);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPagado = _historial.fold(0.0, (sum, h) => sum + h.montoPagado);

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
                gradient: LinearGradient(
                  colors: [
                    Color(
                      int.parse(
                        widget.plataforma.color.replaceFirst('#', '0xFF'),
                      ),
                    ),
                    Color(
                      int.parse(
                        widget.plataforma.color.replaceFirst('#', '0xFF'),
                      ),
                    ).withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Historial de Pagos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.plataforma.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.cuenta.email,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pagado:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'L ${totalPagado.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de pagos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _historial.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay pagos registrados',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _historial.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final pago = _historial[index];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fecha y monto
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(pago.fechaPago),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'L ${pago.montoPagado.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Método de pago
                            Row(
                              children: [
                                Icon(
                                  Icons.payment,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getMetodoPagoTexto(pago.metodoPago ?? 'N/A'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),

                            // Referencia (opcional)
                            if (pago.referencia?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.receipt,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ref: ${pago.referencia}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Notas (opcional)
                            if (pago.notas?.isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  pago.notas!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
            ),

            // Botón cerrar
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

  String _getMetodoPagoTexto(String metodo) {
    switch (metodo) {
      case 'transferencia':
        return 'Transferencia';
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'otro':
        return 'Otro';
      default:
        return metodo;
    }
  }
}
