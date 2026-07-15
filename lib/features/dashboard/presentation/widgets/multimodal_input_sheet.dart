import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ai_orchestrator/providers/core_action_provider.dart';

class MultimodalInputSheet extends ConsumerStatefulWidget {
  const MultimodalInputSheet({super.key});

  @override
  ConsumerState<MultimodalInputSheet> createState() => _MultimodalInputSheetState();
}

class _MultimodalInputSheetState extends ConsumerState<MultimodalInputSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    // Send the text to the SLM Orchestrator
    await ref.read(coreActionNotifierProvider.notifier).submitRawPrompt(_controller.text);

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pop(context); // Close the bottom sheet on success
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gets the keyboard height so the sheet floats exactly above it
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset, left: 16, right: 16, top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What do you need to remember?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'e.g., "Remind me to call Mom at 5 PM" or "Spent 150 on coffee"',
              hintStyle: TextStyle(color: Colors.black26),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic, color: Color(0xFF6B4FA0)),
                    onPressed: () { /* TODO: Implement STT */ },
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF6B4FA0)),
                    onPressed: () { /* TODO: Implement OCR */ },
                  ),
                ],
              ),
              _isProcessing
                  ? const CircularProgressIndicator()
                  : FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4FA0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Process'),
                    ),
            ],
          )
        ],
      ),
    );
  }
}