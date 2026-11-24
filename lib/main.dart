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
      bottomNavigationBar: _ModernBottomNavBar(
        state: state,
        onTabSelected: (i) {
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
      ),
    );
  }
}

class _ModernBottomNavBar extends StatelessWidget {
  final AppState state;
  final void Function(int) onTabSelected;

  const _ModernBottomNavBar({
    required this.state,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Fallback minimum padding: jika bottomInset 0 (browser web standar), beri 16px.
    // Jika ada home indicator iOS (~34px), beri bottomInset + 8px agar tidak menempel.
    final effectiveBottomPadding = bottomInset > 0 ? (bottomInset + 8.0) : 16.0;

    const tabs = [
      _NavTabItem(
        label: 'Beranda',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
      ),
      _NavTabItem(
        label: 'Menu',
        activeIcon: Icons.restaurant_menu,
        inactiveIcon: Icons.restaurant_menu_outlined,
      ),
      _NavTabItem(
        label: 'Cerita',
        activeIcon: Icons.auto_stories,
        inactiveIcon: Icons.auto_stories_outlined,
      ),
      _NavTabItem(
        label: 'Pesanan',
        activeIcon: Icons.confirmation_num,
        inactiveIcon: Icons.confirmation_num_outlined,
      ),
      _NavTabItem(
        label: 'Profil',
        activeIcon: Icons.person,
        inactiveIcon: Icons.person_outline,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: brown2,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, effectiveBottomPadding),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = state.tab == index;

              return Expanded(
                child: InkWell(
                  onTap: () => onTabSelected(index),
                  borderRadius: BorderRadius.circular(16),
                  splashColor: green.withValues(alpha: 0.15),
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pill Indicator Modern ala WhatsApp
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: 58,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? green.withValues(alpha: 0.28)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isSelected ? tab.activeIcon : tab.inactiveIcon,
                            size: 23,
                            color: isSelected ? gold : muted,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Label teks rapi & terlindungi dari font scaling ekstrem
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: isSelected ? cream : muted,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTabItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _NavTabItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

String rupiah(int n) {
  return 'Rp ${n.toString().replaceAllMapped(
        RegExp(r'(?=(\d{3})+(?!\d))'),
        (m) => '.',
      )}';
}