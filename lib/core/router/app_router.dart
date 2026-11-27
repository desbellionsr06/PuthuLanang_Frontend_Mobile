import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_insight/presentation/views/ai_insight_view.dart';
import '../../features/auth/presentation/views/auth_view.dart';
import '../../features/checkout/presentation/views/checkout_view.dart';
import '../../features/checkout/presentation/views/takeaway_view.dart';
import '../../features/menu/presentation/views/home_view.dart';
import '../../features/menu/presentation/views/menu_view.dart';
import '../../features/menu/presentation/views/story_view.dart';
import '../../features/orders/presentation/views/orders_view.dart';
import '../../features/orders/presentation/views/ticket_view.dart';
import '../../features/profile/presentation/views/notifications_view.dart';
import '../../features/profile/presentation/views/profile_view.dart';
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
        path: '/home',
        builder: (context, state) => HomeView(state: appState),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => MenuView(state: appState),
      ),
      GoRoute(
        path: '/story',
        builder: (context, state) => StoryView(state: appState),
      ),
      GoRoute(
        path: '/ai-insight',
        builder: (context, state) => AiInsightView(appState: appState),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => NotificationsView(state: appState),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfileView(state: appState),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => OrdersView(state: appState),
      ),
      GoRoute(
        path: '/ticket',
        builder: (context, state) => TicketView(state: appState),
      ),
      GoRoute(
        path: '/takeaway',
        builder: (context, state) => TakeawayView(state: appState),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => CheckoutView(appState: appState),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => AuthView(state: appState),
      ),
    ],
  );
}
