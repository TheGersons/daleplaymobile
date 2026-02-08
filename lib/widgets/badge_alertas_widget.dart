// Widget para mostrar badge de alertas en AppBar
// Usar en home_screen.dart o donde necesites

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alertas_provider.dart';
import '../screens/alertas/alertas_screen.dart';

class BadgeAlertas extends StatelessWidget {
  const BadgeAlertas({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertasProvider>(
      builder: (context, alertasProvider, child) {
        final count = alertasProvider.alertasPendientes;
        
        return Badge(
          label: Text('$count'),
          isLabelVisible: count > 0,
          backgroundColor: Colors.red,
          child: IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AlertasScreen(),
                ),
              );
            },
            tooltip: count > 0 
                ? '$count alerta${count > 1 ? 's' : ''} pendiente${count > 1 ? 's' : ''}'
                : 'Sin alertas',
          ),
        );
      },
    );
  }
}


// EJEMPLO DE USO EN AppBar:
/*
AppBar(
  title: const Text('DalePlay'),
  actions: [
    const BadgeAlertas(), // ← Agregar aquí
    const SizedBox(width: 8),
  ],
),
*/