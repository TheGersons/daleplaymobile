import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../models/cliente.dart';
import '../../models/plataforma.dart';
import '../../models/cuenta_correo.dart';
import '../../models/perfil.dart';
import '../../services/supabase_service.dart';
import 'crear_cliente_mini_dialog.dart';
import 'crear_cuenta_mini_dialog.dart';
import 'crear_perfil_mini_dialog.dart';

class SuscripcionRapidaDialog extends StatefulWidget {
  const SuscripcionRapidaDialog({super.key});

  @override
  State<SuscripcionRapidaDialog> createState() => _SuscripcionRapidaDialogState();
}

class _SuscripcionRapidaDialogState extends State<SuscripcionRapidaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  
  // Datos cargados
  List<Cliente> _clientes = [];
  List<Plataforma> _plataformas = [];
  List<CuentaCorreo> _cuentas = [];
  List<Perfil> _perfiles = [];
  
  // Listas filtradas
  List<CuentaCorreo> _cuentasFiltradas = [];
  List<Perfil> _perfilesFiltrados = [];
  
  // Selecciones
  Cliente? _clienteSeleccionado;
  Plataforma? _plataformaSeleccionada;
  CuentaCorreo? _cuentaSeleccionada;
  Perfil? _perfilSeleccionado;
  
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaVencimiento;
  double _precio = 0.0;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      final clientes = await _supabaseService.obtenerClientes();
      final plataformas = await _supabaseService.obtenerPlataformas();
      final cuentas = await _supabaseService.obtenerCuentas();
      final perfiles = await _supabaseService.obtenerPerfiles();
      
      setState(() {
        _clientes = clientes.where((c) => c.estado == 'activo').toList();
        _plataformas = plataformas.where((p) => p.estado == 'activa').toList();
        _cuentas = cuentas.where((c) => c.estado == 'activo').toList();
        _perfiles = perfiles;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onClienteChanged(Cliente? cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      _plataformaSeleccionada = null;
      _cuentaSeleccionada = null;
      _perfilSeleccionado = null;
      _cuentasFiltradas = [];
      _perfilesFiltrados = [];
      _precio = 0.0;
      _fechaVencimiento = null;
    });
  }

  void _onPlataformaChanged(Plataforma? plataforma) {
    setState(() {
      _plataformaSeleccionada = plataforma;
      _cuentaSeleccionada = null;
      _perfilSeleccionado = null;
      _perfilesFiltrados = [];
      
      if (plataforma != null) {
        _precio = plataforma.precioBase;
        _calcularFechaVencimiento();
        
        _cuentasFiltradas = _cuentas
            .where((c) => c.plataformaId == plataforma.id)
            .toList();
      } else {
        _cuentasFiltradas = [];
        _precio = 0.0;
        _fechaVencimiento = null;
      }
    });
  }

  void _onCuentaChanged(CuentaCorreo? cuenta) {
    setState(() {
      _cuentaSeleccionada = cuenta;
      _perfilSeleccionado = null;
      
      if (cuenta != null) {
        _perfilesFiltrados = _perfiles
            .where((p) => p.cuentaId == cuenta.id && p.estado == 'disponible')
            .toList();
      } else {
        _perfilesFiltrados = [];
      }
    });
  }

  void _onPerfilChanged(Perfil? perfil) {
    setState(() => _perfilSeleccionado = perfil);
  }

  void _calcularFechaVencimiento() {
    final siguienteMes = DateTime(
      _fechaInicio.year,
      _fechaInicio.month + 1,
      _fechaInicio.day,
    );
    
    setState(() => _fechaVencimiento = siguienteMes);
  }

  Future<void> _crearCliente() async {
    final cliente = await showDialog<Cliente>(
      context: context,
      builder: (context) => const CrearClienteMiniDialog(),
    );
    
    if (cliente != null) {
      setState(() {
        _clientes.add(cliente);
        _clienteSeleccionado = cliente;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente "${cliente.nombreCompleto}" creado')),
        );
      }
    }
  }

  Future<void> _crearCuenta() async {
    if (_plataformaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una plataforma primero')),
      );
      return;
    }
    
    final cuenta = await showDialog<CuentaCorreo>(
      context: context,
      builder: (context) => CrearCuentaMiniDialog(plataforma: _plataformaSeleccionada!),
    );
    
    if (cuenta != null) {
      setState(() {
        _cuentas.add(cuenta);
        _cuentasFiltradas.add(cuenta);
        _cuentaSeleccionada = cuenta;
      });
      
      _onCuentaChanged(cuenta);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cuenta "${cuenta.email}" creada')),
        );
      }
    }
  }

  Future<void> _crearPerfil() async {
    if (_cuentaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta primero')),
      );
      return;
    }
    
    final perfil = await showDialog<Perfil>(
      context: context,
      builder: (context) => CrearPerfilMiniDialog(cuenta: _cuentaSeleccionada!),
    );
    
    if (perfil != null) {
      setState(() {
        _perfiles.add(perfil);
        _perfilesFiltrados.add(perfil);
        _perfilSeleccionado = perfil;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Perfil "${perfil.nombrePerfil}" creado')),
        );
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_clienteSeleccionado == null) {
      _mostrarError('Selecciona un cliente');
      return;
    }
    if (_plataformaSeleccionada == null) {
      _mostrarError('Selecciona una plataforma');
      return;
    }
    if (_cuentaSeleccionada == null) {
      _mostrarError('Selecciona una cuenta');
      return;
    }
    if (_perfilSeleccionado == null) {
      _mostrarError('Selecciona un perfil');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _supabaseService.crearSuscripcionRapida(
        clienteId: _clienteSeleccionado!.id,
        perfilId: _perfilSeleccionado!.id,
        fechaInicio: _fechaInicio,
        precio: _precio,
        plataformaId: _plataformaSeleccionada!.id,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear suscripción: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Suscripción Rápida',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cliente
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownSearch<Cliente>(
                                    selectedItem: _clienteSeleccionado,
                                    items: _clientes,
                                    itemAsString: (Cliente c) => c.nombreCompleto,
                                    dropdownDecoratorProps: const DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        labelText: 'Cliente *',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.person),
                                      ),
                                    ),
                                    popupProps: PopupProps.menu(
                                      showSearchBox: true,
                                      searchFieldProps: const TextFieldProps(
                                        decoration: InputDecoration(
                                          hintText: 'Buscar por nombre o teléfono...',
                                          prefixIcon: Icon(Icons.search),
                                        ),
                                      ),
                                      itemBuilder: (context, item, isSelected) {
                                        return ListTile(
                                          title: Text(item.nombreCompleto),
                                          subtitle: Text(item.telefono),
                                          selected: isSelected,
                                        );
                                      },
                                      searchDelay: const Duration(milliseconds: 300),
                                      fit: FlexFit.loose,
                                      constraints: const BoxConstraints(maxHeight: 400),
                                    ),
                                    compareFn: (item1, item2) => item1.id == item2.id,
                                    filterFn: (item, filter) {
                                      final query = filter.toLowerCase().replaceAll('-', '');
                                      return item.nombreCompleto.toLowerCase().contains(query) ||
                                             item.telefono.replaceAll('-', '').contains(query);
                                    },
                                    onChanged: _isSaving ? null : _onClienteChanged,
                                    enabled: !_isSaving,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: _isSaving ? null : _crearCliente,
                                  icon: const Icon(Icons.add),
                                  tooltip: 'Nuevo Cliente',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Plataforma
                            DropdownButtonFormField<Plataforma>(
                              value: _plataformaSeleccionada,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Plataforma *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.tv),
                              ),
                              items: _plataformas.map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Color(int.parse(p.color.replaceFirst('#', '0xFF'))),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            p.nombre,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                              onChanged: _isSaving || _clienteSeleccionado == null ? null : _onPlataformaChanged,
                            ),
                            const SizedBox(height: 16),
                            
                            // Cuenta
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownSearch<CuentaCorreo>(
                                    selectedItem: _cuentaSeleccionada,
                                    items: _cuentasFiltradas,
                                    itemAsString: (CuentaCorreo c) => c.email,
                                    dropdownDecoratorProps: DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        labelText: 'Cuenta *',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.email),
                                        helperText: _cuentasFiltradas.isEmpty && _plataformaSeleccionada != null
                                            ? 'No hay cuentas, crea una'
                                            : null,
                                      ),
                                    ),
                                    popupProps: PopupProps.menu(
                                      showSearchBox: true,
                                      searchFieldProps: const TextFieldProps(
                                        decoration: InputDecoration(
                                          hintText: 'Buscar cuenta...',
                                          prefixIcon: Icon(Icons.search),
                                        ),
                                      ),
                                      emptyBuilder: (context, searchEntry) => const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Text('No hay cuentas disponibles'),
                                        ),
                                      ),
                                      searchDelay: const Duration(milliseconds: 300),
                                      fit: FlexFit.loose,
                                      constraints: const BoxConstraints(maxHeight: 400),
                                    ),
                                    compareFn: (item1, item2) => item1.id == item2.id,
                                    onChanged: _isSaving || _plataformaSeleccionada == null ? null : _onCuentaChanged,
                                    enabled: !_isSaving && _plataformaSeleccionada != null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: _isSaving || _plataformaSeleccionada == null ? null : _crearCuenta,
                                  icon: const Icon(Icons.add),
                                  tooltip: 'Nueva Cuenta',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Perfil
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownSearch<Perfil>(
                                    selectedItem: _perfilSeleccionado,
                                    items: _perfilesFiltrados,
                                    itemAsString: (Perfil p) => p.nombrePerfil,
                                    dropdownDecoratorProps: DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        labelText: 'Perfil *',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.person_outline),
                                        helperText: _perfilesFiltrados.isEmpty && _cuentaSeleccionada != null
                                            ? 'No hay perfiles disponibles, crea uno'
                                            : null,
                                      ),
                                    ),
                                    popupProps: PopupProps.menu(
                                      showSearchBox: true,
                                      searchFieldProps: const TextFieldProps(
                                        decoration: InputDecoration(
                                          hintText: 'Buscar perfil...',
                                          prefixIcon: Icon(Icons.search),
                                        ),
                                      ),
                                      itemBuilder: (context, item, isSelected) {
                                        return ListTile(
                                          title: Text(item.nombrePerfil),
                                          subtitle: Text('Disponible'),
                                          trailing: Icon(Icons.check_circle, color: Colors.green.shade300),
                                          selected: isSelected,
                                        );
                                      },
                                      emptyBuilder: (context, searchEntry) => const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Text('No hay perfiles disponibles'),
                                        ),
                                      ),
                                      searchDelay: const Duration(milliseconds: 300),
                                      fit: FlexFit.loose,
                                      constraints: const BoxConstraints(maxHeight: 400),
                                    ),
                                    compareFn: (item1, item2) => item1.id == item2.id,
                                    onChanged: _isSaving || _cuentaSeleccionada == null ? null : _onPerfilChanged,
                                    enabled: !_isSaving && _cuentaSeleccionada != null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: _isSaving || _cuentaSeleccionada == null ? null : _crearPerfil,
                                  icon: const Icon(Icons.add),
                                  tooltip: 'Nuevo Perfil',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Fecha Inicio
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Fecha de Inicio'),
                              subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaInicio)),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_calendar),
                                onPressed: _isSaving
                                    ? null
                                    : () async {
                                        final fecha = await showDatePicker(
                                          context: context,
                                          initialDate: _fechaInicio,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2030),
                                        );
                                        if (fecha != null) {
                                          setState(() {
                                            _fechaInicio = fecha;
                                            _calcularFechaVencimiento();
                                          });
                                        }
                                      },
                              ),
                            ),
                            
                            // Fecha Vencimiento
                            if (_fechaVencimiento != null) ...[
                              const Divider(),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.event_available),
                                title: const Text('Fecha de Vencimiento'),
                                subtitle: Text(
                                  DateFormat('dd/MM/yyyy').format(_fechaVencimiento!),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Auto-calculado',
                                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                                  ),
                                ),
                              ),
                            ],
                            
                            // Precio
                            if (_precio > 0) ...[
                              const Divider(),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.attach_money, color: Colors.green),
                                title: const Text('Precio Mensual'),
                                subtitle: Text(
                                  'L ${_precio.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'De plataforma',
                                    style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
            
            // Botones
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_clienteSeleccionado != null &&
                      _plataformaSeleccionada != null &&
                      _cuentaSeleccionada != null &&
                      _perfilSeleccionado != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '✓ Todo listo para crear la suscripción',
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _isSaving ||
                                  _clienteSeleccionado == null ||
                                  _plataformaSeleccionada == null ||
                                  _cuentaSeleccionada == null ||
                                  _perfilSeleccionado == null
                              ? null
                              : _guardar,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.flash_on),
                          label: Text(_isSaving ? 'Creando...' : 'Crear Suscripción'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
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
}