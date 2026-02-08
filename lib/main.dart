import 'dart:io';
import 'package:daleplay/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'utils/constants.dart';
import 'providers/alertas_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Inicializar locale español
  await initializeDateFormatting('es_ES', null);

  try{
    await Supabase.instance.client.from('clientes').select().limit(1);
    print('Conexiona Supabase exitosa');
  }catch(e){
    print('Error initializing Supabase: $e');
  }
  final userProvider = UserProvider();
  await userProvider.loadUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider), // Usar .value para pasar el que ya cargó
        ChangeNotifierProvider(create: (_) => AlertasProvider()..iniciarMonitoreo()),
      ],
      child: const DalePlayApp(),
    ),
  );
}

class DalePlayApp extends StatelessWidget {
  const DalePlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AlertasProvider()..iniciarMonitoreo()),
      ],
      child: MaterialApp(
        title: 'DalePlay',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.dark,
          ),
        ),
          home: userProvider.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

///conservar las sesiones abiertas