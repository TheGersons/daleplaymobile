// ACTUALIZAR modelo Alerta (alerta.dart)
// Agregar campo suscripcionId

class Alerta {
  final String id;
  final String tipoAlerta;
  final String tipoEntidad;
  final String entidadId;
  final String? clienteId;
  final String? plataformaId;
  final String? suscripcionId; // ← NUEVO CAMPO
  final String nivel;
  final int? diasRestantes;
  final double? monto;
  final String mensaje;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaEnvioEmail;
  final String? emailEnviadoA;

  Alerta({
    required this.id,
    required this.tipoAlerta,
    required this.tipoEntidad,
    required this.entidadId,
    this.clienteId,
    this.plataformaId,
    this.suscripcionId, // ← NUEVO
    required this.nivel,
    this.diasRestantes,
    this.monto,
    required this.mensaje,
    required this.estado,
    required this.fechaCreacion,
    this.fechaEnvioEmail,
    this.emailEnviadoA,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'],
      tipoAlerta: json['tipo_alerta'],
      tipoEntidad: json['tipo_entidad'],
      entidadId: json['entidad_id'],
      clienteId: json['cliente_id'],
      plataformaId: json['plataforma_id'],
      suscripcionId: json['suscripcion_id'], // ← NUEVO
      nivel: json['nivel'],
      diasRestantes: json['dias_restantes'],
      monto: json['monto']?.toDouble(),
      mensaje: json['mensaje'],
      estado: json['estado'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaEnvioEmail: json['fecha_envio_email'] != null
          ? DateTime.parse(json['fecha_envio_email'])
          : null,
      emailEnviadoA: json['email_enviado_a'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_envio_email': fechaEnvioEmail?.toIso8601String(),
      'email_enviado_a': emailEnviadoA,
    };
  }
}