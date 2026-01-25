import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/supabase_service.dart';
import '../../providers/user_provider.dart';
import '../../models/suscripcion.dart';
import '../../models/plataforma.dart';
import '../../models/cliente.dart';
import '../../models/perfil.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  
  List<Suscripcion> _suscripciones = [];
  List<Plataforma> _plataformas = [];
  List<Cliente> _clientes = [];
  List<Perfil> _perfiles = [];
  
  int _totalSuscripcionesActivas = 0;
  double _ingresosMensuales = 0;
  int _totalClientes = 0;
  int _perfilesDisponibles = 0;
  int _suscripcionesEsteMes = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final suscripciones = await _supabaseService.obtenerSuscripciones();
      final plataformas = await _supabaseService.obtenerPlataformas();
      final clientes = await _supabaseService.obtenerClientes();
      final perfiles = await _supabaseService.obtenerPerfiles();

      final suscripcionesActivas = suscripciones
          .where((s) => s.estado == 'activa')
          .toList();

      final clientesActivos = clientes
          .where((c) => c.estado == 'activo')
          .toList();

      final perfilesDisponibles = perfiles
          .where((p) => p.estado == 'disponible')
          .length;

      final ahora = DateTime.now();
      final suscripcionesEsteMes = suscripcionesActivas
          .where((s) => 
              s.fechaInicio.month == ahora.month && 
              s.fechaInicio.year == ahora.year)
          .length;

      setState(() {
        _suscripciones = suscripcionesActivas;
        _plataformas = plataformas;
        _clientes = clientesActivos;
        _perfiles = perfiles;
        _totalSuscripcionesActivas = suscripcionesActivas.length;
        _ingresosMensuales = suscripcionesActivas.fold(0, (sum, s) => sum + s.precio);
        _totalClientes = clientesActivos.length;
        _perfilesDisponibles = perfilesDisponibles;
        _suscripcionesEsteMes = suscripcionesEsteMes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isAdmin = userProvider.isAdmin;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha
            Text(
              DateFormat('EEEE, dd \'de\' MMMM yyyy', 'es_ES').format(DateTime.now()),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Suscripciones Activas',
                  _totalSuscripcionesActivas.toString(),
                  '+$_suscripcionesEsteMes este mes',
                  Icons.subscriptions,
                  const Color(0xFF2196F3),
                ),
                if (isAdmin)
                  _buildStatCard(
                    'Ingresos Mensuales',
                    'L ${_ingresosMensuales.toStringAsFixed(2)}',
                    DateFormat('MMMM yyyy', 'es_ES').format(DateTime.now()),
                    Icons.attach_money,
                    const Color(0xFF4CAF50),
                  ),
                _buildStatCard(
                  'Clientes Activos',
                  _totalClientes.toString(),
                  '$_totalClientes activos',
                  Icons.people,
                  const Color(0xFFFF9800),
                ),
                _buildStatCard(
                  'Perfiles Disponibles',
                  _perfilesDisponibles.toString(),
                  'De ${_perfiles.length} totales',
                  Icons.person_outline,
                  const Color(0xFF9C27B0),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Gráfico de ingresos por plataforma (solo admin)
            if (isAdmin) ...[
              Text(
                'Ingresos por Plataforma',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildIngresosPorPlataforma(),
              const SizedBox(height: 24),
            ],

            // Plataformas populares
            Text(
              'Plataformas Populares',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPlataformasPopulares(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngresosPorPlataforma() {
    final ingresosPorPlataforma = <String, double>{};

    for (var plataforma in _plataformas) {
      final suscripcionesPlataforma = _suscripciones
          .where((s) => s.plataformaId == plataforma.id)
          .toList();
      
      if (suscripcionesPlataforma.isNotEmpty) {
        final total = suscripcionesPlataforma.fold(0.0, (sum, s) => sum + s.precio);
        ingresosPorPlataforma[plataforma.nombre] = total;
      }
    }

    if (ingresosPorPlataforma.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No hay datos disponibles')),
        ),
      );
    }

    final topPlataformas = ingresosPorPlataforma.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: topPlataformas.take(5).map((entry) {
                    final index = topPlataformas.indexOf(entry);
                    final colors = [
                      const Color(0xFF2196F3),
                      const Color(0xFF4CAF50),
                      const Color(0xFFFF9800),
                      const Color(0xFFF44336),
                      const Color(0xFF9C27B0),
                    ];
                    
                    return PieChartSectionData(
                      value: entry.value,
                      title: 'L${entry.value.toStringAsFixed(0)}',
                      color: colors[index % colors.length],
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  centerSpaceRadius: 35,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...topPlataformas.take(5).map((entry) {
              final index = topPlataformas.indexOf(entry);
              final colors = [
                const Color(0xFF2196F3),
                const Color(0xFF4CAF50),
                const Color(0xFFFF9800),
                const Color(0xFFF44336),
                const Color(0xFF9C27B0),
              ];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.key)),
                    Text(
                      'L ${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlataformasPopulares() {
    final cantidadPorPlataforma = <String, int>{};

    for (var plataforma in _plataformas) {
      final cantidad = _suscripciones
          .where((s) => s.plataformaId == plataforma.id)
          .length;
      
      if (cantidad > 0) {
        cantidadPorPlataforma[plataforma.nombre] = cantidad;
      }
    }

    if (cantidadPorPlataforma.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No hay datos disponibles')),
        ),
      );
    }

    final topPlataformas = cantidadPorPlataforma.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topPlataformas.take(5).length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = topPlataformas[index];
          final plataforma = _plataformas.firstWhere((p) => p.nombre == entry.key);
          
          return ListTile(
            leading: _buildPlataformaLogo(plataforma),
            title: Text(entry.key),
            trailing: Text(
              '${entry.value} ${entry.value == 1 ? 'suscripción' : 'suscripciones'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlataformaLogo(Plataforma plataforma) {
    // Mapeo de logos conocidos (PNG/JPG)
    final logos = {
      'Netflix': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Netflix_2015_logo.svg/330px-Netflix_2015_logo.svg.png',
      'Disney+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Disney%2B_logo.svg/330px-Disney%2B_logo.svg.png',
      'HBO': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/HBO_logo.svg/330px-HBO_logo.svg.png',
      'HBO Max': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/HBO_Max_Logo.svg/330px-HBO_Max_Logo.svg.png',
      'Prime Video': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Prime_Video.svg/330px-Prime_Video.svg.png',
      'Spotify': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Spotify_logo_without_text.svg/168px-Spotify_logo_without_text.svg.png',
      'YouTube': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/YouTube_full-color_icon_%282017%29.svg/159px-YouTube_full-color_icon_%282017%29.svg.png',
      'Paramount+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Paramount_Plus.svg/330px-Paramount_Plus.svg.png',
      'Apple TV+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Apple_TV_Plus_Logo.svg/330px-Apple_TV_Plus_Logo.svg.png',
      'Max': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/HBO_Max_Logo.svg/330px-HBO_Max_Logo.svg.png',
    };

    final logoUrl = logos[plataforma.nombre];

    if (logoUrl != null) {
      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: logoUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) {
              print('Error loading logo for ${plataforma.nombre}: $error');
              return _buildGenericIcon(plataforma);
            },
          ),
        ),
      );
    }

    return _buildGenericIcon(plataforma);
  }

  Widget _buildGenericIcon(Plataforma plataforma) {
    return CircleAvatar(
      backgroundColor: Color(int.parse(plataforma.color.replaceFirst('#', '0xFF'))),
      child: const FaIcon(
        FontAwesomeIcons.tv,
        size: 20,
        color: Colors.white,
      ),
    );
  }
}