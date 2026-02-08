import 'package:daleplay/models/alerta.dart';
import 'package:daleplay/models/configuracion.dart';
import 'package:daleplay/models/pago.dart';
import 'package:daleplay/models/recordatorio_pago.dart';
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

  Future<Plataforma> obtenerPlataformaPorId(String id) async {
    try {
      final response = await _client
          .from('plataformas')
          .select()
          .eq('id', id)
          .single();

      return Plataforma.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener plataforma: $e');
    }
  }

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
      final json = plataforma.toJson();
      json.remove('id'); // Dejar que Supabase genere el ID
      await _client.from('plataformas').insert(json);
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
    return;

    /*try {
      await _client.from('plataformas').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar plataforma: $e');
    }
    */
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
      // Excluimos 'id' para que Supabase lo genere, o lo mandamos si lo generas localmente
      final json = cliente.toJson();
      json.remove('id');
      await _client.from('clientes').insert(json);
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
      final json = suscripcion.toJson();
      json.remove('id'); // Dejar que Supabase genere el ID
      await _client.from('suscripciones').insert(json);
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
      await _client
          .from('suscripciones')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
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

  Future<String> crearCuenta(CuentaCorreo cuenta) async {
    try {
      // 1. Obtener plataforma para saber max_perfiles
      final plataforma = await obtenerPlataformaPorId(cuenta.plataformaId);

      // 2. Insertar cuenta
      final json = cuenta.toJson();
      json.remove('id');

      final response = await _client
          .from('cuentas_correo')
          .insert(json)
          .select()
          .single();

      final cuentaId = response['id'] as String;

      // 3. AUTO-CREAR PERFILES según max_perfiles de la plataforma
      final perfilesACrear = <Map<String, dynamic>>[];

      for (int i = 1; i <= plataforma.maxPerfiles; i++) {
        perfilesACrear.add({
          'cuenta_id': cuentaId,
          'nombre_perfil': 'Perfil $i',
          'pin': null,
          'estado': 'disponible',
          'fecha_creacion': DateTime.now().toIso8601String(),
        });
      }

      await _client.from('perfiles').insert(perfilesACrear);

      return cuentaId;
    } catch (e) {
      throw Exception('Error al crear cuenta: $e');
    }
  }

  Future<void> actualizarCuenta(CuentaCorreo cuenta) async {
    try {
      // Obtener cuenta actual
      final cuentaActual = await _client
          .from('cuentas_correo')
          .select()
          .eq('id', cuenta.id)
          .single();

      final plataformaActualId = cuentaActual['plataforma_id'] as String;

      // Si cambió de plataforma, validar
      if (plataformaActualId != cuenta.plataformaId) {
        final perfilesOcupados = await contarPerfilesOcupados(cuenta.id);
        final nuevaPlataforma = await obtenerPlataformaPorId(
          cuenta.plataformaId,
        );

        if (perfilesOcupados > nuevaPlataforma.maxPerfiles) {
          throw Exception(
            'No puedes cambiar a ${nuevaPlataforma.nombre}. '
            'Tiene $perfilesOcupados perfiles ocupados pero ${nuevaPlataforma.nombre} '
            'solo permite ${nuevaPlataforma.maxPerfiles} perfiles máximo.',
          );
        }
      }

      // Actualizar cuenta
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

  // 1. AGREGAR MÉTODO HELPER para contar perfiles
  Future<int> contarPerfilesCuenta(String cuentaId) async {
    try {
      final response = await _client
          .from('perfiles')
          .select()
          .eq('cuenta_id', cuentaId)
          .filter('deleted_at', 'is', null);

      return (response as List).length;
    } catch (e) {
      throw Exception('Error al contar perfiles: $e');
    }
  }

  // 2. AGREGAR MÉTODO para contar perfiles ocupados
  Future<int> contarPerfilesOcupados(String cuentaId) async {
    try {
      final response = await _client
          .from('perfiles')
          .select()
          .eq('cuenta_id', cuentaId)
          .eq('estado', 'ocupado')
          .filter('deleted_at', 'is', null);

      return (response as List).length;
    } catch (e) {
      throw Exception('Error al contar perfiles ocupados: $e');
    }
  }

  Future<void> crearPerfil(Perfil perfil) async {
    try {
      // 1. Obtener cuenta para saber la plataforma
      final cuenta = await _client
          .from('cuentas_correo')
          .select()
          .eq('id', perfil.cuentaId)
          .single();

      final plataformaId = cuenta['plataforma_id'] as String;
      final plataforma = await obtenerPlataformaPorId(plataformaId);

      // 2. Contar perfiles actuales de la cuenta
      final perfilesActuales = await contarPerfilesCuenta(perfil.cuentaId);

      // 3. Validar límite
      if (perfilesActuales >= plataforma.maxPerfiles) {
        throw Exception(
          'Límite alcanzado. ${plataforma.nombre} solo permite '
          '${plataforma.maxPerfiles} perfiles por cuenta.',
        );
      }

      // 4. Insertar perfil
      final json = perfil.toJson();
      json.remove('id');

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
      final json = pago.toJson();
      json.remove('id'); // Dejar que Supabase genere el ID
      await _client.from('pagos').insert(json);
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
      final json = pago.toJson();
      json.remove('id'); // Dejar que Supabase genere el ID
      await _client.from('pagos_plataforma').insert(json);
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

  Future<void> crearAlerta({
    required String tipoAlerta,
    required String tipoEntidad,
    required String entidadId,
    String? clienteId,
    String? plataformaId,
    required String suscripcionId, // ← NUEVO: ahora es required
    required String nivel,
    required int diasRestantes,
    required double monto,
    required String mensaje,
  }) async {
    try {
      await _client.from('alertas').insert({
        'tipo_alerta': tipoAlerta,
        'tipo_entidad': tipoEntidad,
        'entidad_id': entidadId,
        'cliente_id': clienteId,
        'plataforma_id': plataformaId,
        'suscripcion_id': suscripcionId, // ← NUEVO
        'nivel': nivel,
        'dias_restantes': diasRestantes,
        'monto': monto,
        'mensaje': mensaje,
        'estado': 'pendiente',
        'fecha_creacion': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al crear alerta: $e');
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

  // ==================== SUSCRIPCIÓN RÁPIDA (TRANSACCIONAL) ====================

  Future<void> crearSuscripcionRapida({
    required String clienteId,
    required String perfilId,
    required DateTime fechaInicio,
    required double precio,
    required String plataformaId,
  }) async {
    try {
      // 1. Verificar que el perfil sigue disponible
      final perfilResponse = await _client
          .from('perfiles')
          .select()
          .eq('id', perfilId)
          .single();

      final perfil = Perfil.fromJson(perfilResponse);

      if (perfil.estado != 'disponible') {
        throw Exception('El perfil ya no está disponible');
      }

      // 2. Calcular fecha vencimiento (mismo día del siguiente mes)
      final fechaVencimiento = DateTime(
        fechaInicio.year,
        fechaInicio.month + 1,
        fechaInicio.day,
      );

      // 3. Crear suscripción
      final suscripcion = Suscripcion(
        id: '00000000-0000-0000-0000-000000000000',
        plataformaId: plataformaId,
        tipoSuscripcion: 'perfil',
        clienteId: clienteId,
        perfilId: perfilId,
        fechaInicio: fechaInicio,
        fechaProximoPago: fechaVencimiento,
        fechaLimitePago: fechaVencimiento,
        precio: precio,
        estado: 'activa',
        fechaCreacion: DateTime.now(),
        notas: null,
      );

      //retiramos el id para que supabase lo genere automáticamente
      final suscripcionJson = suscripcion.toJson();
      suscripcionJson.remove('id');

      await _client.from('suscripciones').insert(suscripcionJson);

      // 4. Actualizar estado del perfil a "ocupado"
      await _client
          .from('perfiles')
          .update({'estado': 'ocupado'})
          .eq('id', perfilId);

      // 5. NOTA: Las alertas se crean automáticamente por triggers en la BD
      // No necesitamos crearlas manualmente aquí
    } catch (e) {
      throw Exception('Error al crear suscripción rápida: $e');
    }
  }

  // ==================== RECORDATORIOS DE PAGO ====================
  // Agregar estos métodos a la clase SupabaseService

  // Importar el modelo (agregar al inicio del archivo)
  // import '../models/recordatorio_pago.dart';

  /// Obtener suscripciones que necesitan recordatorio (hoy y mañana)
  /// Incluye: activas + esperando_pago sin recordatorio hoy
  Future<List<Suscripcion>> obtenerSuscripcionesParaRecordatorio() async {
    try {
      final hoy = DateTime.now();
      final manana = hoy.add(const Duration(days: 1));

      // Formatear fechas para comparación
      final hoyStr = hoy.toIso8601String().split('T')[0];
      final mananaStr = manana.toIso8601String().split('T')[0];

      // Obtener suscripciones activas que vencen hoy o mañana
      final response = await _client
          .from('suscripciones')
          .select()
          .filter('deleted_at', 'is', null)
          .or('estado.eq.activa,estado.eq.esperando_pago')
          .or('fecha_proximo_pago.eq.$hoyStr,fecha_proximo_pago.eq.$mananaStr')
          .order('fecha_proximo_pago');

      final suscripciones = (response as List)
          .map((json) => Suscripcion.fromJson(json))
          .toList();

      // Filtrar las que ya tienen recordatorio enviado hoy
      final suscripcionesFiltradas = <Suscripcion>[];

      for (final suscripcion in suscripciones) {
        final tieneRecordatorioHoy = await _tieneRecordatorioHoy(
          suscripcion.id,
        );
        if (!tieneRecordatorioHoy) {
          suscripcionesFiltradas.add(suscripcion);
        }
      }

      return suscripcionesFiltradas;
    } catch (e) {
      throw Exception('Error al obtener suscripciones para recordatorio: $e');
    }
  }

  /// Verificar si una suscripción ya tiene recordatorio enviado hoy
  Future<bool> _tieneRecordatorioHoy(String suscripcionId) async {
    try {
      final hoy = DateTime.now().toIso8601String().split('T')[0];

      final response = await _client
          .from('recordatorios_pago')
          .select()
          .eq('suscripcion_id', suscripcionId)
          .eq('fecha_recordatorio', hoy)
          .eq('enviado', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Marcar recordatorio como enviado y cambiar estado a esperando_pago
  Future<void> marcarRecordatorioEnviado(String suscripcionId) async {
    try {
      final hoy = DateTime.now();
      final hoyStr = hoy.toIso8601String().split('T')[0];

      // 1. Crear o actualizar recordatorio
      final recordatorioExistente = await _client
          .from('recordatorios_pago')
          .select()
          .eq('suscripcion_id', suscripcionId)
          .eq('fecha_recordatorio', hoyStr)
          .maybeSingle();

      if (recordatorioExistente != null) {
        // Actualizar existente
        await _client
            .from('recordatorios_pago')
            .update({'enviado': true, 'fecha_envio': hoy.toIso8601String()})
            .eq('id', recordatorioExistente['id']);
      } else {
        // Crear nuevo
        await _client.from('recordatorios_pago').insert({
          'suscripcion_id': suscripcionId,
          'fecha_recordatorio': hoyStr,
          'enviado': true,
          'fecha_envio': hoy.toIso8601String(),
        });
      }

      // 2. Cambiar estado de suscripción a esperando_pago
      await _client
          .from('suscripciones')
          .update({'estado': 'esperando_pago'})
          .eq('id', suscripcionId);
    } catch (e) {
      throw Exception('Error al marcar recordatorio: $e');
    }
  }

  /// Obtener suscripciones en lista de espera
  Future<List<Suscripcion>> obtenerSuscripcionesEnEspera() async {
    try {
      final response = await _client
          .from('suscripciones')
          .select()
          .filter('deleted_at', 'is', null)
          .eq('estado', 'esperando_pago')
          .order('fecha_proximo_pago');

      return (response as List)
          .map((json) => Suscripcion.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener suscripciones en espera: $e');
    }
  }

  /// Renovar suscripción con pago
  Future<void> renovarSuscripcion({
    required String suscripcionId,
    required String clienteId,
    required DateTime nuevaFechaPago,
    required double monto,
    required String metodoPago,
    String? referencia,
    String? notas,
    String? usuarioId,
  }) async {
    try {
      final ahora = DateTime.now();

      // 1. Obtener suscripción actual para calcular fecha límite
      final suscripcionActual = await _client
          .from('suscripciones')
          .select()
          .eq('id', suscripcionId)
          .single();

      final suscripcion = Suscripcion.fromJson(suscripcionActual);

      // Calcular fecha límite (5 días después del próximo pago)
      final nuevaFechaLimite = nuevaFechaPago.add(const Duration(days: 5));

      // 2. Registrar pago
      await _client.from('pagos').insert({
        'suscripcion_id': suscripcionId,
        'cliente_id': clienteId,
        'monto': monto,
        'fecha_pago': ahora.toIso8601String(),
        'metodo_pago': metodoPago,
        'referencia': referencia,
        'notas': notas,
        'registrado_por': usuarioId,
      });

      // 3. Actualizar suscripción
      await _client
          .from('suscripciones')
          .update({
            'fecha_proximo_pago': nuevaFechaPago.toIso8601String().split(
              'T',
            )[0],
            'fecha_limite_pago': nuevaFechaLimite.toIso8601String().split(
              'T',
            )[0],
            'estado': 'activa',
          })
          .eq('id', suscripcionId);

      // 4. Registrar en historial
      await _client.from('historial_suscripciones').insert({
        'suscripcion_id': suscripcionId,
        'accion': 'renovada',
        'precio_anterior': suscripcion.precio,
        'precio_nuevo': monto,
        'fecha_cambio': ahora.toIso8601String(),
        'usuario_id': usuarioId,
        'notas': 'Renovación con pago registrado',
      });

      // 5. Eliminar alertas vencidas de esta suscripción
      await _client
          .from('alertas')
          .delete()
          .eq('suscripcion_id', suscripcionId)
          .lt('dias_restantes', 0);
    } catch (e) {
      throw Exception('Error al renovar suscripción: $e');
    }
  }

  /// Cancelar suscripción (soft delete) y liberar perfil
  Future<void> cancelarSuscripcion(
    String suscripcionId, {
    String? usuarioId,
  }) async {
    try {
      final ahora = DateTime.now();

      // 1. Obtener suscripción para acceder al perfil
      final suscripcionData = await _client
          .from('suscripciones')
          .select()
          .eq('id', suscripcionId)
          .single();

      final perfilId = suscripcionData['perfil_id'] as String;

      // 2. Soft delete de suscripción
      await _client
          .from('suscripciones')
          .update({
            'deleted_at': ahora.toIso8601String(),
            'estado': 'cancelada',
          })
          .eq('id', suscripcionId);

      // 3. Liberar perfil
      await _client
          .from('perfiles')
          .update({'estado': 'disponible'})
          .eq('id', perfilId);

      // 4. Eliminar alertas asociadas
      await _client
          .from('alertas')
          .delete()
          .eq('suscripcion_id', suscripcionId);

      // 5. Registrar en historial
      await _client.from('historial_suscripciones').insert({
        'suscripcion_id': suscripcionId,
        'accion': 'cancelada',
        'fecha_cambio': ahora.toIso8601String(),
        'usuario_id': usuarioId,
        'notas': 'Suscripción cancelada por falta de pago',
      });
    } catch (e) {
      throw Exception('Error al cancelar suscripción: $e');
    }
  }

  /// Obtener recordatorios de una suscripción (historial)
  Future<List<RecordatorioPago>> obtenerRecordatoriosSuscripcion(
    String suscripcionId,
  ) async {
    try {
      final response = await _client
          .from('recordatorios_pago')
          .select()
          .eq('suscripcion_id', suscripcionId)
          .order('fecha_recordatorio', ascending: false);

      return (response as List)
          .map((json) => RecordatorioPago.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener recordatorios: $e');
    }
  }
}
