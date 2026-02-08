import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/plataforma.dart';
import '../../services/supabase_service.dart';

class PlataformasScreen extends StatefulWidget {
  const PlataformasScreen({super.key});

  @override
  State<PlataformasScreen> createState() => _PlataformasScreenState();
}

class _PlataformasScreenState extends State<PlataformasScreen> {
  final _supabaseService = SupabaseService();
  List<Plataforma> _plataformas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPlataformas();
  }

  Future<void> _cargarPlataformas() async {
    setState(() => _isLoading = true);

    try {
      final plataformas = await _supabaseService.obtenerPlataformas();
      setState(() => _plataformas = plataformas);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar plataformas: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoPlataforma([Plataforma? plataforma]) {
    showDialog(
      context: context,
      builder: (context) => PlataformaDialog(
        plataforma: plataforma,
        onGuardar: () {
          Navigator.pop(context);
          _cargarPlataformas();
        },
      ),
    );
  }

  Future<void> _eliminarPlataforma(Plataforma plataforma) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Plataforma'),
        content: Text(
          '¿Estás seguro de eliminar "${plataforma.nombre}"?\n\n'
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
        await _supabaseService.eliminarPlataforma(plataforma.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Plataforma eliminada')));
          _cargarPlataformas();
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
      //espacio para que no este pegada la primera card al appbar
      appBar: AppBar(
        title: const Text('Mis Plataformas'),
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _plataformas.isEmpty
            ? Center(
                //dejar un espacio entre el icono y el appbar
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 800),
                    Icon(Icons.tv_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay plataformas registradas',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agrega tu primera plataforma',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _cargarPlataformas,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _plataformas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final plataforma = _plataformas[index];
                    return _buildPlataformaCard(plataforma);
                  },
                ),
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: FloatingActionButton.extended(
          heroTag: "fab_plataformas",
          onPressed: () => _mostrarDialogoPlataforma(),
          icon: const Icon(Icons.add),
          label: const Text('Nueva Plataforma'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPlataformaCard(Plataforma plataforma) {
    final colorPlataforma = Color(
      int.parse(plataforma.color.replaceFirst('#', '0xFF')),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _mostrarDialogoPlataforma(plataforma),
        child: Column(
          children: [
            // Header con color
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorPlataforma,
                gradient: LinearGradient(
                  colors: [colorPlataforma, colorPlataforma.withOpacity(0.8)],
                ),
              ),
              child: Row(
                children: [
                  _buildLogo(plataforma),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plataforma.nombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plataforma.estado == 'activa' ? 'Activa' : 'Inactiva',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Detalles
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Precio Base',
                          'L ${plataforma.precioBase.toStringAsFixed(2)}',
                          Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          'Max Perfiles',
                          '${plataforma.maxPerfiles}',
                          Icons.people,
                        ),
                      ),
                    ],
                  ),
                  if (plataforma.notas?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        plataforma.notas!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _mostrarDialogoPlataforma(plataforma),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _eliminarPlataforma(plataforma),
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
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) =>
              const FaIcon(FontAwesomeIcons.tv, size: 24, color: Colors.grey),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const FaIcon(FontAwesomeIcons.tv, size: 24, color: Colors.grey),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ==================== DIALOG ====================

class PlataformaDialog extends StatefulWidget {
  final Plataforma? plataforma;
  final VoidCallback onGuardar;

  const PlataformaDialog({super.key, this.plataforma, required this.onGuardar});

  @override
  State<PlataformaDialog> createState() => _PlataformaDialogState();
}

class _PlataformaDialogState extends State<PlataformaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _maxPerfilesController;
  late TextEditingController _notasController;
  late TextEditingController _precioCompletaController;

  String _colorSeleccionado = '#2196F3';
  String _estadoSeleccionado = 'activa';
  bool _isLoading = false;

  final List<String> _coloresDisponibles = [
    '#2196F3', // Azul
    '#E50914', // Rojo Netflix
    '#00D9FF', // Azul Disney
    '#9C27B0', // Morado HBO
    '#1DB954', // Verde Spotify
    '#FF9800', // Naranja
    '#F44336', // Rojo
    '#4CAF50', // Verde
    '#FFC107', // Amarillo
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.plataforma;
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _precioController = TextEditingController(
      text: p?.precioBase.toString() ?? '',
    );
    _maxPerfilesController = TextEditingController(
      text: p?.maxPerfiles.toString() ?? '4',
    );
    _notasController = TextEditingController(text: p?.notas ?? '');
    _precioCompletaController = TextEditingController(
      text: p?.precioCompleta?.toString() ?? '',
    );
    _colorSeleccionado = p?.color ?? '#2196F3';
    _estadoSeleccionado = p?.estado ?? 'activa';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _maxPerfilesController.dispose();
    _notasController.dispose();
    _precioCompletaController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final plataforma = Plataforma(
        id: widget.plataforma?.id ?? '',
        nombre: _nombreController.text.trim(),
        icono: 'Television',
        precioBase: double.parse(_precioController.text),
        maxPerfiles: int.parse(_maxPerfilesController.text),
        color: _colorSeleccionado,
        estado: _estadoSeleccionado,
        fechaCreacion: widget.plataforma?.fechaCreacion ?? DateTime.now(),
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
        precioCompleta: _precioCompletaController.text.isEmpty
            ? null
            : int.tryParse(_precioCompletaController.text),
      );

      if (widget.plataforma == null) {
        await _supabaseService.crearPlataforma(plataforma);
      } else {
        await _supabaseService.actualizarPlataforma(plataforma);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.plataforma == null
                  ? 'Plataforma creada'
                  : 'Plataforma actualizada',
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
                color: Color(
                  int.parse(_colorSeleccionado.replaceFirst('#', '0xFF')),
                ),
              ),
              child: Text(
                widget.plataforma == null
                    ? 'Nueva Plataforma'
                    : 'Editar Plataforma',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tv),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Campo requerido' : null,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _precioController,
                        decoration: const InputDecoration(
                          labelText: 'Precio Base *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          helperText: 'Precio por perfil',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Campo requerido';
                          if (double.tryParse(v!) == null) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maxPerfilesController,
                        decoration: const InputDecoration(
                          labelText: 'Máximo de Perfiles *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Campo requerido';
                          if (int.tryParse(v!) == null) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _precioCompletaController,
                        decoration: const InputDecoration(
                          labelText: 'Precio Cuenta Completa',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                          helperText: 'Opcional',
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      // Color
                      const Text(
                        'Color',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _coloresDisponibles.map((color) {
                          final isSelected = color == _colorSeleccionado;
                          return InkWell(
                            onTap: _isLoading
                                ? null
                                : () => setState(
                                    () => _colorSeleccionado = color,
                                  ),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(color.replaceFirst('#', '0xFF')),
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
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
                            value: 'inactiva',
                            child: Text('Inactiva'),
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
