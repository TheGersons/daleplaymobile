import 'package:daleplay/models/alerta.dart';
import 'package:daleplay/models/configuracion.dart';
import 'package:daleplay/models/pago.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:dbcrypt/dbcrypt.dart';
import '../models/auth_user.dart';
import '../models/plataforma.dart';
import '../models/cliente.dart';
import '../models/suscripcion.dart';
import '../models/perfil.dart';
import '../models/cuenta_correo.dart';
import '../models/pago_plataforma.dart';
import '../models/historial_pago_plataforma.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // ==================== AUTH ====================

  Future<AuthUser?> login(String email, String password) async {
    try {
      final response = await _client
          .from('auth_users')
          .select()
          .eq('email', email.toLowerCase())
          .eq('estado', 'activo')
          .maybeSingle();

      if (response == null) return null;

      final user = AuthUser.fromJson(response);

      // Verificar contraseña con BCrypt
      final dBCrypt = DBCrypt();
      if (!dBCrypt.checkpw(password, user.passwordHash)) {
        return null;
      }

      // Actualizar último acceso
      await _client
          .from('auth_users')
          .update({'fecha_ultimo_acceso': DateTime.now().toIso8601String()})
          .eq('id', user.id);

      return user;
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  // ==================== PLATAFORMAS ====================

  Future<List<Plataforma>> obtenerPlataformas() async {
    try {
      final response = await _client
          .from('plataformas')
          .select()
          .order('nombre');

      return (response as List)
          .map((json) => Plataforma.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener plataformas: $e');
    }
  }

  Future<void> crearPlataforma(Plataforma plataforma) async {
    try {
      await _client.from('plataformas').insert(plataforma.toJson());
    } catch (e) {
      throw Exception('Error al crear plataforma: $e');
    }
  }

  Future<void> actualizarPlataforma(Plataforma plataforma) async {
    try {
      await _client
          .from('plataformas')
          .update(plataforma.toJson())
          .eq('id', plataforma.id);
    } catch (e) {
      throw Exception('Error al actualizar plataforma: $e');
    }
  }

  Future<void> eliminarPlataforma(String id) async {
    try {
      await _client.from('plataformas').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar plataforma: $e');
    }
  }

  // ==================== CLIENTES ====================

  Future<List<Cliente>> obtenerClientes() async {
    try {
      final response = await _client
          .from('clientes')
          .select()
          .filter('deleted_at', 'is', null)
          .order('nombre_completo');

      return (response as List).map((json) => Cliente.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  Future<void> crearCliente(Cliente cliente) async {
    try {
      await _client.from('clientes').insert(cliente.toJson());
    } catch (e) {
      throw Exception('Error al crear cliente: $e');
    }
  }

  Future<void> actualizarCliente(Cliente cliente) async {
    try {
      await _client
          .from('clientes')
          .update(cliente.toJson())
          .eq('id', cliente.id);
    } catch (e) {
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  Future<void> eliminarCliente(String id) async {
    try {
      await _client.from('clientes').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar cliente: $e');
    }
  }

  // ==================== SUSCRIPCIONES ====================

  Future<List<Suscripcion>> obtenerSuscripciones() async {
    try {
      final response = await _client
          .from('suscripciones')
          .select()
          .filter('deleted_at', 'is', null)
          .order('fecha_creacion', ascending: false);

      return (response as List)
          .map((json) => Suscripcion.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener suscripciones: $e');
    }
  }

  Future<void> crearSuscripcion(Suscripcion suscripcion) async {
    try {
      await _client.from('suscripciones').insert(suscripcion.toJson());
    } catch (e) {
      throw Exception('Error al crear suscripción: $e');
    }
  }

  Future<void> actualizarSuscripcion(Suscripcion suscripcion) async {
    try {
      await _client
          .from('suscripciones')
          .update(suscripcion.toJson())
          .eq('id', suscripcion.id);
    } catch (e) {
      throw Exception('Error al actualizar suscripción: $e');
    }
  }

  Future<void> eliminarSuscripcion(String id) async {
    try {
      await _client.from('suscripciones').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar suscripción: $e');
    }
  }

  // ==================== PERFILES ====================

  Future<List<Perfil>> obtenerPerfiles() async {
    try {
      final response = await _client
          .from('perfiles')
          .select()
          .filter('deleted_at', 'is', null)
          .order('nombre_perfil');

      return (response as List).map((json) => Perfil.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener perfiles: $e');
    }
  }

  // ==================== CUENTAS ====================

  Future<List<CuentaCorreo>> obtenerCuentas() async {
    try {
      final response = await _client
          .from('cuentas_correo')
          .select()
          .filter('deleted_at', 'is', null)
          .order('email');

      return (response as List)
          .map((json) => CuentaCorreo.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener cuentas: $e');
    }
  }

  Future<void> crearCuenta(CuentaCorreo cuenta) async {
    try {
      await _client.from('cuentas_correo').insert(cuenta.toJson());
    } catch (e) {
      throw Exception('Error al crear cuenta: $e');
    }
  }

  Future<void> actualizarCuenta(CuentaCorreo cuenta) async {
    try {
      await _client
          .from('cuentas_correo')
          .update(cuenta.toJson())
          .eq('id', cuenta.id);
    } catch (e) {
      throw Exception('Error al actualizar cuenta: $e');
    }
  }

  Future<void> eliminarCuenta(String id) async {
    try {
      await _client.from('cuentas_correo').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar cuenta: $e');
    }
  }
  // ==================== PERFILES ====================

  Future<void> crearPerfil(Perfil perfil) async {
    try {
      // Excluimos 'id' para que Supabase lo genere, o lo mandamos si lo generas localmente
      final json = perfil.toJson();
      if (perfil.id.isEmpty) json.remove('id');

      await _client.from('perfiles').insert(json);
    } catch (e) {
      throw Exception('Error al crear perfil: $e');
    }
  }

  Future<void> actualizarPerfil(Perfil perfil) async {
    try {
      await _client
          .from('perfiles')
          .update(perfil.toJson())
          .eq('id', perfil.id);
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  Future<void> eliminarPerfil(String id) async {
    try {
      // Soft Delete (recomendado por tu estructura actual)
      await _client
          .from('perfiles')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar perfil: $e');
    }
  }

  // ==================== SUSCRIPCIONES Y CLIENTES (Necesarios para PerfilesScreen) ====================

  Future<List<Suscripcion>> obtenerTodasSuscripciones() async {
    final response = await _client
        .from('suscripciones')
        .select()
        .filter('deleted_at', 'is', null);
    return (response as List).map((e) => Suscripcion.fromJson(e)).toList();
  }
  // ==================== USUARIOS (AUTH_USERS) ====================

  Future<List<AuthUser>> obtenerUsuarios() async {
    try {
      final response = await _client
          .from('auth_users')
          .select()
          .order('nombre_completo'); // Ordenar por nombre

      return (response as List).map((json) => AuthUser.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  Future<void> crearUsuario(AuthUser usuario, String password) async {
    try {
      // 1. Encriptar contraseña
      final hashedPassword = DBCrypt().hashpw(password, DBCrypt().gensalt());

      // 2. Preparar JSON
      final json = usuario.toJson();
      if (usuario.id.isEmpty) json.remove('id');
      json['password_hash'] = hashedPassword; // Campo importante

      await _client.from('auth_users').insert(json);
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  Future<void> actualizarUsuario(
    AuthUser usuario, {
    String? newPassword,
  }) async {
    try {
      final json = usuario.toJson();

      // Si se proporciona una nueva contraseña, la encriptamos y actualizamos
      if (newPassword != null && newPassword.isNotEmpty) {
        json['password_hash'] = DBCrypt().hashpw(
          newPassword,
          DBCrypt().gensalt(),
        );
      } else {
        // Si no, removemos el campo para no tocarlo en la BD
        json.remove('password_hash');
      }

      await _client.from('auth_users').update(json).eq('id', usuario.id);
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  Future<void> eliminarUsuario(String id) async {
    try {
      // Hard delete o Soft delete dependiendo de tu preferencia.
      // Usaremos Delete físico por consistencia con el código C#
      await _client.from('auth_users').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  // ==================== PAGOS ====================

  Future<List<Pago>> obtenerPagos() async {
    try {
      final response = await _client
          .from('pagos')
          .select()
          .order('fecha_pago', ascending: false);

      return (response as List).map((json) => Pago.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener pagos: $e');
    }
  }

  Future<void> crearPago(Pago pago) async {
    try {
      await _client.from('pagos').insert(pago.toJson());
    } catch (e) {
      throw Exception('Error al crear pago: $e');
    }
  }

  Future<void> actualizarPago(Pago pago) async {
    try {
      await _client.from('pagos').update(pago.toJson()).eq('id', pago.id);
    } catch (e) {
      throw Exception('Error al actualizar pago: $e');
    }
  }

  Future<void> eliminarPago(String id) async {
    try {
      await _client.from('pagos').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar pago: $e');
    }
  }

  // ==================== PAGOS PLATAFORMA ====================

  Future<List<PagoPlataforma>> obtenerPagosPlataforma() async {
    try {
      final response = await _client
          .from('pagos_plataforma')
          .select()
          .order('fecha_proximo_pago');

      return (response as List)
          .map((json) => PagoPlataforma.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener pagos plataforma: $e');
    }
  }

  Future<void> crearPagoPlataforma(PagoPlataforma pago) async {
    try {
      await _client.from('pagos_plataforma').insert(pago.toJson());
    } catch (e) {
      throw Exception('Error al crear pago plataforma: $e');
    }
  }

  Future<void> actualizarPagoPlataforma(PagoPlataforma pago) async {
    try {
      await _client
          .from('pagos_plataforma')
          .update(pago.toJson())
          .eq('id', pago.id);
    } catch (e) {
      throw Exception('Error al actualizar pago plataforma: $e');
    }
  }

  Future<void> eliminarPagoPlataforma(String id) async {
    try {
      await _client.from('pagos_plataforma').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar pago plataforma: $e');
    }
  }

  // ==================== HISTORIAL PAGOS PLATAFORMA ====================

  Future<List<HistorialPagoPlataforma>> obtenerHistorialPagosPlataforma(
    String pagoPlataformaId,
  ) async {
    try {
      final response = await _client
          .from('historial_pagos_plataforma')
          .select()
          .eq('pago_plataforma_id', pagoPlataformaId)
          .order('fecha_pago', ascending: false);

      return (response as List)
          .map((json) => HistorialPagoPlataforma.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }

  Future<void> registrarPagoPlataforma(
    HistorialPagoPlataforma historial,
  ) async {
    try {
      await _client
          .from('historial_pagos_plataforma')
          .insert(historial.toJson());
    } catch (e) {
      throw Exception('Error al registrar pago: $e');
    }
  }

  // ==================== ALERTAS ====================

  Future<List<Alerta>> obtenerAlertas() async {
    try {
      final response = await _client
          .from('alertas')
          .select()
          .order('fecha_creacion', ascending: false);

      return (response as List).map((json) => Alerta.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener alertas: $e');
    }
  }

  Future<void> marcarAlertaComoLeida(String id) async {
    try {
      await _client.from('alertas').update({'estado': 'leida'}).eq('id', id);
    } catch (e) {
      throw Exception('Error al marcar alerta: $e');
    }
  }

  Future<void> marcarAlertaComoResuelta(String id) async {
    try {
      await _client.from('alertas').update({'estado': 'resuelta'}).eq('id', id);
    } catch (e) {
      throw Exception('Error al resolver alerta: $e');
    }
  }

  Future<void> eliminarAlerta(String id) async {
    try {
      await _client.from('alertas').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar alerta: $e');
    }
  }

  // ==================== CONFIGURACION ====================

  Future<List<Configuracion>> obtenerConfiguraciones() async {
    try {
      final response = await _client
          .from('configuracion')
          .select()
          .order('categoria')
          .order('clave');

      return (response as List)
          .map((json) => Configuracion.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener configuraciones: $e');
    }
  }

  Future<void> actualizarConfiguracion(Configuracion config) async {
    try {
      await _client
          .from('configuracion')
          .update({
            'valor': config.valor,
            'fecha_modificacion': DateTime.now().toIso8601String(),
          })
          .eq('id', config.id);
    } catch (e) {
      throw Exception('Error al actualizar configuración: $e');
    }
  }
}
