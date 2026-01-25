import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:dbcrypt/dbcrypt.dart';
import '../models/auth_user.dart';
import '../models/plataforma.dart';
import '../models/cliente.dart';
import '../models/suscripcion.dart';
import '../models/perfil.dart';
import '../models/cuenta_correo.dart';

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

  // ==================== USUARIOS ====================
  
  Future<List<AuthUser>> obtenerUsuarios() async {
    try {
      final response = await _client
          .from('auth_users')
          .select()
          .order('nombre_completo');

      return (response as List)
          .map((json) => AuthUser.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  Future<void> crearUsuario(AuthUser user) async {
    try {
      await _client.from('auth_users').insert(user.toJson());
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  Future<void> actualizarUsuario(AuthUser user) async {
    try {
      await _client
          .from('auth_users')
          .update(user.toJson())
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  Future<void> eliminarUsuario(String id) async {
    try {
      await _client.from('auth_users').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
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

      return (response as List)
          .map((json) => Cliente.fromJson(json))
          .toList();
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

      return (response as List)
          .map((json) => Perfil.fromJson(json))
          .toList();
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
}