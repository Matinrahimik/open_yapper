import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A TextField that reliably handles Cmd+V (paste) on macOS.
/// Wraps the standard TextField with Shortcuts and Actions so paste works
/// even when the platform paste doesn't reach the field.
class PasteableTextField extends StatefulWidget {
  const PasteableTextField({
    super.key,
    required this.controller,
    this.decoration,
    this.maxLines = 1,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.cursorColor,
  });

  final TextEditingController controller;
  final InputDecoration? decoration;
  final int? maxLines;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final Color? cursorColor;

  @override
  State<PasteableTextField> createState() => _PasteableTextFieldState();
}

class _PasteableTextFieldState extends State<PasteableTextField> {
  void _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) return;

    final ctrl = widget.controller;
    final sel = ctrl.selection;
    final start = sel.start.clamp(0, ctrl.text.length);
    final end = sel.end.clamp(0, ctrl.text.length);
    final newText = ctrl.text.replaceRange(start, end, text);
    ctrl.text = newText;
    ctrl.selection = TextSelection.collapsed(offset: start + text.length);
    widget.onChanged?.call(newText);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyV, meta: true): PasteIntent(),
        SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteIntent(),
      },
      child: Actions(
        actions: {
          PasteIntent: CallbackAction<PasteIntent>(
            onInvoke: (_) {
              _handlePaste();
              return null;
            },
          ),
        },
        child: TextField(
          controller: widget.controller,
          decoration: widget.decoration,
          maxLines: widget.maxLines,
          obscureText: widget.obscureText,
          cursorColor: widget.cursorColor,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          readOnly: widget.readOnly,
        ),
      ),
    );
  }
}

class PasteIntent extends Intent {
  const PasteIntent();
}
