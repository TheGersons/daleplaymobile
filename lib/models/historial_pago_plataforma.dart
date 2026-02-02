class HistorialPagoPlataforma {
  final String id;
  final String pagoPlataformaId;
  final double montoPagado;
  final DateTime fechaPago;
  final String? metodoPago;
  final String? referencia;
  final String? notas;
  final String? registradoPor;

  HistorialPagoPlataforma({
    required this.id,
    required this.pagoPlataformaId,
    required this.montoPagado,
    required this.fechaPago,
    this.metodoPago,
    this.referencia,
    this.notas,
    this.registradoPor,
  });

  factory HistorialPagoPlataforma.fromJson(Map<String, dynamic> json) {
    return HistorialPagoPlataforma(
      id: json['id'],
      pagoPlataformaId: json['pago_plataforma_id'],
      montoPagado: (json['monto_pagado'] as num).toDouble(),
      fechaPago: DateTime.parse(json['fecha_pago']),
      metodoPago: json['metodo_pago'],
      referencia: json['referencia'],
      notas: json['notas'],
      registradoPor: json['registrado_por'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'pago_plataforma_id': pagoPlataformaId,
      'monto_pagado': montoPagado,
      'fecha_pago': fechaPago.toIso8601String(),
      'metodo_pago': metodoPago,
      'referencia': referencia,
      'notas': notas,
      'registrado_por': registradoPor,
    };
    
    if (id.isNotEmpty && id != '00000000-0000-0000-0000-000000000000') {
      map['id'] = id;
    }
    
    return map;
  }
}