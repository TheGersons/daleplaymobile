import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/alerta.dart';
import '../../models/cliente.dart';
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
  List<Cliente> _clientes = [];
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
      final clientes = await _supabaseService.obtenerClientes();
      final plataformas = await _supabaseService.obtenerPlataformas();
      
      setState(() {
        _alertas = alertas;
        _clientes = clientes;
        _plataformas = plataformas;
        _aplicarFiltros();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar alertas: $e')),
        );
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

    _alertasCriticas = _alertas.where((a) => a.nivel == 'critico' && a.estado != 'resuelta').length;
    _alertasUrgentes = _alertas.where((a) => a.nivel == 'urgente' && a.estado != 'resuelta').length;
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
      _filtroNivel != 'todos' || _filtroEstado != 'todos' || _filtroTipo != 'todos';

  Future<void> _marcarComoLeida(Alerta alerta) async {
    try {
      await _supabaseService.marcarAlertaComoLeida(alerta.id);
      _cargarDatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _marcarComoResuelta(Alerta alerta) async {
    try {
      await _supabaseService.marcarAlertaComoResuelta(alerta.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta resuelta')),
        );
        _cargarDatos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alerta eliminada')),
          );
          _cargarDatos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
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
                const Text('Centro de Alertas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatChip('Críticas', _alertasCriticas.toString(), Colors.red.shade900),
                    _buildStatChip('Urgentes', _alertasUrgentes.toString(), Colors.orange.shade900),
                    _buildStatChip('Pendientes', _alertasPendientes.toString(), Colors.white24),
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
                        decoration: const InputDecoration(labelText: 'Nivel', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: 'todos', child: Text('Todos')),
                          DropdownMenuItem(value: 'critico', child: Text('Crítico')),
                          DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
                          DropdownMenuItem(value: 'advertencia', child: Text('Advertencia')),
                          DropdownMenuItem(value: 'normal', child: Text('Normal')),
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
                        decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: 'todos', child: Text('Todos')),
                          DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                          DropdownMenuItem(value: 'leida', child: Text('Leída')),
                          DropdownMenuItem(value: 'resuelta', child: Text('Resuelta')),
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
                        decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: 'todos', child: Text('Todos')),
                          DropdownMenuItem(value: 'cobro_cliente', child: Text('Cobro')),
                          DropdownMenuItem(value: 'pago_plataforma', child: Text('Pago')),
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
                    child: Chip(label: const Text('Filtros aplicados'), deleteIcon: const Icon(Icons.close, size: 18), onDeleted: _limpiarFiltros),
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
                            Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(_alertas.isEmpty ? 'No hay alertas' : 'No se encontraron alertas', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            Text(_alertas.isEmpty ? '¡Todo está al día!' : 'Intenta con otros filtros', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarDatos,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _alertasFiltradas.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final alerta = _alertasFiltradas[index];
                            final cliente = alerta.clienteId != null
                                ? _clientes.firstWhere((c) => c.id == alerta.clienteId, orElse: () => Cliente(id: '', nombreCompleto: 'N/A', telefono: '', estado: '', fechaRegistro: DateTime.now()))
                                : null;
                            final plataforma = alerta.plataformaId != null
                                ? _plataformas.firstWhere((p) => p.id == alerta.plataformaId, orElse: () => Plataforma(id: '', nombre: 'N/A', icono: '', precioBase: 0, maxPerfiles: 0, color: '#999999', estado: '', fechaCreacion: DateTime.now()))
                                : null;
                            
                            return _AlertaCard(
                              alerta: alerta,
                              cliente: cliente,
                              plataforma: plataforma,
                              onMarcarLeida: () => _marcarComoLeida(alerta),
                              onResolver: () => _marcarComoResuelta(alerta),
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ==================== ALERTA CARD ====================

class _AlertaCard extends StatelessWidget {
  final Alerta alerta;
  final Cliente? cliente;
  final Plataforma? plataforma;
  final VoidCallback onMarcarLeida;
  final VoidCallback onResolver;
  final VoidCallback onEliminar;

  const _AlertaCard({
    required this.alerta,
    this.cliente,
    this.plataforma,
    required this.onMarcarLeida,
    required this.onResolver,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    // Colores según nivel
    Color nivelColor;
    IconData nivelIcon;
    
    switch (alerta.nivel) {
      case 'critico':
        nivelColor = Colors.red;
        nivelIcon = Icons.error;
        break;
      case 'urgente':
        nivelColor = Colors.orange;
        nivelIcon = Icons.warning;
        break;
      case 'advertencia':
        nivelColor = Colors.amber;
        nivelIcon = Icons.info;
        break;
      default:
        nivelColor = Colors.blue;
        nivelIcon = Icons.notifications;
    }

    // Colores según estado
    Color cardColor;
    if (alerta.estado == 'resuelta') {
      cardColor = Colors.grey.shade100;
    } else {
      cardColor = nivelColor.withOpacity(0.1);
    }

    return Card(
      elevation: alerta.estado == 'resuelta' ? 0 : 2,
      color: cardColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: nivelColor, width: 4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(nivelIcon, color: nivelColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: nivelColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getNivelTexto(alerta.nivel),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getEstadoColor(alerta.estado),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getEstadoTexto(alerta.estado),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        alerta.mensaje,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: alerta.estado == 'resuelta' 
                              ? Colors.grey[600] 
                              : Colors.black87,
                          decoration: alerta.estado == 'resuelta'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (cliente != null) ...[
                            Icon(Icons.person, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              cliente!.nombreCompleto,
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (plataforma != null) ...[
                            Icon(Icons.tv, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              plataforma!.nombre,
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ],
                        ],
                      ),
                      if (alerta.monto != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_money, size: 16, color: Colors.green.shade700),
                              Text(
                                'L ${alerta.monto!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(alerta.fechaCreacion),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Acciones
          if (alerta.estado != 'resuelta')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (alerta.estado == 'pendiente')
                    TextButton.icon(
                      onPressed: onMarcarLeida,
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Marcar leída'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onResolver,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Resolver'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onEliminar,
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '✓ Resuelta',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onEliminar,
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getNivelTexto(String nivel) {
    switch (nivel) {
      case 'critico':
        return 'CRÍTICO';
      case 'urgente':
        return 'URGENTE';
      case 'advertencia':
        return 'ADVERTENCIA';
      default:
        return 'NORMAL';
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'leida':
        return 'Leída';
      case 'resuelta':
        return 'Resuelta';
      default:
        return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.grey;
      case 'leida':
        return Colors.blue;
      case 'resuelta':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}