import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

// Modelos
import '../../models/perfil.dart';
import '../../models/cuenta_correo.dart';
import '../../models/plataforma.dart';
import '../../models/suscripcion.dart';
import '../../models/cliente.dart';

// Servicios
import '../../services/supabase_service.dart';

class PerfilesScreen extends StatefulWidget {
  const PerfilesScreen({super.key});

  @override
  State<PerfilesScreen> createState() => _PerfilesScreenState();
}

class _PerfilesScreenState extends State<PerfilesScreen> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;

  // Datos crudos
  List<Perfil> _perfiles = [];
  List<CuentaCorreo> _cuentas = [];
  List<Plataforma> _plataformas = [];
  List<Suscripcion> _suscripciones = [];
  List<Cliente> _clientes = [];

  // Datos filtrados
  List<Perfil> _perfilesFiltrados = [];

  // Filtros
  final _searchController = TextEditingController();
  String _filtroEstado = 'todos';
  String _ordenarPor = 'plataforma';
  bool _ordenDescendente = false;

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
      final results = await Future.wait([
        _supabaseService.obtenerPerfiles(),
        _supabaseService.obtenerCuentas(),
        _supabaseService.obtenerPlataformas(),
        _supabaseService.obtenerSuscripciones(),
        _supabaseService.obtenerClientes(),
      ]);

      if (mounted) {
        setState(() {
          _perfiles = results[0] as List<Perfil>;
          _cuentas = results[1] as List<CuentaCorreo>;
          _plataformas = results[2] as List<Plataforma>;
          _suscripciones = results[3] as List<Suscripcion>;
          _clientes = results[4] as List<Cliente>;
          _aplicarFiltros();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando datos: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _aplicarFiltros() {
    var lista = List<Perfil>.from(_perfiles);
    final query = _searchController.text.toLowerCase().trim();
    final queryClean = query.replaceAll('-', '');

    // 1. Filtrado
    if (query.isNotEmpty) {
      lista = lista.where((p) {
        // Coincidencia con nombre del perfil o PIN
        bool matchPerfil =
            p.nombrePerfil.toLowerCase().contains(query) ||
            (p.pin?.contains(query) ?? false);

        // NUEVO: Coincidencia con email de cuenta
        bool matchEmail = false;
        try {
          final cuenta = _cuentas.firstWhere((c) => c.id == p.cuentaId);
          if (cuenta.email.toLowerCase().contains(query)) {
            matchEmail = true;
          }
        } catch (_) {}

        // Coincidencia con cliente asignado
        bool matchCliente = false;
        try {
          final suscripcion = _suscripciones.firstWhere(
            (s) => s.perfilId == p.id && s.estado == 'activa',
          );
          final cliente = _clientes.firstWhere(
            (c) => c.id == suscripcion.clienteId,
          );
          if (cliente.nombreCompleto.toLowerCase().contains(query))
            matchCliente = true;
          if (!matchCliente) {
            final telClienteClean = cliente.telefono.replaceAll('-', '');
            if (telClienteClean.contains(queryClean)) matchCliente = true;
          }
        } catch (_) {}

        return matchPerfil ||
            matchEmail ||
            matchCliente; // ← AGREGADO: matchEmail
      }).toList();
    }

    // 2. Estado
    if (_filtroEstado != 'todos') {
      lista = lista.where((p) => p.estado == _filtroEstado).toList();
    }

    // 3. Ordenamiento
    lista.sort((a, b) {
      // Disponibles siempre arriba
      if (a.estado == 'disponible' && b.estado != 'disponible') return -1;
      if (a.estado != 'disponible' && b.estado == 'disponible') return 1;

      // Desempate con criterio seleccionado
      int result = 0;
      switch (_ordenarPor) {
        case 'nombre':
          result = a.nombrePerfil.compareTo(b.nombrePerfil);
          break;
        case 'estado':
          result = a.estado.compareTo(b.estado);
          break;
        case 'plataforma':
        default:
          final platA = _obtenerNombrePlataforma(a.cuentaId);
          final platB = _obtenerNombrePlataforma(b.cuentaId);
          result = platA.compareTo(platB);
          break;
      }
      return _ordenDescendente ? -result : result;
    });

    setState(() {
      _perfilesFiltrados = lista;
    });
  }

  String _obtenerNombrePlataforma(String cuentaId) {
    final cuenta = _cuentas.firstWhere(
      (c) => c.id == cuentaId,
      orElse: () => CuentaCorreo(
        id: '',
        plataformaId: '',
        email: '',
        password: '',
        estado: '',
        fechaCreacion: DateTime.now(),
      ),
    );
    if (cuenta.id.isEmpty) return 'ZZZ';

    final plat = _plataformas.firstWhere(
      (p) => p.id == cuenta.plataformaId,
      orElse: () => Plataforma(
        id: '',
        nombre: 'ZZZ',
        icono: '',
        precioBase: 0,
        maxPerfiles: 0,
        color: '#000000',
        estado: '',
        fechaCreacion: DateTime.now(),
      ),
    );
    return plat.nombre;
  }

  // --- ACTIONS ---

  Future<void> _eliminarPerfil(Perfil perfil) async {
    final tieneSuscripcion = _suscripciones.any(
      (s) => s.perfilId == perfil.id && s.estado == 'activa',
    );
    if (tieneSuscripcion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar: Perfil ocupado por cliente.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Perfil'),
        content: Text('¿Eliminar "${perfil.nombrePerfil}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabaseService.eliminarPerfil(perfil.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Perfil eliminado')));
          _cargarDatos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _abrirDialogo({Perfil? perfil}) {
    showDialog(
      context: context,
      builder: (ctx) => PerfilDialog(
        perfil: perfil,
        cuentas: _cuentas,
        plataformas: _plataformas,
        suscripciones: _suscripciones, // <--- AGREGAR ESTO
        onGuardar: () {
          Navigator.pop(ctx);
          _cargarDatos();
        },
      ),
    );
  }

  void _mostrarFiltros() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ordenar y Filtrar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _filtroEstado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                DropdownMenuItem(
                  value: 'disponible',
                  child: Text('Disponible'),
                ),
                DropdownMenuItem(value: 'ocupado', child: Text('Ocupado')),
              ],
              onChanged: (v) => setState(() => _filtroEstado = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _ordenarPor,
              decoration: const InputDecoration(labelText: 'Ordenar por'),
              items: const [
                DropdownMenuItem(
                  value: 'plataforma',
                  child: Text('Plataforma'),
                ),
                DropdownMenuItem(value: 'nombre', child: Text('Nombre Perfil')),
                DropdownMenuItem(value: 'estado', child: Text('Estado')),
              ],
              onChanged: (v) => setState(() => _ordenarPor = v!),
            ),
            SwitchListTile(
              title: const Text('Descendente'),
              value: _ordenDescendente,
              onChanged: (v) => setState(() => _ordenDescendente = v),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              _aplicarFiltros();
              Navigator.pop(ctx);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar perfil, PIN, cliente...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _aplicarFiltros();
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => _aplicarFiltros(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _mostrarFiltros,
                  icon: const Icon(Icons.filter_list),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _perfilesFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron perfiles',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _perfilesFiltrados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildPerfilCard(_perfilesFiltrados[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_perfiles",
        onPressed: () => _abrirDialogo(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Perfil'),
      ),
    );
  }

  Widget _buildPerfilCard(Perfil perfil) {
    // Relaciones
    final cuenta = _cuentas.firstWhere(
      (c) => c.id == perfil.cuentaId,
      orElse: () => CuentaCorreo(
        id: '',
        plataformaId: '',
        email: 'Eliminada',
        password: '',
        estado: '',
        fechaCreacion: DateTime.now(),
      ),
    );

    final plataforma = _plataformas.firstWhere(
      (p) => p.id == cuenta.plataformaId,
      orElse: () => Plataforma(
        id: '',
        nombre: 'Desconocida',
        icono: '',
        precioBase: 0,
        maxPerfiles: 0,
        color: '#808080',
        estado: '',
        fechaCreacion: DateTime.now(),
      ),
    );

    // Búsqueda de ocupación
    Suscripcion? suscripcionActiva;
    Cliente? clienteAsignado;

    try {
      suscripcionActiva = _suscripciones.firstWhere(
        (s) => s.perfilId == perfil.id && s.estado == 'activa',
      );
      clienteAsignado = _clientes.firstWhere(
        (c) => c.id == suscripcionActiva!.clienteId,
      );
    } catch (_) {}

    final colorPlataforma = _parseColor(plataforma.color);
    final isOccupied = perfil.estado == 'ocupado';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorPlataforma.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          // HEADER CARD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorPlataforma.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _buildLogo(plataforma, 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plataforma.nombre,
                        style: TextStyle(
                          color: colorPlataforma,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        cuenta.email,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOccupied
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOccupied ? Colors.orange : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isOccupied ? 'OCUPADO' : 'DISPONIBLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOccupied
                          ? Colors.orange[800]
                          : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BODY CARD
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    perfil.nombrePerfil.isNotEmpty
                        ? perfil.nombrePerfil[0].toUpperCase()
                        : '#',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perfil.nombrePerfil,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PIN: ${perfil.pin}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: perfil.pin ?? ''),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN Copiado'),
                                  duration: Duration(milliseconds: 500),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.copy,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),

                      if (isOccupied && clienteAsignado != null) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${clienteAsignado.nombreCompleto} • ${clienteAsignado.telefono}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (suscripcionActiva != null)
                          Text(
                            'Vence: ${DateFormat('dd/MM/yyyy').format(suscripcionActiva.fechaProximoPago)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: _getColorFecha(
                                suscripcionActiva.fechaProximoPago,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _abrirDialogo(perfil: perfil),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () => _eliminarPerfil(perfil),
                      tooltip: 'Eliminar',
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

  // --- HELPERS VISUALES ---

  Color _parseColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Color _getColorFecha(DateTime fecha) {
    final dias = fecha.difference(DateTime.now()).inDays;
    if (dias < 0) return Colors.red;
    if (dias <= 3) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildLogo(Plataforma plataforma, double size) {
    // Lista completa de logos para consistencia
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
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: logoUrl,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => FaIcon(
              FontAwesomeIcons.tv,
              size: size * 0.6,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // Fallback: Icono coloreado
    return FaIcon(
      FontAwesomeIcons.tv,
      size: size,
      color: _parseColor(plataforma.color),
    );
  }
}

// ==================== DIALOG CREAR/EDITAR (CORREGIDO OVERFLOW) ====================

class PerfilDialog extends StatefulWidget {
  final Perfil? perfil;
  final List<CuentaCorreo> cuentas;
  final List<Plataforma> plataformas;
  final List<Suscripcion> suscripciones; // <--- Nuevo parámetro
  final VoidCallback onGuardar;

  const PerfilDialog({
    super.key,
    this.perfil,
    required this.cuentas,
    required this.plataformas,
    required this.suscripciones, // <--- Nuevo parámetro
    required this.onGuardar,
  });

  @override
  State<PerfilDialog> createState() => _PerfilDialogState();
}

class _PerfilDialogState extends State<PerfilDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  late TextEditingController _nombreController;
  late TextEditingController _pinController;

  String? _cuentaSeleccionadaId;
  String _estadoSeleccionado = 'disponible';
  bool _isLoading = false;

  // Variable para saber si está bloqueado por uso
  bool _tieneSuscripcionActiva = false;

  @override
  void initState() {
    super.initState();
    final p = widget.perfil;
    _nombreController = TextEditingController(text: p?.nombrePerfil ?? '');
    _pinController = TextEditingController(text: p?.pin ?? '');
    _cuentaSeleccionadaId = p?.cuentaId;
    _estadoSeleccionado = p?.estado ?? 'disponible';

    // VERIFICACIÓN: ¿Este perfil tiene una suscripción activa?
    if (p != null) {
      _tieneSuscripcionActiva = widget.suscripciones.any(
        (s) => s.perfilId == p.id && s.estado == 'activa',
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final nuevoPerfil = Perfil(
        id: widget.perfil?.id ?? '',
        cuentaId: _cuentaSeleccionadaId!,
        nombrePerfil: _nombreController.text.trim(),
        pin: _pinController.text.trim(),
        estado: _estadoSeleccionado,
        fechaCreacion: widget.perfil?.fechaCreacion ?? DateTime.now(),
      );

      if (widget.perfil == null) {
        await _supabaseService.crearPerfil(nuevoPerfil);
      } else {
        await _supabaseService.actualizarPerfil(nuevoPerfil);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.perfil == null ? 'Perfil creado' : 'Perfil actualizado',
            ),
          ),
        );
        widget.onGuardar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentasOrdenadas = List<CuentaCorreo>.from(widget.cuentas);
    cuentasOrdenadas.sort((a, b) {
      final platA = widget.plataformas
          .firstWhere(
            (p) => p.id == a.plataformaId,
            orElse: () => Plataforma(
              id: '',
              nombre: 'Z',
              icono: '',
              precioBase: 0,
              maxPerfiles: 0,
              color: '',
              estado: '',
              fechaCreacion: DateTime.now(),
            ),
          )
          .nombre;
      final platB = widget.plataformas
          .firstWhere(
            (p) => p.id == b.plataformaId,
            orElse: () => Plataforma(
              id: '',
              nombre: 'Z',
              icono: '',
              precioBase: 0,
              maxPerfiles: 0,
              color: '',
              estado: '',
              fechaCreacion: DateTime.now(),
            ),
          )
          .nombre;
      return platA.compareTo(platB);
    });

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.perfil == null ? 'Nuevo Perfil' : 'Editar Perfil',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Aviso si está bloqueado
                if (_tieneSuscripcionActiva)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange[800],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Edición restringida: Este perfil está asignado a un cliente activo.',
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _cuentaSeleccionadaId,
                  // BLOQUEO: No se puede cambiar de cuenta si está activo
                  onChanged: _tieneSuscripcionActiva
                      ? null
                      : (v) => setState(() => _cuentaSeleccionadaId = v),
                  decoration: const InputDecoration(
                    labelText: 'Cuenta asociada *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  items: cuentasOrdenadas.map((c) {
                    final plat = widget.plataformas.firstWhere(
                      (p) => p.id == c.plataformaId,
                      orElse: () => Plataforma(
                        id: '',
                        nombre: '?',
                        icono: '',
                        precioBase: 0,
                        maxPerfiles: 0,
                        color: '',
                        estado: '',
                        fechaCreacion: DateTime.now(),
                      ),
                    );
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        '${plat.nombre} - ${c.email}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  validator: (v) => v == null ? 'Selecciona una cuenta' : null,
                  isExpanded: true,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Perfil *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.face),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // PIN (opcional)
                TextFormField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pin),
                    hintText: '4 dígitos',
                    helperText:
                        'Deje en blanco para no usar PIN', // Ayuda visual al usuario
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (v) {
                    // Si el usuario no escribe nada, no hay error
                    if (v == null || v.isEmpty) return null;
                    // Solo validamos longitud si hay texto
                    if (v.length < 4) return 'El PIN debe tener 4 dígitos';
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _estadoSeleccionado,
                  // BLOQUEO: No se puede cambiar el estado si está activo
                  onChanged: _tieneSuscripcionActiva
                      ? null
                      : (v) => setState(() => _estadoSeleccionado = v!),
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.toggle_on),
                    helperText: 'Bloqueado si hay suscripción activa',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'disponible',
                      child: Text('Disponible'),
                    ),
                    DropdownMenuItem(value: 'ocupado', child: Text('Ocupado')),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
