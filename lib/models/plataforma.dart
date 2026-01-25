class Plataforma {
  final String id;
  final String nombre;
  final String icono;
  final double precioBase;
  final int maxPerfiles;
  final String color;
  final String estado;
  final DateTime fechaCreacion;
  final String? notas;
  final int? precioCompleta;

  Plataforma({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.precioBase,
    required this.maxPerfiles,
    required this.color,
    required this.estado,
    required this.fechaCreacion,
    this.notas,
    this.precioCompleta,
  });

  factory Plataforma.fromJson(Map<String, dynamic> json) {
    return Plataforma(
      id: json['id'],
      nombre: json['nombre'],
      icono: json['icono'] ?? 'Television',
      precioBase: (json['precio_base'] ?? 0).toDouble(),
      maxPerfiles: json['max_perfiles'] ?? 4,
      color: json['color'] ?? '#2196F3',
      estado: json['estado'] ?? 'activa',
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      notas: json['notas'],
      precioCompleta: json['precio_completa'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'icono': icono,
      'precio_base': precioBase,
      'max_perfiles': maxPerfiles,
      'color': color,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'notas': notas,
      'precio_completa': precioCompleta,
    };
  }
}