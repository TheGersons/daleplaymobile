import 'dart:async';
import 'package:flutter/material.dart';
import '../models/suscripcion.dart';
import '../models/alerta.dart';
import '../services/supabase_service.dart';

class AlertasProvider extends ChangeNotifier {
  final _supabaseService = SupabaseService();

  List<Alerta> _alertas = [];
  Timer? _timer;

  int get alertasPendientes => _alertas
      .where((a) => a.estado == 'pendiente' || a.estado == 'enviada')
      .length;

  List<Alerta> get alertas => _alertas;

  // Iniciar monitoreo cada 1 minuto
  void iniciarMonitoreo() {
    // Verificar inmediatamente
    _verificarYCrearAlertas();

    // Luego cada 1 minuto
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _verificarYCrearAlertas();
    });
  }

  void detenerMonitoreo() {
    _timer?.cancel();
    _timer = null;
  }

  // REEMPLAZAR método _verificarYCrearAlertas() en alertas_provider.dart

  Future<void> _verificarYCrearAlertas() async {
    try {
      // 1. Obtener suscripciones activas
      final suscripciones = await _supabaseService.obtenerSuscripciones();
      final suscripcionesActivas = suscripciones
          .where((s) => s.estado == 'activa')
          .toList();

      final hoy = DateTime.now();

      for (final suscripcion in suscripcionesActivas) {
        final diasRestantes = suscripcion.fechaProximoPago
            .difference(DateTime(hoy.year, hoy.month, hoy.day))
            .inDays;

        String? nivel;
        String? mensaje;

        // Determinar nivel según días restantes
        if (diasRestantes == 1) {
          nivel = 'advertencia';
          mensaje = 'La suscripción vence mañana';
        } else if (diasRestantes == 0) {
          nivel = 'urgente';
          mensaje = 'La suscripción vence HOY';
        } else if (diasRestantes < 0) {
          nivel = 'critico';
          mensaje =
              'Suscripción vencida hace ${diasRestantes.abs()} día${diasRestantes.abs() > 1 ? 's' : ''}';
        }

        // Si hay nivel, verificar si ya existe alerta para ESTA suscripción
        if (nivel != null && mensaje != null) {
          final alertasExistentes = await _supabaseService.obtenerAlertas();

          // BUSCAR POR SUSCRIPCION_ID (no por entidad_id)
          final alertaExiste = alertasExistentes.any(
            (a) =>
                a.suscripcionId ==
                    suscripcion.id && // ← CLAVE: usar suscripcionId
                a.estado != 'resuelta',
          );

          // Solo crear si NO existe alerta sin resolver para esta suscripción
          if (!alertaExiste) {
            await _crearAlerta(
              suscripcion: suscripcion,
              nivel: nivel,
              diasRestantes: diasRestantes,
              mensaje: mensaje,
            );
          }
        }
      }
      print('Se verificaron las suscriciones y alertas a las ${DateTime.now()}');
      // Recargar alertas
      await cargarAlertas();
    } catch (e) {
      print('Error verificando alertas: $e');
    }
  }

  Future<void> _crearAlerta({
    required Suscripcion suscripcion,
    required String nivel,
    required int diasRestantes,
    required String mensaje,
  }) async {
    if(suscripcion.id == null || suscripcion.id!.isEmpty || suscripcion.id!.length < 5){
      print('Suscripción sin ID, no se puede crear alerta');
      return;
    }   
    try {
      await _supabaseService.crearAlerta(
        tipoAlerta: 'cobro_cliente',
        tipoEntidad: 'suscripcion',
        entidadId: suscripcion.id,
        clienteId: suscripcion.clienteId,
        plataformaId: suscripcion.plataformaId,
        suscripcionId: suscripcion.id, // ← AGREGAR ESTO
        nivel: nivel,
        diasRestantes: diasRestantes,
        monto: suscripcion.precio,
        mensaje: mensaje,
      );
    } catch (e) {
      print('Error creando alerta: $e');
    }
  }

  Future<void> cargarAlertas() async {
    try {
      _alertas = await _supabaseService.obtenerAlertas();

      // Solo mostrar pendientes y enviadas
      _alertas = _alertas
          .where((a) => a.estado == 'pendiente' || a.estado == 'enviada')
          .toList();

      notifyListeners();
    } catch (e) {
      print('Error cargando alertas: $e');
    }
  }

  Future<void> marcarComoLeida(String alertaId) async {
    try {
      await _supabaseService.marcarAlertaComoLeida(alertaId);
      await cargarAlertas();
    } catch (e) {
      print('Error marcando alerta: $e');
    }
  }

  Future<void> resolver(String alertaId) async {
    try {
      await _supabaseService.marcarAlertaComoResuelta(alertaId);
      await cargarAlertas();
    } catch (e) {
      print('Error resolviendo alerta: $e');
    }
  }

  @override
  void dispose() {
    detenerMonitoreo();
    super.dispose();
  }
}
