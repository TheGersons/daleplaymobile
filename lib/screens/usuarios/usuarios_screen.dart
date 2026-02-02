import 'package:flutter/material.dart';
import '../../models/auth_user.dart';
import '../../services/supabase_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<AuthUser> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final usuarios = await _supabaseService.obtenerUsuarios();
      if (mounted) {
        setState(() {
          _usuarios = usuarios;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarUsuario(AuthUser usuario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de eliminar a "${usuario.nombreCompleto}"?\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
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
        await _supabaseService.eliminarUsuario(usuario.id);
        _cargarUsuarios();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario eliminado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _mostrarDialogo({AuthUser? usuario}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UsuarioDialog(
        usuario: usuario,
        onGuardar: () {
          Navigator.pop(ctx);
          _cargarUsuarios();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarUsuarios,
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay usuarios registrados',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _usuarios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildUsuarioCard(_usuarios[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogo(),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Usuario'),
      ),
    );
  }

  Widget _buildUsuarioCard(AuthUser usuario) {
    final isAdmin = usuario.rol == 'admin';
    final isActive = usuario.estado == 'activo';
    
    // Configuración de Colores y Estilos
    final cardColor = isAdmin 
        ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3) // Azulado sutil o gris destacado
        : Theme.of(context).colorScheme.surface; // Color estándar del tema

    final borderColor = isAdmin 
        ? Colors.blue.withOpacity(0.3) 
        : Colors.grey.withOpacity(0.2);

    final iconColor = isAdmin ? Colors.blueAccent : Colors.orangeAccent;
    final iconBgColor = isAdmin ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1);

    return Card(
      elevation: 0, // Flat design se ve mejor en listas complejas
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar con Icono Grande
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // Info Principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nombreCompleto,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      // Usar onSurface para asegurar contraste correcto en Dark/Light
                      color: Theme.of(context).colorScheme.onSurface, 
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          usuario.email,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500, // Un poco más grueso
                            // Color con más contraste
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), 
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Badges: Rol y Estado (Con colores fuertes para resaltar)
                  Row(
                    children: [
                      _buildBadge(
                        text: isAdmin ? 'ADMINISTRADOR' : 'VENDEDOR',
                        color: isAdmin ? Colors.blue : Colors.orange,
                        isOutlined: false, // Relleno sólido suave
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        text: isActive ? 'ACTIVO' : 'INACTIVO',
                        color: isActive ? Colors.green : Colors.red,
                        isOutlined: true, // Solo borde para estado
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => _mostrarDialogo(usuario: usuario),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () => _eliminarUsuario(usuario),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String text, 
    required MaterialColor color, 
    bool isOutlined = false
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOutlined ? color : Colors.transparent, 
          width: 1
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          // El texto siempre toma el color fuerte
          color: isOutlined ? color : color[700], 
        ),
      ),
    );
  }
}

// ==================== DIALOGO CREAR/EDITAR ====================

class UsuarioDialog extends StatefulWidget {
  final AuthUser? usuario;
  final VoidCallback onGuardar;

  const UsuarioDialog({
    super.key,
    this.usuario,
    required this.onGuardar,
  });

  @override
  State<UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends State<UsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  String _rolSeleccionado = 'vendedor';
  String _estadoSeleccionado = 'activo';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombreController = TextEditingController(text: u?.nombreCompleto ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _passwordController = TextEditingController(); 
    
    _rolSeleccionado = u?.rol ?? 'vendedor';
    _estadoSeleccionado = u?.estado ?? 'activo';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final esNuevo = widget.usuario == null;
      
      final usuarioData = AuthUser(
        id: widget.usuario?.id ?? '', 
        email: _emailController.text.trim().toLowerCase(),
        nombreCompleto: _nombreController.text.trim(),
        rol: _rolSeleccionado,
        estado: _estadoSeleccionado,
        fechaCreacion: widget.usuario?.fechaCreacion ?? DateTime.now(),
        fechaUltimoAcceso: widget.usuario?.fechaUltimoAcceso,
        passwordHash: '', 
      );

      if (esNuevo) {
        await _supabaseService.crearUsuario(usuarioData, _passwordController.text);
      } else {
        final newPass = _passwordController.text.isNotEmpty ? _passwordController.text : null;
        await _supabaseService.actualizarUsuario(usuarioData, newPassword: newPass);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(esNuevo ? 'Usuario creado' : 'Usuario actualizado')),
        );
        widget.onGuardar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esNuevo = widget.usuario == null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(esNuevo ? Icons.person_add : Icons.edit, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      esNuevo ? 'Nuevo Usuario' : 'Editar Usuario',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
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
                    if (v!.isEmpty) return 'Requerido';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: esNuevo ? 'Contraseña *' : 'Nueva Contraseña (Opcional)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    helperText: esNuevo ? 'Mínimo 6 caracteres' : 'Dejar en blanco para mantener la actual',
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (esNuevo && (v == null || v.isEmpty)) return 'Requerido para nuevos usuarios';
                    if (v != null && v.isNotEmpty && v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.security),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  ],
                  onChanged: (v) => setState(() => _rolSeleccionado = v!),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _estadoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.toggle_on),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'activo', child: Text('Activo')),
                    DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                  ],
                  onChanged: (v) => setState(() => _estadoSeleccionado = v!),
                ),
                const SizedBox(height: 24),

                Row(
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
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}