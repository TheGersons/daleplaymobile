// ============================================
// utils/date_utils.dart
// Utilidad global para manejo de fechas
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FechaUtils {
  /// Calcular días restantes entre fechas (solo compara fechas, ignora horas)
  static int diasRestantes(DateTime fechaVencimiento) {
    final hoy = DateTime.now();
    final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);
    final vencimientoSoloFecha = DateTime(
      fechaVencimiento.year,
      fechaVencimiento.month,
      fechaVencimiento.day,
    );

    return vencimientoSoloFecha.difference(hoySoloFecha).inDays;
  }

  /// Obtener fecha sin hora (solo año, mes, día)
  static DateTime soloFecha(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  /// Verificar si una fecha es hoy
  static bool esHoy(DateTime fecha) {
    return diasRestantes(fecha) == 0;
  }

  /// Verificar si una fecha es mañana
  static bool esManana(DateTime fecha) {
    return diasRestantes(fecha) == 1;
  }

  /// Verificar si una fecha es ayer
  static bool esAyer(DateTime fecha) {
    return diasRestantes(fecha) == -1;
  }

  /// Verificar si una fecha ya pasó (sin contar hoy)
  static bool yaVencio(DateTime fecha) {
    return diasRestantes(fecha) < 0;
  }

  /// Formatear fecha según días restantes
  static String formatearSegunDias(DateTime fecha) {
    final dias = diasRestantes(fecha);

    if (dias < 0) {
      return 'Vencida hace ${dias.abs()} día(s)';
    } else if (dias == 0) {
      return 'Vence HOY';
    } else if (dias == 1) {
      return 'Vence MAÑANA';
    } else if (dias <= 7) {
      return 'Faltan $dias días';
    } else {
      return DateFormat('dd/MM/yyyy').format(fecha);
    }
  }

  /// Color según días restantes
  static ColorEstado colorSegunDias(DateTime fecha) {
    final dias = diasRestantes(fecha);

    if (dias < 0) return ColorEstado.vencida;
    if (dias == 0) return ColorEstado.hoy;
    if (dias == 1) return ColorEstado.manana;
    if (dias <= 3) return ColorEstado.proximo;
    return ColorEstado.normal;
  }

  /// Comparar si dos fechas son el mismo día
  static bool mismaFecha(DateTime fecha1, DateTime fecha2) {
    return fecha1.year == fecha2.year &&
        fecha1.month == fecha2.month &&
        fecha1.day == fecha2.day;
  }

  /// Obtener fecha en formato ISO para Supabase (solo fecha, sin hora)
  static String toIsoDate(DateTime fecha) {
    return fecha.toIso8601String().split('T')[0];
  }

  /// Parsear fecha desde string ISO
  static DateTime fromIsoDate(String fechaStr) {
    return DateTime.parse(fechaStr);
  }
}

/// Enum para colores según estado de vencimiento
enum ColorEstado {
  vencida, // Rojo oscuro
  hoy, // Rojo
  manana, // Naranja
  proximo, // Azul
  normal, // Verde
}

/// Extensión para obtener el Color desde ColorEstado
extension ColorEstadoExtension on ColorEstado {
  Color get color {
    switch (this) {
      case ColorEstado.vencida:
        return Colors.red[900]!;
      case ColorEstado.hoy:
        return Colors.red;
      case ColorEstado.manana:
        return Colors.orange;
      case ColorEstado.proximo:
        return Colors.blue;
      case ColorEstado.normal:
        return Colors.green;
    }
  }
}
