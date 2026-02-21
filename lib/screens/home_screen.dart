import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/recording_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.recordingService,
  });

  final RecordingService recordingService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: recordingService,
        builder: (context, _) {
          if (recordingService.initError != null) {
            return _ErrorContent(
              message: 'Recording error: ${recordingService.initError}',
            );
          }

          if (!recordingService.hasPermission) {
            return _PermissionContent();
          }

          return _RecordingContent(recordingService: recordingService);
        },
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.mic,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Microphone permission is required for voice recording.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingContent extends StatelessWidget {
  const _RecordingContent({required this.recordingService});

  final RecordingService recordingService;

  @override
  Widget build(BuildContext context) {
    final hasRecording = recordingService.hasRecording;
    final isRecording = recordingService.isRecording;
    final isPlaying = recordingService.isPlaying;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isRecording)
                    Text(
                      'Recording...',
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                  else if (hasRecording)
                    _TranscriptionDisplay(
                      transcription: recordingService.latestEntry?.transcription,
                    )
                  else
                    Text(
                      'Press hotkey or tap record to capture your voice',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasRecording)
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: recordingService.togglePlayback,
                      icon: Icon(
                        isPlaying ? Symbols.stop : Symbols.play_arrow,
                        size: 24,
                      ),
                      label: Text(isPlaying ? 'Stop' : 'Play'),
                    ),
                    const SizedBox(width: 8),
                    if (recordingService.latestEntry?.transcription != null)
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: recordingService.latestEntry!.transcription!,
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard')),
                          );
                        },
                        icon: Icon(Symbols.content_copy, size: 18),
                        label: const Text('Copy'),
                      ),
                    if (recordingService.latestEntry?.transcription != null)
                      const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: recordingService.clearRecording,
                      icon: const Icon(Symbols.delete_outline, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: _RecordButton(
                  isRecording: isRecording,
                  onPressed: recordingService.toggleRecording,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TranscriptionDisplay extends StatelessWidget {
  const _TranscriptionDisplay({this.transcription});

  final String? transcription;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (transcription != null && transcription!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                transcription!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Press play to listen back',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ] else ...[
            Icon(
              Symbols.audio_file,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Transcribing...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Press play to listen back',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordButton extends StatefulWidget {
  const _RecordButton({
    required this.isRecording,
    required this.onPressed,
  });

  final bool isRecording;
  final VoidCallback onPressed;

  @override
  State<_RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<_RecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.isRecording ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: FilledButton.icon(
        onPressed: widget.onPressed,
        icon: Icon(
          widget.isRecording ? Symbols.stop : Symbols.mic,
          size: 24,
        ),
        label: Text(widget.isRecording ? 'Stop' : 'Record'),
        style: FilledButton.styleFrom(
          backgroundColor: widget.isRecording
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      ),
    );
  }
}
