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
    _configuracionesPorCategoria = {};
    for (var config in _configuraciones) {
      if (!_configuracionesPorCategoria.containsKey(config.categoria)) {
        _configuracionesPorCategoria[config.categoria] = [];
      }
      _configuracionesPorCategoria[config.categoria]!.add(config);
    }
  }

  Future<void> _actualizarConfiguracion(Configuracion config, String nuevoValor) async {
    try {
      // Optimistic update
      setState(() {
        final index = _configuraciones.indexWhere((c) => c.id == config.id);
        if (index != -1) {
          //_configuraciones[index] = config.copyWith(valor: nuevoValor);
          _agruparPorCategoria();
        }
      });

     // await _supabaseService.actualizarConfiguracion(config.id, nuevoValor);
      
    } catch (e) {
      // Revertir si falla
      await _cargarConfiguraciones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos un color base "Sistema" para las tarjetas de configuración
    // ya que no pertenecen a una plataforma específica.
    final systemColor = Colors.blueGrey;

    return Scaffold(
      // Asumimos que el fondo general de la app ya es oscuro, 
      // si no, descomenta la siguiente línea:
      // backgroundColor: const Color(0xFF1E1E1E), 
      appBar: AppBar(
        title: const Text('Configuración', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _configuracionesPorCategoria.length,
              itemBuilder: (context, index) {
                final categoria = _configuracionesPorCategoria.keys.elementAt(index);
                final configs = _configuracionesPorCategoria[categoria]!;
                
                return _buildCategoriaSection(categoria, configs, systemColor);
              },
            ),
    );
  }

  Widget _buildCategoriaSection(String categoria, List<Configuracion> configs, Color baseColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
          child: Text(
            categoria.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Color claro para el título
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          // ESTILO: Fondo semitransparente oscuro
          color: baseColor.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            // Opcional: Borde sutil
            side: BorderSide(color: baseColor.withOpacity(0.2)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: configs.length,
            separatorBuilder: (context, index) => Divider(
              height: 1, 
              color: Colors.white.withOpacity(0.1) // Separador sutil
            ),
            itemBuilder: (context, index) {
              return _buildConfigItem(configs[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfigItem(Configuracion config) {
    final bool esBooleano = config.tipoDato == 'boolean';
    final bool valorBooleano = config.valor.toLowerCase() == 'true';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        config.clave,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white, // Texto blanco
        ),
      ),
      subtitle: config.descripcion != null
          ? Text(
              config.descripcion!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6), // Subtítulo gris claro
              ),
            )
          : null,
      trailing: esBooleano
          ? Switch(
              value: valorBooleano,
              onChanged: (value) => _actualizarConfiguracion(config, value.toString()),
              activeColor: Colors.white,
              activeTrackColor: Colors.green.shade400,
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.white10,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    config.valor,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5), size: 20),
              ],
            ),
      onTap: esBooleano
          ? () => _actualizarConfiguracion(config, (!valorBooleano).toString())
          : () => _mostrarDialogoEdicion(config),
    );
  }

  Future<void> _mostrarDialogoEdicion(Configuracion config) async {
    final nuevoValor = await showDialog<String>(
      context: context,
      builder: (context) => _EditarConfigDialog(config: config),
    );

    if (nuevoValor != null && nuevoValor != config.valor) {
      _actualizarConfiguracion(config, nuevoValor);
    }
  }
}

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
    _valorBoolean = widget.config.valor.toLowerCase() == 'true';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definimos un tema oscuro local para el diálogo si es necesario,
    // o usamos estilos directos.
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2C), // Fondo oscuro para el diálogo
      title: Text(
        'Editar ${widget.config.clave}',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.config.descripcion != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.config.descripcion!,
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ),
          
          if (widget.config.tipoDato == 'boolean')
            SwitchListTile(
              title: Text(
                _valorBoolean ? 'Activado' : 'Desactivado',
                style: const TextStyle(color: Colors.white),
              ),
              value: _valorBoolean,
              onChanged: (v) => setState(() => _valorBoolean = v),
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.green.shade400,
            )
          else
            TextFormField(
              controller: _controller,
              style: const TextStyle(color: Colors.white), // Texto input blanco
              decoration: InputDecoration(
                labelText: 'Valor',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                border: const OutlineInputBorder(),
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
          style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final nuevoValor = widget.config.tipoDato == 'boolean'
                ? _valorBoolean.toString()
                : _controller.text;
            Navigator.pop(context, nuevoValor);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}