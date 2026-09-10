import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt_result;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../ai_orchestrator/providers/core_action_provider.dart';

class MultimodalInputSheet extends ConsumerStatefulWidget {
  const MultimodalInputSheet({super.key});

  @override
  ConsumerState<MultimodalInputSheet> createState() => _MultimodalInputSheetState();
}

class _MultimodalInputSheetState extends ConsumerState<MultimodalInputSheet> {
  static const int _maxImageBytes = 25 * 1024 * 1024;
  static const Color _primaryColor = AppTheme.primaryColor;
  static const Color _borderColor = Color(0xFFE9E2F2);

  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isProcessing = false;
  bool _isListening = false;
  bool _hasVoiceSession = false;
  bool _speechAvailable = false;
  int _voiceMilliseconds = 0;
  int _speechSessionId = 0;
  int _waveTick = 0;
  double _soundLevel = 0;
  Timer? _voiceTimer;
  String _committedSpeechText = '';
  String _lastRecognizedWords = '';
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  @override
  void dispose() {
    _voiceTimer?.cancel();
    _speechToText.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prompt = _controller.text.trim().isEmpty && _selectedImage != null
        ? 'Attached image: ${_selectedImage!.name}'
        : _controller.text.trim();
    if (prompt.isEmpty) return;

    _voiceTimer?.cancel();
    await _speechToText.stop();

    setState(() => _isProcessing = true);

    await ref.read(coreActionNotifierProvider.notifier).submitRawPrompt(prompt);

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pop(context);
    }
  }

  Future<void> _startVoiceInput() async {
    if (_isListening) {
      return;
    }

    try {
      _speechAvailable = _speechAvailable ||
          await _speechToText.initialize(
            onStatus: (status) {
              if (!mounted) return;
            },
            onError: (error) {
              if (!mounted) return;
              setState(() => _isListening = false);
              AppFeedback.show(context, message: 'Speech recognition error: ${error.errorMsg}', icon: Icons.error_outline_rounded);
            },
          );
    } on MissingPluginException {
      if (!mounted) return;
      AppFeedback.show(context, message: 'Restart and rebuild the app to enable speech recognition.', icon: Icons.info_outline_rounded);
      return;
    }

    if (!_speechAvailable) {
      if (!mounted) return;
      AppFeedback.show(context, message: 'Speech recognition is not available on this device.', icon: Icons.info_outline_rounded);
      return;
    }

    _controller.clear();
    _voiceMilliseconds = 0;
    _committedSpeechText = '';
    _lastRecognizedWords = '';

    setState(() {
      _hasVoiceSession = true;
      _isListening = true;
    });
    final speechSessionId = ++_speechSessionId;
    _startVoiceTimer();
    try {
      await _speechToText.listen(
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 60),
        onSoundLevelChange: (level) {
          if (!mounted || speechSessionId != _speechSessionId || !_hasVoiceSession) return;
          setState(() => _soundLevel = level);
        },
        onResult: (result) {
          if (!mounted || speechSessionId != _speechSessionId || !_hasVoiceSession) return;
          setState(() {
            _setRecognizedSpeechText(result);
          });
        },
      );
    } on MissingPluginException {
      if (!mounted) return;
      setState(() => _isListening = false);
      _voiceTimer?.cancel();
      AppFeedback.show(context, message: 'Restart and rebuild the app to enable speech recognition.', icon: Icons.info_outline_rounded);
    }
  }

  Future<void> _deleteVoiceInput() async {
    _speechSessionId++;
    await _speechToText.stop();
    _voiceTimer?.cancel();
    setState(() {
      _controller.clear();
      _voiceMilliseconds = 0;
      _soundLevel = 0;
      _committedSpeechText = '';
      _lastRecognizedWords = '';
      _isListening = false;
      _hasVoiceSession = false;
    });
  }

  void _startVoiceTimer() {
    _voiceTimer?.cancel();
    _voiceTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted || !_hasVoiceSession) return;
      setState(() {
        if (_isListening) _voiceMilliseconds += 120;
        _waveTick += 1;
        _soundLevel *= 0.82;
      });
    });
  }

  void _setRecognizedSpeechText(stt_result.SpeechRecognitionResult result) {
    final recognizedWords = result.recognizedWords.trim();
    if (recognizedWords.isEmpty) return;

    if (_lastRecognizedWords.isNotEmpty &&
        recognizedWords != _lastRecognizedWords &&
        !recognizedWords.startsWith(_lastRecognizedWords) &&
        !_lastRecognizedWords.startsWith(recognizedWords)) {
      _committedSpeechText = _joinSpeechText(_committedSpeechText, _lastRecognizedWords);
    }

    _lastRecognizedWords = recognizedWords;
    final fullText = _joinSpeechText(_committedSpeechText, recognizedWords);
    _controller.text = fullText;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);

    if (result.finalResult) {
      _committedSpeechText = fullText;
      _lastRecognizedWords = '';
    }
  }

  String _joinSpeechText(String first, String second) {
    final left = first.trim();
    final right = second.trim();
    if (left.isEmpty) return right;
    if (right.isEmpty) return left;
    if (right.startsWith(left)) return right;
    if (left.endsWith(right)) return left;
    return '$left $right';
  }

  Future<void> _showImageSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt_rounded, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Take picture'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_rounded, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Choose image'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source, imageQuality: 92);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (bytes.length > _maxImageBytes) {
      if (!mounted) return;
      AppFeedback.show(context, message: 'Image must be 25 MB or smaller.', icon: Icons.error_outline_rounded);
      return;
    }

    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
    });
  }

  void _showImagePreview() {
    final bytes = _selectedImageBytes;
    if (bytes == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              InteractiveViewer(
                child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatImageSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
  }

  String _formatVoiceDuration() {
    final totalSeconds = _voiceMilliseconds ~/ 1000;
    final minutes = (totalSeconds ~/ 60).toString();
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    return Container(
      // Raise the sheet above the docked navigation without changing its
      // content-driven height. Avoid the extra offset while typing.
      margin: EdgeInsets.only(
        bottom: bottomInset + (isKeyboardVisible ? 0 : 80),
        left: 16,
        right: 16,
        top: 16,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedImageBytes != null) ...[
            _buildImagePreviewCard(),
            const SizedBox(height: 10),
          ],
          if (_hasVoiceSession)
            _buildVoiceComposer()
          else ...[
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
                    avatar: Icon(Icons.check_circle_outline_rounded, size: 16, color: colorScheme.primary),
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
                      icon: Icon(Icons.mic_rounded, color: colorScheme.primary),
                      tooltip: 'Voice dictation',
                      onPressed: _isProcessing ? null : _startVoiceInput,
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt_outlined, color: colorScheme.primary),
                      tooltip: 'Add image',
                      onPressed: _isProcessing ? null : _showImageSourcePicker,
                    )
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
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Process', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceComposer() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.delete_rounded, color: colorScheme.primary, size: 30),
              tooltip: 'Delete voice input',
              onPressed: _isProcessing ? null : _deleteVoiceInput,
            ),
            Expanded(
              child: _buildActiveVoiceBar(),
            ),
            IconButton(
              icon: Icon(Icons.send_rounded, color: colorScheme.primary, size: 34),
              tooltip: 'Send',
              onPressed: _isProcessing ? null : _submit,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildVoiceTranscriptField(),
      ],
    );
  }

  Widget _buildVoiceTranscriptField() {
    return TextField(
      controller: _controller,
      maxLines: 3,
      minLines: 1,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _submit(),
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Speech text will appear here',
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildActiveVoiceBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Expanded(child: _buildWaveform(color: colorScheme.onPrimary)),
          const SizedBox(width: 10),
          Text(
            _formatVoiceDuration(),
            style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform({required Color color}) {
    const heights = [8.0, 12.0, 8.0, 20.0, 26.0, 18.0, 30.0, 14.0, 10.0, 22.0, 34.0, 40.0, 28.0, 18.0, 12.0, 24.0];
    final activity = _soundLevel.clamp(0.0, 25.0) / 25;
    final isQuiet = (_isListening || _hasVoiceSession) && activity < 0.08;
    final activeDot = _waveTick % heights.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(heights.length, (index) {
        final waveOffset = (((index + _waveTick) % 5) - 2).abs() * 0.08;
        final soundScale = _isListening ? (0.22 + activity + waveOffset).clamp(0.16, 1.35) : 0.62;
        final adjustedHeight = isQuiet ? (index == activeDot ? 7.0 : 3.0) : heights[index] * soundScale;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: 4,
          height: adjustedHeight,
          decoration: BoxDecoration(
            color: isQuiet && index != activeDot ? color.withValues(alpha: 0.38) : color,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImagePreviewCard() {
    final bytes = _selectedImageBytes;
    final image = _selectedImage;
    if (bytes == null || image == null) return const SizedBox.shrink();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _showImagePreview,
      child: Container(
        height: 120,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6B4FA0).withValues(alpha: 0.18)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes, fit: BoxFit.cover),
            Positioned(
              left: 10,
              right: 48,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${image.name} - ${_formatImageSize(bytes.length)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _selectedImageBytes = null;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
