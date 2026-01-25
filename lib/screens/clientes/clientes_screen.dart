import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/cliente.dart';
import '../../services/supabase_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _supabaseService = SupabaseService();
  List<Cliente> _clientes = [];
  List<Cliente> _clientesFiltrados = [];
  bool _isLoading = true;
  String _filtroEstado = 'todos';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    setState(() => _isLoading = true);
    
    try {
      final clientes = await _supabaseService.obtenerClientes();
      setState(() {
        _clientes = clientes;
        _aplicarFiltros();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _aplicarFiltros() {
    var filtrados = _clientes;

    // Filtro por estado
    if (_filtroEstado != 'todos') {
      filtrados = filtrados.where((c) => c.estado == _filtroEstado).toList();
    }

    // Filtro por búsqueda
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtrados = filtrados.where((c) =>
        c.nombreCompleto.toLowerCase().contains(query) ||
        c.telefono.contains(query)
      ).toList();
    }

    setState(() => _clientesFiltrados = filtrados);
  }

  void _mostrarDialogoCliente([Cliente? cliente]) {
    showDialog(
      context: context,
      builder: (context) => ClienteDialog(
        cliente: cliente,
        onGuardar: () {
          Navigator.pop(context);
          _cargarClientes();
        },
      ),
    );
  }

  Future<void> _eliminarCliente(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text(
          '¿Estás seguro de eliminar a "${cliente.nombreCompleto}"?\n\n'
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
        await _supabaseService.eliminarCliente(cliente.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente eliminado')),
          );
          _cargarClientes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
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
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o teléfono...',
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
                const SizedBox(height: 12),
                // Filtros
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'todos',
                            label: Text('Todos'),
                            icon: Icon(Icons.people, size: 16),
                          ),
                          ButtonSegment(
                            value: 'activo',
                            label: Text('Activos'),
                            icon: Icon(Icons.check_circle, size: 16),
                          ),
                          ButtonSegment(
                            value: 'inactivo',
                            label: Text('Inactivos'),
                            icon: Icon(Icons.cancel, size: 16),
                          ),
                        ],
                        selected: {_filtroEstado},
                        onSelectionChanged: (Set<String> selection) {
                          setState(() {
                            _filtroEstado = selection.first;
                            _aplicarFiltros();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _clientesFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _clientes.isEmpty
                                  ? 'No hay clientes registrados'
                                  : 'No se encontraron clientes',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _clientes.isEmpty
                                  ? 'Agrega tu primer cliente'
                                  : 'Intenta con otro filtro',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarClientes,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _clientesFiltrados.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final cliente = _clientesFiltrados[index];
                            return _buildClienteCard(cliente);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCliente(),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildClienteCard(Cliente cliente) {
    final isActivo = cliente.estado == 'activo';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _mostrarDialogoCliente(cliente),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isActivo
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    child: Text(
                      cliente.nombreCompleto.isNotEmpty
                          ? cliente.nombreCompleto[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cliente.telefono,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActivo ? Colors.green[50] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActivo ? Colors.green : Colors.grey,
                      ),
                    ),
                    child: Text(
                      isActivo ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActivo ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              if (cliente.notas?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cliente.notas!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _mostrarDialogoCliente(cliente),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _eliminarCliente(cliente),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Eliminar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== DIALOG ====================

class ClienteDialog extends StatefulWidget {
  final Cliente? cliente;
  final VoidCallback onGuardar;

  const ClienteDialog({
    super.key,
    this.cliente,
    required this.onGuardar,
  });

  @override
  State<ClienteDialog> createState() => _ClienteDialogState();
}

class _ClienteDialogState extends State<ClienteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _notasController;
  
  String _estadoSeleccionado = 'activo';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nombreController = TextEditingController(text: c?.nombreCompleto ?? '');
    _telefonoController = TextEditingController(text: c?.telefono ?? '');
    _notasController = TextEditingController(text: c?.notas ?? '');
    _estadoSeleccionado = c?.estado ?? 'activo';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cliente = Cliente(
        id: widget.cliente?.id ?? '',
        nombreCompleto: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        estado: _estadoSeleccionado,
        fechaRegistro: widget.cliente?.fechaRegistro ?? DateTime.now(),
        notas: _notasController.text.trim().isEmpty 
            ? null 
            : _notasController.text.trim(),
      );

      if (widget.cliente == null) {
        await _supabaseService.crearCliente(cliente);
      } else {
        await _supabaseService.actualizarCliente(cliente);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.cliente == null
                  ? 'Cliente creado'
                  : 'Cliente actualizado',
            ),
          ),
        );
        widget.onGuardar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    Icons.person,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente',
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
            Flexible(
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
                          labelText: 'Nombre Completo *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Campo requerido' : null,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                          helperText: 'Formato: 9999-9999 o 8 dígitos',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Campo requerido';
                          if (v!.length < 8) {
                            return 'Debe tener 8 dígitos';
                          }
                          return null;
                        },
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
                            child: Text('Activo'),
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