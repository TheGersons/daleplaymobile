class PagoPlataforma {
  final String id;
  final String cuentaId;
  final String plataformaId;
  final double montoMensual;
  final int diaPagoMes;
  final DateTime fechaProximoPago;
  final DateTime fechaLimitePago;
  final int diasGracia;
  final String estado; // al_dia, por_pagar, vencido
  final String metodoPagoPreferido;
  final String? notas;
  final DateTime? fechaUltimoPago;
  final DateTime fechaCreacion;

  PagoPlataforma({
    required this.id,
    required this.cuentaId,
    required this.plataformaId,
    required this.montoMensual,
    required this.diaPagoMes,
    required this.fechaProximoPago,
    required this.fechaLimitePago,
    required this.diasGracia,
    required this.estado,
    required this.metodoPagoPreferido,
    this.notas,
    this.fechaUltimoPago,
    required this.fechaCreacion,
  });

  factory PagoPlataforma.fromJson(Map<String, dynamic> json) {
    return PagoPlataforma(
      id: json['id'],
      cuentaId: json['cuenta_id'],
      plataformaId: json['plataforma_id'],
      montoMensual: (json['monto_mensual'] as num).toDouble(),
      diaPagoMes: json['dia_pago_mes'],
      fechaProximoPago: DateTime.parse(json['fecha_proximo_pago']),
      fechaLimitePago: DateTime.parse(json['fecha_limite_pago']),
      diasGracia: json['dias_gracia'] ?? 5,
      estado: json['estado'] ?? 'pendiente',
      metodoPagoPreferido: json['metodo_pago_preferido'] ?? 'transferencia',
      notas: json['notas'],
      fechaUltimoPago: json['fecha_ultimo_pago'] != null
          ? DateTime.parse(json['fecha_ultimo_pago'])
          : null,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'cuenta_id': cuentaId,
      'plataforma_id': plataformaId,
      'monto_mensual': montoMensual,
      'dia_pago_mes': diaPagoMes,
      'fecha_proximo_pago': fechaProximoPago.toIso8601String().split('T')[0],
      'fecha_limite_pago': fechaLimitePago.toIso8601String().split('T')[0],
      'dias_gracia': diasGracia,
      'estado': estado,
      'metodo_pago_preferido': metodoPagoPreferido,
      'notas': notas,
      'fecha_ultimo_pago': fechaUltimoPago?.toIso8601String().split('T')[0],
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
    
    if (id.isNotEmpty && id != '00000000-0000-0000-0000-000000000000') {
      map['id'] = id;
    }
    
    return map;
  }
}