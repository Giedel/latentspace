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

    await ref.read(coreActionNotifierProvider.notifier).submitRawPrompt(_controller.text);

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pop(context);
    }
  }

  void _simulateVoice() {
    const voiceExamples = [
      'Remind me to call Mom today at 5 PM',
      'Spent 150 pesos on coffee at Starbucks',
      'Don\'t forget to pay internet bill of 2500 tomorrow',
      'Idea: Build a Flutter app with local AI capabilities',
    ];
    final selected = (voiceExamples..shuffle()).first;
    setState(() {
      _controller.text = selected;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voice transcribed: "$selected"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _simulateOcr() {
    const ocrExamples = [
      'Receipt: Paid 480.00 for grocery items',
      'Invoice: Electricity bill 3200 PHP due on Friday',
      'Note scan: Team sync meeting on Monday morning',
    ];
    final selected = (ocrExamples..shuffle()).first;
    setState(() {
      _controller.text = selected;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanned text from camera: "$selected"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'What do you need to remember?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'e.g., "Remind me to call Mom at 5 PM" or "Spent 150 on coffee"',
              hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          
          // Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.coffee_rounded, size: 16, color: Colors.orange),
                  label: const Text('Spent 150 on coffee', style: TextStyle(fontSize: 12)),
                  onPressed: () => setState(() => _controller.text = 'Spent 150 on coffee'),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF6B4FA0)),
                  label: const Text('Remind me to call Mom at 5 PM', style: TextStyle(fontSize: 12)),
                  onPressed: () => setState(() => _controller.text = 'Remind me to call Mom at 5 PM'),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.amber),
                  label: const Text('Idea for mobile app', style: TextStyle(fontSize: 12)),
                  onPressed: () => setState(() => _controller.text = 'Idea for mobile app layout design'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic_rounded, color: Color(0xFF6B4FA0)),
                    tooltip: 'Voice Dictation (STT)',
                    onPressed: _simulateVoice,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF6B4FA0)),
                    tooltip: 'Document OCR Scan',
                    onPressed: _simulateOcr,
                  ),
                ],
              ),
              _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4FA0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Process', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ],
          )
        ],
      ),
    );
  }
}