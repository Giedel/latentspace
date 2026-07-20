import '../../../core/database/action_dependency_repository.dart';
import '../data/core_action_repository.dart';
import '../models/core_ai_action.dart';
import 'slm_inference_engine.dart';

class SlmService {
  final SlmInferenceEngine _engine = SlmInferenceEngine();
  final CoreActionRepository _repo = CoreActionRepository();
  final ActionDependencyRepository _dependencyRepo = ActionDependencyRepository();

  /// Processes raw multimodal input via the SLM Inference Engine semantic middleware
  Future<CoreAiAction> processInput(String prompt) async {
    // Run local quantized SLM semantic middleware inference
    final result = await _engine.runInference(prompt);

    // Save primary action
    await _repo.insert(result.primaryAction);

    // Save any sub-actions and DAG dependency links
    for (var subAction in result.subActions) {
      await _repo.insert(subAction);
    }
    for (var dep in result.dependencies) {
      await _dependencyRepo.addDependency(dep);
    }

    return result.primaryAction;
  }
}