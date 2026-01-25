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
  Widget _currentScreen = const DashboardScreen();
  String _currentTitle = 'Inicio';

  // Páginas del bottom nav
  void _onBottomNavTapped(int index) {
    if (index == 2) return; // Ignorar placeholder del FAB

    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          _currentScreen = const DashboardScreen();
          _currentTitle = 'Inicio';
          break;
        case 1:
          _currentScreen = const PerfilesScreen();
          _currentTitle = 'Perfiles';
          break;
        case 3:
          _currentScreen = const GestionPagosClientesScreen();
          _currentTitle = 'Gestión de Cobros';
          break;
        case 4:
          _currentScreen = const ReportesScreen();
          _currentTitle = 'Reportes';
          break;
      }
    });
  }

  // Navegación desde drawer
  void _navigateToScreen(Widget screen, String title, {int? bottomNavIndex}) {
    Navigator.pop(context); // Cerrar drawer
    setState(() {
      _currentScreen = screen;
      _currentTitle = title;
      _selectedIndex = bottomNavIndex ?? -1;
    });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
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
      body: _currentScreen,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 80.0),
        child: FloatingActionButton(
          onPressed: _crearSuscripcionRapida,
          elevation: 4,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex >= 0 ? _selectedIndex : 0,
        onDestinationSelected: _onBottomNavTapped,
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
            icon: SizedBox(width: 48),
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

          // Inicio (bottom nav)
          _buildDrawerTile(
            context,
            icon: Icons.home,
            title: 'Inicio',
            onTap: () => _navigateToScreen(
              const DashboardScreen(),
              'Inicio',
              bottomNavIndex: 0,
            ),
          ),

          const Divider(),

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
            onTap: () => _navigateToScreen(
              const PlataformasScreen(),
              'Plataformas',
            ),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.email,
            title: 'Cuentas',
            onTap: () => _navigateToScreen(
              const CuentasScreen(),
              'Cuentas',
            ),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.person,
            title: 'Perfiles',
            onTap: () => _navigateToScreen(
              const PerfilesScreen(),
              'Perfiles',
              bottomNavIndex: 1,
            ),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.people,
            title: 'Clientes',
            onTap: () => _navigateToScreen(
              const ClientesScreen(),
              'Clientes',
            ),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.subscriptions,
            title: 'Suscripciones',
            onTap: () => _navigateToScreen(
              const SuscripcionesScreen(),
              'Suscripciones',
            ),
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
            icon: Icons.payments,
            title: 'Gestión de Cobros',
            onTap: () => _navigateToScreen(
              const GestionPagosClientesScreen(),
              'Gestión de Cobros',
              bottomNavIndex: 3,
            ),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.credit_card,
            title: 'Pagos a Proveedores',
            onTap: () => _navigateToScreen(
              const PagosPlataformaScreen(),
              'Pagos a Proveedores',
            ),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.notifications,
            title: 'Alertas',
            onTap: () => _navigateToScreen(
              const AlertasScreen(),
              'Alertas',
            ),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.bar_chart,
            title: 'Reportes',
            onTap: () => _navigateToScreen(
              const ReportesScreen(),
              'Reportes',
              bottomNavIndex: 4,
            ),
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
              onTap: () => _navigateToScreen(
                const UsuariosScreen(),
                'Usuarios',
              ),
            ),
            _buildDrawerTile(
              context,
              icon: Icons.settings,
              title: 'Configuración',
              onTap: () => _navigateToScreen(
                const ConfiguracionScreen(),
                'Configuración',
              ),
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