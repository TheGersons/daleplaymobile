import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../perfiles/perfiles_screen.dart';
import '../pagos/gestion_pagos_clientes_screen.dart';
import '../reportes/reportes_screen.dart';
import '../plataformas/plataformas_screen.dart';
import '../cuentas/cuentas_screen.dart';
import '../clientes/clientes_screen.dart';
import '../suscripciones/suscripciones_screen.dart';
import '../pagos/pagos_plataforma_screen.dart';
import '../alertas/alertas_screen.dart';
import '../usuarios/usuarios_screen.dart';
import '../configuracion/configuracion_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    // --- Del 0 al 4 (Bottom Navigation Bar) ---
    const DashboardScreen(),            // 0
    const PerfilesScreen(),             // 1
    const SizedBox.shrink(),            // 2 (Espacio del botón central FAB)
    const GestionPagosClientesScreen(), // 3
    const ReportesScreen(),             // 4
    
    // --- Del 5 en adelante (Solo accesibles desde el Drawer) ---
    const PlataformasScreen(),          // 5
    const CuentasScreen(),              // 6
    const ClientesScreen(),             // 7
    const SuscripcionesScreen(),        // 8
    const AlertasScreen(),              // 9
    const UsuariosScreen(),             // 10
    const ConfiguracionScreen(),        // 11
  ];
  final List<String> _titles = [
    'Dashboard', 'Perfiles', '', 'Cobros', 'Reportes',
    'Plataformas', 'Cuentas', 'Clientes', 'Suscripciones', 'Alertas', 'Usuarios', 'Configuración'
  ];

  void _onItemTapped(int index) {
    if (index == 2) return; // Ignorar tap en FAB placeholder
    setState(() => _selectedIndex = index);
  }

  void _crearSuscripcionRapida() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Crear Suscripción Rápida - Próximamente'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).clearUser();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    int bottomNavIndex = _selectedIndex > 4 ? 0 : _selectedIndex;
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
        actions: [
          // Usuario info
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user?.nombreCompleto ?? 'Usuario',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.isAdmin == true ? 'Administrador' : 'Vendedor',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user?.nombreCompleto.isNotEmpty == true
                    ? user!.nombreCompleto[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, userProvider),
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _crearSuscripcionRapida,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex == 2 ? 0 : _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfiles',
          ),
          NavigationDestination(
            icon: SizedBox(width: 48), // Espacio para FAB
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Cobros',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Perfiles';
      case 3:
        return 'Gestión de Cobros';
      case 4:
        return 'Reportes';
      default:
        return 'DalePlay';
    }
  }

  Widget _buildDrawer(BuildContext context, UserProvider userProvider) {
    final user = userProvider.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.nombreCompleto.isNotEmpty == true
                    ? user!.nombreCompleto[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            accountName: Text(
              user?.nombreCompleto ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? ''),
          ),

          // Gestión
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'GESTIÓN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.tv,
            title: 'Plataformas',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlataformasScreen()),
              );
            },
          ),
          _buildDrawerTile(
            context,
            icon: Icons.email,
            title: 'Cuentas',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CuentasScreen()),
              );
            },
          ),
          _buildDrawerTile(
            context,
            icon: Icons.people,
            title: 'Clientes',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientesScreen()),
              );
            },
          ),
          _buildDrawerTile(
            context,
            icon: Icons.subscriptions,
            title: 'Suscripciones',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuscripcionesScreen()),
              );
            },
          ),

          const Divider(),

          // Pagos y Alertas
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'OPERACIONES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.credit_card,
            title: 'Pagos a Proveedores',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PagosPlataformaScreen()),
              );
            },
          ),
          _buildDrawerTile(
            context,
            icon: Icons.notifications,
            title: 'Alertas',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertasScreen()),
              );
            },
          ),

          const Divider(),

          // Sistema (solo admin)
          if (userProvider.isAdmin) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'SISTEMA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            _buildDrawerTile(
              context,
              icon: Icons.people_outline,
              title: 'Usuarios',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                );
              },
            ),
            _buildDrawerTile(
              context,
              icon: Icons.settings,
              title: 'Configuración',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
                );
              },
            ),
            const Divider(),
          ],

          // Cerrar Sesión
          _buildDrawerTile(
            context,
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            onTap: _logout,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      onTap: onTap,
    );
  }
}