import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../providers/core_action_provider.dart';
import '../../services/slm_model_manager.dart';

class SlmModelCard extends ConsumerWidget {
  const SlmModelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelManager = ref.watch(slmModelManagerProvider);
    final status = modelManager.status;

    return CustomCard(
      backgroundColor: const Color(0xFFF3E5F5).withValues(alpha: 0.6),
      border: Border.all(color: const Color(0xFF6B4FA0).withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4FA0).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.memory_rounded, color: Color(0xFF6B4FA0), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modelManager.modelInfo.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        modelManager.modelInfo.quantization,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              _buildStatusBadge(context, status),
            ],
          ),
          if (status == SlmModelStatus.downloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: modelManager.downloadProgress,
              backgroundColor: Colors.purple.shade50,
              color: const Color(0xFF6B4FA0),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Downloading additional SLM model binary...', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('${(modelManager.downloadProgress * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            )
          ] else if (status == SlmModelStatus.notDownloaded) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Size: ${modelManager.modelInfo.sizeMB.toInt()} MB',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(slmModelManagerProvider).downloadModelResource();
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download Model', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4FA0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                )
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, SlmModelStatus status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case SlmModelStatus.ready:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        text = 'SLM Ready';
        break;
      case SlmModelStatus.downloading:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        text = 'Downloading...';
        break;
      case SlmModelStatus.notDownloaded:
        bg = Colors.orange.shade100;
        fg = Colors.deepOrange;
        text = 'Resource Required';
        break;
      case SlmModelStatus.error:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        text = 'Download Error';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
