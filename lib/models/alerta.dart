class Alerta {
  final String id;
  final String tipoAlerta; // cobro_cliente, pago_plataforma
  final String tipoEntidad; // suscripcion, pago_plataforma
  final String entidadId;
  final String? clienteId;
  final String? plataformaId;
  final String nivel; // normal, advertencia, urgente, critico
  final int? diasRestantes;
  final double? monto;
  final String mensaje;
  final String estado; // pendiente, enviada, leida, resuelta
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
      nivel: json['nivel'],
      diasRestantes: json['dias_restantes'],
      monto: json['monto'] != null ? (json['monto'] as num).toDouble() : null,
      mensaje: json['mensaje'],
      estado: json['estado'] ?? 'pendiente',
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaEnvioEmail: json['fecha_envio_email'] != null
          ? DateTime.parse(json['fecha_envio_email'])
          : null,
      emailEnviadoA: json['email_enviado_a'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'tipo_alerta': tipoAlerta,
      'tipo_entidad': tipoEntidad,
      'entidad_id': entidadId,
      'cliente_id': clienteId,
      'plataforma_id': plataformaId,
      'nivel': nivel,
      'dias_restantes': diasRestantes,
      'monto': monto,
      'mensaje': mensaje,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_envio_email': fechaEnvioEmail?.toIso8601String(),
      'email_enviado_a': emailEnviadoA,
    };
    
    if (id.isNotEmpty && id != '00000000-0000-0000-0000-000000000000') {
      map['id'] = id;
    }
    
    return map;
  }
}