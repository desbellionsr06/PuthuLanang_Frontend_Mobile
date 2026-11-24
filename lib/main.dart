import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'state/app_state.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/story_page.dart';
import 'pages/ticket_page.dart';
import 'pages/profile_page.dart';

export 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator(); // Inisialisasi GetIt Dependency Injection
  runApp(
    const ProviderScope( // Riverpod State Management Container
      child: PuthuLanangApp(),
    ),
  );
}

class PuthuLanangApp extends StatefulWidget {
  const PuthuLanangApp({super.key});

  @override
  State<PuthuLanangApp> createState() => _PuthuLanangAppState();
}

class _PuthuLanangAppState extends State<PuthuLanangApp> {
  final state = AppState();

  @override
  void initState() {
    super.initState();
    state.restore().then((_) {
      if (kIsWeb) {
        final uri = Uri.base;
        final orderId = uri.queryParameters['order_id'];
        if (orderId != null && orderId.isNotEmpty) {
          unawaited(state.loadInvoiceTicket(orderId));
        }
      }
    });
    state.loadMenu();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Puthu Lanang',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: brown,
            colorScheme: ColorScheme.fromSeed(
              seedColor: green,
              brightness: Brightness.dark,
            ),
            fontFamily: GoogleFonts.poppins().fontFamily,
            navigationBarTheme: NavigationBarThemeData(
              height: 64,
              backgroundColor: brown2,
              indicatorColor: green.withValues(alpha: 0.25),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    color: gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  );
                }
                return const TextStyle(
                  color: muted,
                  fontSize: 10,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: gold, size: 22);
                }
                return const IconThemeData(color: cream, size: 20);
              }),
            ),
          ),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final clampedMediaQuery = mediaQuery.copyWith(
              textScaler: mediaQuery.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.15,
              ),
            );

            return MediaQuery(
              data: clampedMediaQuery,
              child: ColoredBox(
                color: const Color(0xFF120B08),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
          home: !state.isRestored
              ? const Scaffold(
                  backgroundColor: brown,
                  body: Center(
                    child: CircularProgressIndicator(color: green),
                  ),
                )
              : (state.loggedIn ? MainShell(state: state) : AuthPage(state: state)),
        );
      },
    );
  }
}

class MainShell extends StatelessWidget {
  final AppState state;

  const MainShell({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(state: state),
      MenuPage(state: state),
      StoryPage(state: state),
      TicketPage(state: state),
      ProfilePage(state: state),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[state.tab],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: brown2,
        indicatorColor: green.withValues(alpha: 0.25),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: state.tab,
        onDestinationSelected: (i) {
          // Jika pengguna memilih tab Pesanan (3) atau Profil (4) tetapi belum login,
          // arahkan terlebih dahulu ke halaman Auth (Masuk/Daftar).
          if ((i == 3 || i == 4) && !state.loggedIn) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AuthPage(
                  state: state,
                ),
              ),
            );
            return;
          }

          // Memperbarui tab aktif dan memicu pembaruan UI secara langsung
          state.setTab(i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Cerita',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_num_outlined),
            selectedIcon: Icon(Icons.confirmation_num),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

String rupiah(int n) {
  return 'Rp ${n.toString().replaceAllMapped(
        RegExp(r'(?=(\d{3})+(?!\d))'),
        (m) => '.',
      )}';
}