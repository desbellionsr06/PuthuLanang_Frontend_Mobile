import 'package:get_it/get_it.dart';

// ── Feature: AI Insight ───────────────────────────────────────────
import '../../features/ai_insight/data/repositories/ai_insight_repository_impl.dart';
import '../../features/ai_insight/domain/repositories/ai_insight_repository.dart';
import '../../features/ai_insight/domain/usecases/calculate_queue_estimate.dart';
import '../../features/ai_insight/domain/usecases/get_latest_verified_insight.dart';
import '../../features/ai_insight/domain/usecases/get_menu_recommendation.dart';
import '../../features/ai_insight/presentation/viewmodels/ai_insight_view_model.dart';

// ── Feature: Auth ─────────────────────────────────────────────────
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_user.dart';
import '../../features/auth/domain/usecases/logout_user.dart';
import '../../features/auth/domain/usecases/reset_password.dart';
import '../../features/auth/domain/usecases/restore_auth_session.dart';
import '../../features/auth/domain/usecases/send_auth_otp.dart';
import '../../features/auth/domain/usecases/verify_auth_otp.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';

// ── Feature: Checkout ─────────────────────────────────────────────
import '../../features/checkout/data/repositories/checkout_repository_impl.dart';
import '../../features/checkout/domain/repositories/checkout_repository.dart';
import '../../features/checkout/domain/usecases/create_checkout_order.dart';
import '../../features/checkout/domain/usecases/validate_checkout_input.dart';
import '../../features/checkout/presentation/viewmodels/checkout_view_model.dart';

// ── Feature: Menu ─────────────────────────────────────────────────
import '../../features/menu/data/repositories/menu_repository_impl.dart';
import '../../features/menu/domain/repositories/menu_repository.dart';
import '../../features/menu/domain/usecases/get_menu_catalog.dart';
import '../../features/menu/domain/usecases/get_outlets.dart';
import '../../features/menu/presentation/viewmodels/menu_view_model.dart';

// ── Feature: Orders ───────────────────────────────────────────────
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/domain/usecases/complete_order.dart';
import '../../features/orders/domain/usecases/get_order_history.dart';
import '../../features/orders/domain/usecases/get_order_invoice.dart';
import '../../features/orders/domain/usecases/process_digital_payment.dart';
import '../../features/orders/presentation/viewmodels/orders_view_model.dart';

// ── Feature: Profile ──────────────────────────────────────────────
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_notifications.dart';
import '../../features/profile/domain/usecases/mark_notifications_read.dart';
import '../../features/profile/domain/usecases/sync_device_fcm_token.dart';
import '../../features/profile/presentation/viewmodels/profile_view_model.dart';

/// Composition Root aplikasi Puthu Lanang Malang.
/// Menginjeksikan rantai dependensi secara eksplisit:
/// ApiService → RepositoryImpl (as Interface) → UseCase → ViewModel → View.
final getIt = GetIt.instance;

void setupLocator() {
  // =================================================================
  // 1. DATA LAYER — Repository Implementations (bound to Domain Interfaces)
  // =================================================================
  if (!getIt.isRegistered<AiInsightRepository>()) {
    getIt.registerLazySingleton<AiInsightRepository>(
      () => AiInsightRepositoryImpl(),
    );
  }
  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(),
    );
  }
  if (!getIt.isRegistered<CheckoutRepository>()) {
    getIt.registerLazySingleton<CheckoutRepository>(
      () => CheckoutRepositoryImpl(),
    );
  }
  if (!getIt.isRegistered<MenuRepository>()) {
    getIt.registerLazySingleton<MenuRepository>(
      () => MenuRepositoryImpl(),
    );
  }
  if (!getIt.isRegistered<OrdersRepository>()) {
    getIt.registerLazySingleton<OrdersRepository>(
      () => OrdersRepositoryImpl(),
    );
  }
  if (!getIt.isRegistered<ProfileRepository>()) {
    getIt.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(),
    );
  }

  // =================================================================
  // 2. DOMAIN LAYER — Use Cases
  // =================================================================
  // AI Insight UseCases
  if (!getIt.isRegistered<GetLatestVerifiedInsight>()) {
    getIt.registerLazySingleton(
      () => GetLatestVerifiedInsight(getIt<AiInsightRepository>()),
    );
  }
  if (!getIt.isRegistered<CalculateQueueEstimate>()) {
    getIt.registerLazySingleton(
      () => CalculateQueueEstimate(getIt<AiInsightRepository>()),
    );
  }
  if (!getIt.isRegistered<GetMenuRecommendation>()) {
    getIt.registerLazySingleton(
      () => GetMenuRecommendation(getIt<AiInsightRepository>()),
    );
  }

  // Auth UseCases
  if (!getIt.isRegistered<LoginUser>()) {
    getIt.registerLazySingleton(() => LoginUser(getIt<AuthRepository>()));
  }
  if (!getIt.isRegistered<SendAuthOtp>()) {
    getIt.registerLazySingleton(() => SendAuthOtp(getIt<AuthRepository>()));
  }
  if (!getIt.isRegistered<VerifyAuthOtp>()) {
    getIt.registerLazySingleton(() => VerifyAuthOtp(getIt<AuthRepository>()));
  }
  if (!getIt.isRegistered<ResetPassword>()) {
    getIt.registerLazySingleton(() => ResetPassword(getIt<AuthRepository>()));
  }
  if (!getIt.isRegistered<RestoreAuthSession>()) {
    getIt.registerLazySingleton(
      () => RestoreAuthSession(getIt<AuthRepository>()),
    );
  }
  if (!getIt.isRegistered<LogoutUser>()) {
    getIt.registerLazySingleton(() => LogoutUser(getIt<AuthRepository>()));
  }

  // Checkout UseCases
  if (!getIt.isRegistered<ValidateCheckoutInput>()) {
    getIt.registerLazySingleton(() => const ValidateCheckoutInput());
  }
  if (!getIt.isRegistered<CreateCheckoutOrder>()) {
    getIt.registerLazySingleton(
      () => CreateCheckoutOrder(
        getIt<CheckoutRepository>(),
        validator: getIt<ValidateCheckoutInput>(),
      ),
    );
  }

  // Menu UseCases
  if (!getIt.isRegistered<GetMenuCatalog>()) {
    getIt.registerLazySingleton(() => GetMenuCatalog(getIt<MenuRepository>()));
  }
  if (!getIt.isRegistered<GetOutlets>()) {
    getIt.registerLazySingleton(() => GetOutlets(getIt<MenuRepository>()));
  }

  // Orders UseCases
  if (!getIt.isRegistered<GetOrderHistory>()) {
    getIt.registerLazySingleton(
      () => GetOrderHistory(getIt<OrdersRepository>()),
    );
  }
  if (!getIt.isRegistered<CompleteOrder>()) {
    getIt.registerLazySingleton(
      () => CompleteOrder(getIt<OrdersRepository>()),
    );
  }
  if (!getIt.isRegistered<GetOrderInvoice>()) {
    getIt.registerLazySingleton(
      () => GetOrderInvoice(getIt<OrdersRepository>()),
    );
  }
  if (!getIt.isRegistered<ProcessDigitalPayment>()) {
    getIt.registerLazySingleton(
      () => ProcessDigitalPayment(getIt<OrdersRepository>()),
    );
  }

  // Profile UseCases
  if (!getIt.isRegistered<GetNotifications>()) {
    getIt.registerLazySingleton(
      () => GetNotifications(getIt<ProfileRepository>()),
    );
  }
  if (!getIt.isRegistered<MarkNotificationsRead>()) {
    getIt.registerLazySingleton(
      () => MarkNotificationsRead(getIt<ProfileRepository>()),
    );
  }
  if (!getIt.isRegistered<SyncDeviceFcmToken>()) {
    getIt.registerLazySingleton(
      () => SyncDeviceFcmToken(getIt<ProfileRepository>()),
    );
  }

  // =================================================================
  // 3. PRESENTATION LAYER — ViewModels (Factories agar state bersih per halaman)
  // =================================================================
  if (!getIt.isRegistered<AiInsightViewModel>()) {
    getIt.registerFactory<AiInsightViewModel>(
      () => AiInsightViewModel(
        getLatestVerifiedInsight: getIt<GetLatestVerifiedInsight>(),
        calculateQueueEstimate: getIt<CalculateQueueEstimate>(),
        getMenuRecommendation: getIt<GetMenuRecommendation>(),
      ),
    );
  }
  if (!getIt.isRegistered<AuthViewModel>()) {
    getIt.registerFactory<AuthViewModel>(
      () => AuthViewModel(
        loginUser: getIt<LoginUser>(),
        sendAuthOtp: getIt<SendAuthOtp>(),
        verifyAuthOtp: getIt<VerifyAuthOtp>(),
        resetPassword: getIt<ResetPassword>(),
      ),
    );
  }
  if (!getIt.isRegistered<CheckoutViewModel>()) {
    getIt.registerFactory<CheckoutViewModel>(
      () => CheckoutViewModel(
        validateCheckoutInput: getIt<ValidateCheckoutInput>(),
        calculateQueueEstimate: getIt<CalculateQueueEstimate>(),
      ),
    );
  }
  if (!getIt.isRegistered<MenuViewModel>()) {
    getIt.registerFactory<MenuViewModel>(
      () => MenuViewModel(
        getMenuCatalog: getIt<GetMenuCatalog>(),
        getOutlets: getIt<GetOutlets>(),
        getMenuRecommendation: getIt<GetMenuRecommendation>(),
      ),
    );
  }
  if (!getIt.isRegistered<OrdersViewModel>()) {
    getIt.registerFactory<OrdersViewModel>(
      () => OrdersViewModel(
        processDigitalPayment: getIt<ProcessDigitalPayment>(),
      ),
    );
  }
  if (!getIt.isRegistered<ProfileViewModel>()) {
    getIt.registerFactory<ProfileViewModel>(
      () => ProfileViewModel(
        getNotifications: getIt<GetNotifications>(),
        markNotificationsRead: getIt<MarkNotificationsRead>(),
      ),
    );
  }
}
