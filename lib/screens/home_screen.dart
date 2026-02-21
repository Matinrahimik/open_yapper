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
    final theme = Theme.of(context);
    final hasRecording = recordingService.latestEntry != null;
    final isRecording = recordingService.isRecording;
    final isProcessing = recordingService.isProcessing;
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      isRecording
                          ? Symbols.mic
                          : isProcessing
                              ? Symbols.psychology
                              : Symbols.mic_none,
                      size: 64,
                      color: isRecording
                          ? theme.colorScheme.error
                          : isProcessing
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    recordingService.statusText,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Press ⌥ Space anywhere to start recording',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (recordingService.lastError != null) ...[
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Symbols.warning_amber,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recordingService.lastError!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => recordingService.clearLastError(),
                            child: Text(
                              'Dismiss',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (recordingService.latestEntry != null) ...[
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Last Interaction',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              const Spacer(),
                              if (recordingService.latestEntry?.targetApp !=
                                  null)
                                Text(
                                  '→ ${recordingService.latestEntry!.targetApp}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              recordingService.latestEntry!.displayText,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                    if (recordingService.latestEntry?.displayText.isNotEmpty ==
                        true)
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: recordingService.latestEntry!.displayText,
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard')),
                          );
                        },
                        icon: const Icon(Symbols.content_copy, size: 18),
                        label: const Text('Copy'),
                      ),
                    if (recordingService.latestEntry?.displayText.isNotEmpty ==
                        true)
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
                  isProcessing: isProcessing,
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

class _RecordButton extends StatefulWidget {
  const _RecordButton({
    required this.isRecording,
    required this.isProcessing,
    required this.onPressed,
  });

  final bool isRecording;
  final bool isProcessing;
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
        onPressed: widget.isProcessing ? null : widget.onPressed,
        icon: Icon(
          widget.isRecording ? Symbols.stop : Symbols.mic,
          size: 24,
        ),
        label: Text(
          widget.isRecording ? 'Stop Recording' : 'Start Recording',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: widget.isRecording
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      ),
    );
  }
}
