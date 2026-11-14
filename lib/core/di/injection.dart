import 'package:get_it/get_it.dart';
import '../../features/ai_insight/data/repositories/ai_insight_repository.dart';

final getIt = GetIt.instance;

void setupLocator() {
  if (!getIt.isRegistered<AiInsightRepository>()) {
    getIt.registerLazySingleton<AiInsightRepository>(
        () => AiInsightRepositoryImpl());
  }
}
