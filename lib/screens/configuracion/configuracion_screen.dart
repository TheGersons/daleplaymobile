import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/configuracion.dart';
import '../../services/supabase_service.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _supabaseService = SupabaseService();
  
  List<Configuracion> _configuraciones = [];
  Map<String, List<Configuracion>> _configuracionesPorCategoria = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarConfiguraciones();
  }

  Future<void> _cargarConfiguraciones() async {
    setState(() => _isLoading = true);
    
    try {
      final configs = await _supabaseService.obtenerConfiguraciones();
      
      setState(() {
        _configuraciones = configs;
        _agruparPorCategoria();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar configuraciones: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _agruparPorCategoria() {
    _configuracionesPorCategoria.clear();
    
    for (var config in _configuraciones) {
      if (!_configuracionesPorCategoria.containsKey(config.categoria)) {
        _configuracionesPorCategoria[config.categoria] = [];
      }
      _configuracionesPorCategoria[config.categoria]!.add(config);
    }
  }

  Future<void> _editarConfiguracion(Configuracion config) async {
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => _EditarConfigDialog(config: config),
    );

    if (resultado != null) {
      try {
        final configActualizada = Configuracion(
          id: config.id,
          clave: config.clave,
          valor: resultado,
          descripcion: config.descripcion,
          tipoDato: config.tipoDato,
          categoria: config.categoria,
          fechaModificacion: DateTime.now(),
        );

        await _supabaseService.actualizarConfiguracion(configActualizada);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuración actualizada')),
          );
          _cargarConfiguraciones();
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
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.indigo.shade500],
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.settings, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Configuración',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_configuraciones.length} configuraciones',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _configuraciones.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.settings_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay configuraciones',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarConfiguraciones,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _configuracionesPorCategoria.length,
                          itemBuilder: (context, index) {
                            final categoria = _configuracionesPorCategoria.keys.elementAt(index);
                            final configs = _configuracionesPorCategoria[categoria]!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index > 0) const SizedBox(height: 24),
                                // Header categoría
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.indigo.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.folder, size: 20, color: Colors.indigo.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        categoria.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Cards de configuración
                                ...configs.map((config) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _ConfigCard(
                                        config: config,
                                        onEdit: () => _editarConfiguracion(config),
                                      ),
                                    )),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ==================== CONFIG CARD ====================

class _ConfigCard extends StatelessWidget {
  final Configuracion config;
  final VoidCallback onEdit;

  const _ConfigCard({
    required this.config,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconoTipo;
    Color colorTipo;
    
    switch (config.tipoDato) {
      case 'boolean':
        iconoTipo = Icons.toggle_on;
        colorTipo = Colors.green;
        break;
      case 'integer':
      case 'decimal':
        iconoTipo = Icons.numbers;
        colorTipo = Colors.blue;
        break;
      case 'json':
        iconoTipo = Icons.data_object;
        colorTipo = Colors.purple;
        break;
      default:
        iconoTipo = Icons.text_fields;
        colorTipo = Colors.orange;
    }

    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorTipo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconoTipo, color: colorTipo, size: 20),
        ),
        title: Text(
          config.clave,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (config.descripcion?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                config.descripcion!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    config.tipoDato,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatearValor(config),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
          tooltip: 'Editar',
        ),
        isThreeLine: config.descripcion?.isNotEmpty == true,
      ),
    );
  }

  String _formatearValor(Configuracion config) {
    switch (config.tipoDato) {
      case 'boolean':
        return config.valorBoolean ? 'Activado' : 'Desactivado';
      case 'integer':
        return config.valorInt.toString();
      case 'decimal':
        return config.valorDecimal.toStringAsFixed(2);
      default:
        return config.valor;
    }
  }
}

// ==================== EDITAR CONFIG DIALOG ====================

class _EditarConfigDialog extends StatefulWidget {
  final Configuracion config;

  const _EditarConfigDialog({required this.config});

  @override
  State<_EditarConfigDialog> createState() => _EditarConfigDialogState();
}

class _EditarConfigDialogState extends State<_EditarConfigDialog> {
  late TextEditingController _controller;
  late bool _valorBoolean;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.config.valor);
    _valorBoolean = widget.config.valorBoolean;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar ${widget.config.clave}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.config.descripcion?.isNotEmpty == true) ...[
            Text(
              widget.config.descripcion!,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
          ],
          
          // Input según tipo de dato
          if (widget.config.tipoDato == 'boolean')
            SwitchListTile(
              title: const Text('Valor'),
              subtitle: Text(_valorBoolean ? 'Activado' : 'Desactivado'),
              value: _valorBoolean,
              onChanged: (v) => setState(() => _valorBoolean = v),
              contentPadding: EdgeInsets.zero,
            )
          else
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
              ),
              keyboardType: widget.config.tipoDato == 'integer' || widget.config.tipoDato == 'decimal'
                  ? TextInputType.number
                  : TextInputType.text,
              inputFormatters: widget.config.tipoDato == 'integer'
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : widget.config.tipoDato == 'decimal'
                      ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
                      : null,
              maxLines: widget.config.tipoDato == 'json' ? 5 : 1,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final nuevoValor = widget.config.tipoDato == 'boolean'
                ? _valorBoolean.toString()
                : _controller.text;
            Navigator.pop(context, nuevoValor);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}