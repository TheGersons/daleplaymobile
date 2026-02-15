import 'package:daleplay/screens/cuentas/cuenta_detalle_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/cuenta_correo.dart';
import '../../models/plataforma.dart';
import '../../models/perfil.dart';
import '../../services/supabase_service.dart';
import '../../models/cliente.dart';
import '../../models/suscripcion.dart';

class CuentasScreen extends StatefulWidget {
  const CuentasScreen({super.key});

  @override
  State<CuentasScreen> createState() => _CuentasScreenState();
}

class _CuentasScreenState extends State<CuentasScreen> {
  final _supabaseService = SupabaseService();
  List<CuentaCorreo> _cuentas = [];
  List<CuentaCorreo> _cuentasFiltradas = [];
  List<Plataforma> _plataformas = [];
  List<Perfil> _perfiles = [];
  List<Cliente> _clientes = [];
  List<Suscripcion> _suscripciones = [];
  bool _isLoading = true;

  // Filtros básicos
  final _searchController = TextEditingController();
  String _filtroPlataforma = 'todas';
  String _filtroEstado = 'todos';

  // Filtros avanzados
  String _ordenarPor = 'email'; // email, perfiles_disponibles, perfiles_totales
  bool _ordenDescendente = false;
  bool? _conNotas;

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
      final cuentas = await _supabaseService.obtenerCuentas();
      final plataformas = await _supabaseService.obtenerPlataformas();
      final perfiles = await _supabaseService.obtenerPerfiles();
      final clientes = await _supabaseService.obtenerClientes();
      final suscripciones = await _supabaseService.obtenerSuscripciones();

      setState(() {
        _cuentas = cuentas;
        _plataformas = plataformas;
        _perfiles = perfiles;
        _clientes = clientes;
        _suscripciones = suscripciones;
        _aplicarFiltros();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar cuentas: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _perfilEstaDisponible(Perfil perfil) {
    return !_suscripciones.any(
      (s) => s.perfilId == perfil.id && s.estado != 'cancelada',
    );
  }

  void _aplicarFiltros() {
    var filtradas = _cuentas;

    // Búsqueda por texto
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtradas = filtradas
          .where((c) => c.email.toLowerCase().contains(query))
          .toList();
    }

    // Filtro por plataforma
    if (_filtroPlataforma != 'todas') {
      filtradas = filtradas
          .where((c) => c.plataformaId == _filtroPlataforma)
          .toList();
    }

    // Filtro por estado
    if (_filtroEstado != 'todos') {
      filtradas = filtradas.where((c) => c.estado == _filtroEstado).toList();
    }

    // Filtro por notas
    if (_conNotas != null) {
      filtradas = filtradas
          .where(
            (c) => _conNotas!
                ? (c.notas?.isNotEmpty == true)
                : (c.notas?.isEmpty != false),
          )
          .toList();
    }

    // Ordenamiento
    filtradas.sort((a, b) {
      int comparison = 0;

      switch (_ordenarPor) {
        case 'email':
          comparison = a.email.compareTo(b.email);
          break;
        case 'perfiles_disponibles':
          final disponiblesA = _perfiles
              .where((p) => p.cuentaId == a.id && _perfilEstaDisponible(p))
              .length;
          final disponiblesB = _perfiles
              .where((p) => p.cuentaId == b.id && _perfilEstaDisponible(p))
              .length;
          comparison = disponiblesA.compareTo(disponiblesB);
          break;
        case 'perfiles_totales':
          final perfilesA = _perfiles.where((p) => p.cuentaId == a.id).length;
          final perfilesB = _perfiles.where((p) => p.cuentaId == b.id).length;
          comparison = perfilesA.compareTo(perfilesB);
          break;
      }

      return _ordenDescendente ? -comparison : comparison;
    });

    setState(() => _cuentasFiltradas = filtradas);
  }

  void _limpiarFiltrosAvanzados() {
    setState(() {
      _ordenarPor = 'email';
      _ordenDescendente = false;
      _conNotas = null;
      _aplicarFiltros();
    });
  }

  bool get _tieneFiltrosAvanzados =>
      _ordenarPor != 'email' || _ordenDescendente != false || _conNotas != null;

  void _mostrarFiltrosAvanzados() {
    showDialog(
      context: context,
      builder: (context) => FiltrosAvanzadosDialog(
        ordenarPor: _ordenarPor,
        ordenDescendente: _ordenDescendente,
        conNotas: _conNotas,
        onAplicar: (ordenar, descendente, notas) {
          setState(() {
            _ordenarPor = ordenar;
            _ordenDescendente = descendente;
            _conNotas = notas;
            _aplicarFiltros();
          });
        },
      ),
    );
  }

  void _mostrarDialogoCuenta([CuentaCorreo? cuenta]) {
    showDialog(
      context: context,
      builder: (context) => CuentaDialog(
        cuenta: cuenta,
        plataformas: _plataformas,
        onGuardar: () {
          Navigator.pop(context);
          _cargarDatos();
        },
      ),
    );
  }

  void _mostrarDetalleCuenta(CuentaCorreo cuenta) {
    showDialog(
      context: context,
      builder: (context) => CuentaDetalleDialog(
        cuenta: cuenta,
        plataforma: _plataformas.firstWhere((p) => p.id == cuenta.plataformaId),
        perfiles: _perfiles.where((p) => p.cuentaId == cuenta.id).toList(),
        clientes: _clientes,
        suscripciones: _suscripciones,
        onEditar: () {
          Navigator.pop(context);
          _mostrarDialogoCuenta(cuenta);
        },
      ),
    );
  }

  Future<void> _eliminarCuenta(CuentaCorreo cuenta) async {
    // Verificar si tiene perfiles
    final perfilesCuenta = _perfiles
        .where((p) => p.cuentaId == cuenta.id)
        .toList();

    if (perfilesCuenta.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se puede eliminar. Tiene ${perfilesCuenta.length} perfil(es) asociado(s).',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: Text(
          '¿Estás seguro de eliminar la cuenta "${cuenta.email}"?\n\n'
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
        await _supabaseService.eliminarCuenta(cuenta.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Cuenta eliminada')));
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
                // Búsqueda + botón filtros avanzados
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por email...',
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
                    // Botón filtros avanzados
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
                    // Plataforma
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _filtroPlataforma,
                        isExpanded: true, // AGREGA ESTO
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
                              ), // AGREGA ESTO
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
                    // Estado
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _filtroEstado,
                        isExpanded: true, // AGREGA ESTO
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
                            value: 'inactiva',
                            child: Text('Inactivas'),
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
                // Chip de filtros activos
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
                : _cuentasFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _cuentas.isEmpty
                              ? 'No hay cuentas registradas'
                              : 'No se encontraron cuentas',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _cuentas.isEmpty
                              ? 'Agrega tu primera cuenta'
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
                      itemCount: _cuentasFiltradas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final cuenta = _cuentasFiltradas[index];
                        final plataforma = _plataformas.firstWhere(
                          (p) => p.id == cuenta.plataformaId,
                          orElse: () => Plataforma(
                            id: '',
                            nombre: 'Desconocida',
                            icono: 'Television',
                            precioBase: 0,
                            maxPerfiles: 0,
                            color: '#999999',
                            estado: 'activo',
                            fechaCreacion: DateTime.now(),
                          ),
                        );
                        final perfilesCuenta = _perfiles
                            .where((p) => p.cuentaId == cuenta.id)
                            .toList();
                        return _buildCuentaCard(
                          cuenta,
                          plataforma,
                          perfilesCuenta,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_cuentas",
        onPressed: () => _mostrarDialogoCuenta(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cuenta'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCuentaCard(
    CuentaCorreo cuenta,
    Plataforma plataforma,
    List<Perfil> perfiles,
  ) {
    final disponibles = perfiles
        .where(
          (p) =>
              p.cuentaId == cuenta.id && _perfilEstaDisponible(p), // ← CAMBIO
        )
        .length;

    final ocupados = perfiles
        .where(
          (p) =>
              p.cuentaId == cuenta.id && !_perfilEstaDisponible(p), // ← CAMBIO
        )
        .length;

    final perfilesDisponibles = disponibles;
    final perfilesOcupados = ocupados;

    return _CuentaCard(
      cuenta: cuenta,
      plataforma: plataforma,
      perfilesDisponibles: perfilesDisponibles,
      perfilesOcupados: perfilesOcupados,
      perfilesTotal: perfiles.length,
      onTap: () => _mostrarDetalleCuenta(cuenta),
      onEdit: () => _mostrarDialogoCuenta(cuenta),
      onDelete: () => _eliminarCuenta(cuenta),
    );
  }
}

// ==================== CARD WIDGET ====================

class _CuentaCard extends StatefulWidget {
  final CuentaCorreo cuenta;
  final Plataforma plataforma;
  final int perfilesDisponibles;
  final int perfilesOcupados;
  final int perfilesTotal;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CuentaCard({
    required this.cuenta,
    required this.plataforma,
    required this.perfilesDisponibles,
    required this.perfilesOcupados,
    required this.perfilesTotal,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CuentaCard> createState() => _CuentaCardState();
}

class _CuentaCardState extends State<_CuentaCard> {
  bool _mostrarPassword = false;

  @override
  Widget build(BuildContext context) {
    final colorPlataforma = Color(
      int.parse(widget.plataforma.color.replaceFirst('#', '0xFF')),
    );

    return Card(
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header con logo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorPlataforma.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: colorPlataforma, width: 2),
                ),
              ),
              child: Row(
                children: [
                  _buildLogo(widget.plataforma),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plataforma.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(widget.cuenta.fechaCreacion),
                          style: TextStyle(
                            fontSize: 12,
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
                      color: widget.cuenta.estado == 'activo'
                          ? Colors.green[50]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.cuenta.estado == 'activo'
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    child: Text(
                      widget.cuenta.estado == 'activo' ? 'activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.cuenta.estado == 'activo'
                            ? Colors.green[700]
                            : Colors.grey[700],
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
                  // Email
                  Row(
                    children: [
                      const Icon(Icons.email, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.cuenta.email,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.cuenta.email),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email copiado'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        tooltip: 'Copiar email',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Password
                  Row(
                    children: [
                      const Icon(Icons.lock, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mostrarPassword
                              ? widget.cuenta.password
                              : '•' * widget.cuenta.password.length,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _mostrarPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => setState(
                          () => _mostrarPassword = !_mostrarPassword,
                        ),
                        tooltip: _mostrarPassword ? 'Ocultar' : 'Mostrar',
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.cuenta.password),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contraseña copiada'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        tooltip: 'Copiar contraseña',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Perfiles
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 20, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Perfiles: ${widget.perfilesTotal}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              Text(
                                'Disponibles: ${widget.perfilesDisponibles} • Ocupados: ${widget.perfilesOcupados}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.cuenta.notas?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.cuenta.notas!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: widget.onDelete,
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
}

// ==================== FILTROS AVANZADOS DIALOG ====================

class FiltrosAvanzadosDialog extends StatefulWidget {
  final String ordenarPor;
  final bool ordenDescendente;
  final bool? conNotas;
  final Function(String, bool, bool?) onAplicar;

  const FiltrosAvanzadosDialog({
    super.key,
    required this.ordenarPor,
    required this.ordenDescendente,
    this.conNotas,
    required this.onAplicar,
  });

  @override
  State<FiltrosAvanzadosDialog> createState() => _FiltrosAvanzadosDialogState();
}

class _FiltrosAvanzadosDialogState extends State<FiltrosAvanzadosDialog> {
  late String _ordenarPor;
  late bool _ordenDescendente;
  late String _conNotasValue;

  @override
  void initState() {
    super.initState();
    _ordenarPor = widget.ordenarPor;
    _ordenDescendente = widget.ordenDescendente;

    // Convertir el bool? a String para el Dropdown
    _conNotasValue = widget.conNotas == null
        ? 'todos'
        : widget.conNotas!
        ? 'con_notas'
        : 'sin_notas';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtros Avanzados'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN ORDENAMIENTO ---
            const Text(
              'Ordenar por',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
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
                prefixIcon: Icon(Icons.sort),
              ),
              items: const [
                DropdownMenuItem(value: 'email', child: Text('Email (A-Z)')),
                DropdownMenuItem(
                  value: 'perfiles_disponibles',
                  child: Text('Perfiles Disponibles'),
                ),
                DropdownMenuItem(
                  value: 'perfiles_totales',
                  child: Text('Total de Perfiles'),
                ),
              ],
              onChanged: (v) => setState(() => _ordenarPor = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Orden Descendente'),
              subtitle: const Text('Mayor a menor / Z-A'),
              value: _ordenDescendente,
              onChanged: (v) => setState(() => _ordenDescendente = v),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(height: 24),

            // --- SECCIÓN NOTAS ---
            const Text(
              'Notas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _conNotasValue,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                prefixIcon: Icon(Icons.note),
              ),
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                DropdownMenuItem(value: 'con_notas', child: Text('Con notas')),
                DropdownMenuItem(value: 'sin_notas', child: Text('Sin notas')),
              ],
              onChanged: (v) => setState(() => _conNotasValue = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Resetear a valores por defecto
            widget.onAplicar('email', false, null);
            Navigator.pop(context);
          },
          child: const Text('Restablecer'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            // Convertir el String del dropdown de notas a bool?
            bool? conNotasBool;
            if (_conNotasValue == 'con_notas') conNotasBool = true;
            if (_conNotasValue == 'sin_notas') conNotasBool = false;

            widget.onAplicar(_ordenarPor, _ordenDescendente, conNotasBool);
            Navigator.pop(context);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
// ==================== CUENTA DIALOG ====================

class CuentaDialog extends StatefulWidget {
  final CuentaCorreo? cuenta;
  final List<Plataforma> plataformas;
  final VoidCallback onGuardar;

  const CuentaDialog({
    super.key,
    this.cuenta,
    required this.plataformas,
    required this.onGuardar,
  });

  @override
  State<CuentaDialog> createState() => _CuentaDialogState();
}

class _CuentaDialogState extends State<CuentaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _notasController;

  String? _plataformaSeleccionada;
  String _estadoSeleccionado = 'activo';
  bool _isLoading = false;
  bool _mostrarPassword = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cuenta;
    _emailController = TextEditingController(text: c?.email ?? '');
    _passwordController = TextEditingController(text: c?.password ?? '');
    _notasController = TextEditingController(text: c?.notas ?? '');
    _plataformaSeleccionada = c?.plataformaId;
    _estadoSeleccionado = c?.estado ?? 'activo';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cuenta = CuentaCorreo(
        id: widget.cuenta?.id ?? '',
        plataformaId: _plataformaSeleccionada!,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        estado: _estadoSeleccionado,
        fechaCreacion: widget.cuenta?.fechaCreacion ?? DateTime.now(),
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
      );

      if (widget.cuenta == null) {
        // CREAR: Auto-crea perfiles
        final cuentaId = await _supabaseService.crearCuenta(cuenta);

        if (mounted) {
          // Obtener plataforma para mostrar cuántos perfiles se crearon
          final plataforma = widget.plataformas.firstWhere(
            (p) => p.id == _plataformaSeleccionada,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cuenta creada con ${plataforma.maxPerfiles} perfiles disponibles',
              ),
              backgroundColor: Colors.green,
            ),
          );
          widget.onGuardar();
        }
      } else {
        // EDITAR: Valida cambio de plataforma automáticamente
        await _supabaseService.actualizarCuenta(cuenta);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta actualizada'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onGuardar();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
                    Icons.email,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.cuenta == null ? 'Nueva Cuenta' : 'Editar Cuenta',
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
                      DropdownButtonFormField<String>(
                        value: _plataformaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Plataforma *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tv),
                        ),
                        items: widget.plataformas
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoading
                            ? null
                            : (v) =>
                                  setState(() => _plataformaSeleccionada = v),
                        validator: (v) =>
                            v == null ? 'Selecciona una plataforma' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Campo requerido';
                          if (!v!.contains('@')) return 'Email inválido';
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mostrarPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _mostrarPassword = !_mostrarPassword,
                            ),
                          ),
                        ),
                        obscureText: !_mostrarPassword,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Campo requerido' : null,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _estadoSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.toggle_on),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'activo',
                            child: Text('activo'),
                          ),
                          DropdownMenuItem(
                            value: 'inactivo',
                            child: Text('Inactivo'),
                          ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _estadoSeleccionado = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notasController,
                        decoration: const InputDecoration(
                          labelText: 'Notas',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                          helperText: 'Opcional',
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
