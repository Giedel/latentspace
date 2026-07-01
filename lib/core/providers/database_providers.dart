import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latentspace/core/database/database_service.dart';
import 'package:latentspace/features/ai_orchestrator/data/core_action_repository.dart';

// Provides the singleton instance of the DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Provides the CoreActionRepository, allowing any part of the app to read/write to the ledger
final coreActionRepositoryProvider = Provider<CoreActionRepository>((ref) {
  return CoreActionRepository();
});