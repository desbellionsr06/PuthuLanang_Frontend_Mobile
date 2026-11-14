import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/ai_insight/presentation/views/ai_insight_view.dart';
import '../../features/checkout/presentation/views/checkout_view.dart';
import '../../pages/auth_page.dart';
import '../../pages/notifications_page.dart';
import '../../pages/takeaway_page.dart';
import '../../state/app_state.dart';

GoRouter createAppRouter(AppState appState) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const SizedBox.shrink(), // Dipakai oleh MainShell
      ),
      GoRoute(
        path: '/ai-insight',
        builder: (context, state) => AiInsightView(appState: appState),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => NotificationsPage(state: appState),
      ),
      GoRoute(
        path: '/takeaway',
        builder: (context, state) => TakeawayPage(state: appState),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => CheckoutView(appState: appState),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => AuthPage(state: appState),
      ),
    ],
  );
}
