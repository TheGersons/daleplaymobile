import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/alerta.dart';
import '../../models/plataforma.dart';
import '../../services/supabase_service.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final _supabaseService = SupabaseService();

  List<Alerta> _alertas = [];
  List<Alerta> _alertasFiltradas = [];
  List<Plataforma> _plataformas = [];

  bool _isLoading = true;

  String _filtroNivel = 'todos';
  String _filtroEstado = 'todos';
  String _filtroTipo = 'todos';

  int _alertasCriticas = 0;
  int _alertasUrgentes = 0;
  int _alertasPendientes = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final alertas = await _supabaseService.obtenerAlertas();
      final plataformas = await _supabaseService.obtenerPlataformas();

      setState(() {
        _alertas = alertas;
        _plataformas = plataformas;
        _aplicarFiltros();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar alertas: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _aplicarFiltros() {
    var filtradas = _alertas;

    if (_filtroNivel != 'todos') {
      filtradas = filtradas.where((a) => a.nivel == _filtroNivel).toList();
    }

    if (_filtroEstado != 'todos') {
      filtradas = filtradas.where((a) => a.estado == _filtroEstado).toList();
    }

    if (_filtroTipo != 'todos') {
      filtradas = filtradas.where((a) => a.tipoAlerta == _filtroTipo).toList();
    }

    _alertasCriticas = _alertas
        .where((a) => a.nivel == 'critico' && a.estado != 'resuelta')
        .length;
    _alertasUrgentes = _alertas
        .where((a) => a.nivel == 'urgente' && a.estado != 'resuelta')
        .length;
    _alertasPendientes = _alertas.where((a) => a.estado == 'pendiente').length;

    setState(() => _alertasFiltradas = filtradas);
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroNivel = 'todos';
      _filtroEstado = 'todos';
      _filtroTipo = 'todos';
      _aplicarFiltros();
    });
  }

  bool get _tieneFiltrosActivos =>
      _filtroNivel != 'todos' ||
      _filtroEstado != 'todos' ||
      _filtroTipo != 'todos';

 

  Future<void> _marcarComoResuelta(Alerta alerta) async {
    try {
      await _supabaseService.marcarAlertaComoResuelta(alerta.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Alerta resuelta')));
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

  Future<void> _eliminarAlerta(Alerta alerta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Alerta'),
        content: const Text('¿Estás seguro de eliminar esta alerta?'),
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
        await _supabaseService.eliminarAlerta(alerta.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Alerta eliminada')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade700, Colors.orange.shade500],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Centro de Alertas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatChip(
                      'Críticas',
                      _alertasCriticas.toString(),
                      Colors.red.shade900,
                    ),
                    _buildStatChip(
                      'Urgentes',
                      _alertasUrgentes.toString(),
                      Colors.orange.shade900,
                    ),
                    _buildStatChip(
                      'Pendientes',
                      _alertasPendientes.toString(),
                      Colors.white24,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroNivel,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Nivel',
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
                            value: 'critico',
                            child: Text('Crítico'),
                          ),
                          DropdownMenuItem(
                            value: 'urgente',
                            child: Text('Urgente'),
                          ),
                          DropdownMenuItem(
                            value: 'advertencia',
                            child: Text('Advertencia'),
                          ),
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text('Normal'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _filtroNivel = v!;
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
                            value: 'pendiente',
                            child: Text('Pendiente'),
                          ),
                          DropdownMenuItem(
                            value: 'leida',
                            child: Text('Leída'),
                          ),
                          DropdownMenuItem(
                            value: 'resuelta',
                            child: Text('Resuelta'),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroTipo,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
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
                            value: 'cobro_cliente',
                            child: Text('Cobro'),
                          ),
                          DropdownMenuItem(
                            value: 'pago_plataforma',
                            child: Text('Pago'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _filtroTipo = v!;
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _alertasFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _alertas.isEmpty
                              ? 'No hay alertas'
                              : 'No se encontraron alertas',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _alertas.isEmpty
                              ? '¡Todo está al día!'
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
                      itemCount: _alertasFiltradas.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final alerta = _alertasFiltradas[index];

                        // Buscamos la plataforma correspondiente
                        // Asegúrate de manejar el caso si no se encuentra (orElse)
                        final plataforma = _plataformas.firstWhere(
                          (p) => p.id == alerta.plataformaId,
                          orElse: () => Plataforma(
                            id: '',
                            nombre: 'Desconocido',
                            color: '#808080', // Gris por defecto
                            icono: '', precioBase: 140, maxPerfiles: 3, estado: '', fechaCreacion: DateTime.now(),
                          ),
                        );

                        return _AlertaCard(
                          alerta: alerta,
                          plataforma: plataforma, // <--- Pasamos la plataforma
                          onMarcarResuelta: () => {
                            _marcarComoResuelta(alerta)
                            
                          },
                          onEliminar: () => _eliminarAlerta(alerta),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ==================== ALERTA CARD ====================

class _AlertaCard extends StatelessWidget {
  final Alerta alerta;
  final Plataforma plataforma;
  final VoidCallback onMarcarResuelta;
  final VoidCallback onEliminar;

  const _AlertaCard({
    required this.alerta,
    required this.plataforma,
    required this.onMarcarResuelta,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Obtener color base de la plataforma
    final plataformaColor = Color(
      int.parse(plataforma.color.replaceFirst('#', '0xFF')),
    );

    // 2. Determinar colores de nivel (para el icono/badge)
    Color nivelColor;
    IconData nivelIcono;

    switch (alerta.nivel) {
      case 'critico':
        nivelColor = Colors.redAccent;
        nivelIcono = Icons.gpp_bad;
        break;
      case 'urgente':
        nivelColor = Colors.orangeAccent;
        nivelIcono = Icons.warning_amber;
        break;
      case 'advertencia':
        nivelColor = Colors.amberAccent;
        nivelIcono = Icons.info_outline;
        break;
      default:
        nivelColor = Colors.blueAccent;
        nivelIcono = Icons.notifications_none;
    }

    // Si la alerta ya está resuelta, atenuamos todo visualmente
    final esResuelta = alerta.estado == 'resuelta';
    final opacityFactor = esResuelta ? 0.6 : 1.0;

    return Opacity(
      opacity: opacityFactor,
      child: Card(
        elevation: 0, // Sin elevación para diseño plano/transparente
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // --- TU REQUISITO DE COLOR DE FONDO ---
        color: plataformaColor.withOpacity(0.15),
        
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER: Icono Nivel + Título + Fecha ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono circular con el color del nivel (no de la plataforma)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: nivelColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(nivelIcono, color: nivelColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  
                  // Títulos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título principal (Blanco Bold 16)
                        Text(
                          plataforma.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Requisito
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Nombre plataforma y fecha
                        Row(
                          children: [
                            Text(
                              plataforma.nombre,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' • ${DateFormat('dd/MM HH:mm').format(alerta.fechaCreacion)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1), // Separador sutil
              const SizedBox(height: 12),

              // --- BODY: Descripción ---
              Text(
                alerta.mensaje,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9), // Blanco casi puro
                  height: 1.4,
                ),
              ),

              // --- FOOTER: Acciones (Solo si no está resuelta o para eliminar) ---
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!esResuelta)
                    TextButton.icon(
                      onPressed: onMarcarResuelta,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.greenAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Resolver'),
                    )
                  else
                    // Badge visual si ya está resuelta
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Resuelta',
                            style: TextStyle(
                                color: Colors.green, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(), // Empuja el botón eliminar a la derecha

                  // Botón Eliminar (Discreto)
                  IconButton(
                    onPressed: onEliminar,
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent.shade100),
                    tooltip: 'Eliminar alerta',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}