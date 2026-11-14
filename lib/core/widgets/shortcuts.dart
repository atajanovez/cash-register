import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// ⌘ on macOS, Ctrl elsewhere.
bool get _mac => defaultTargetPlatform == TargetPlatform.macOS;

/// [key] with the platform's command modifier.
SingleActivator cmd(LogicalKeyboardKey key, {bool shift = false}) =>
    SingleActivator(key, meta: _mac, control: !_mac, shift: shift);

/// "⌘N" / "Ctrl+N", for tooltips.
String shortcutLabel(String key, {bool shift = false}) =>
    _mac ? '${shift ? '⇧' : ''}⌘$key' : 'Ctrl+${shift ? 'Shift+' : ''}$key';

/// Keyboard shortcuts for desktop that work wherever the focus is.
///
/// Each instance registers its [bindings] while it is on screen. One
/// keyboard handler tries the newest registration first, skipping those
/// under a dialog or in a hidden tab, so a register page's ⌘F wins over the
/// list's while it is open, and nothing fires behind an open dialog.
///
/// Keys without ⌘/Ctrl (arrows) are ignored while typing, except in
/// [textField].
class KeyboardShortcuts extends StatefulWidget {
  const KeyboardShortcuts({
    super.key,
    required this.bindings,
    required this.child,
    this.textField,
  });

  final Map<SingleActivator, VoidCallback> bindings;
  final FocusNode? textField;
  final Widget child;

  @override
  State<KeyboardShortcuts> createState() => _KeyboardShortcutsState();
}

class _KeyboardShortcutsState extends State<KeyboardShortcuts> {
  static final _active = <_KeyboardShortcutsState>[];

  @override
  void initState() {
    super.initState();
    if (_active.isEmpty) HardwareKeyboard.instance.addHandler(_handle);
    _active.add(this);
  }

  @override
  void dispose() {
    _active.remove(this);
    if (_active.isEmpty) HardwareKeyboard.instance.removeHandler(_handle);
    super.dispose();
  }

  bool get _onScreen =>
      mounted &&
      TickerMode.valuesOf(context).enabled &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  static bool _typing(FocusNode? allowed) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus == allowed) return false;
    final context = focus.context;
    return context != null &&
        (context.widget is EditableText ||
            context.findAncestorWidgetOfExactType<EditableText>() != null);
  }

  static bool _handle(KeyEvent event) {
    if (event is KeyUpEvent) return false;
    for (final state in _active.reversed.toList()) {
      if (!state._onScreen) continue;
      for (final MapEntry(key: activator, value: action)
          in state.widget.bindings.entries) {
        if (!activator.accepts(event, HardwareKeyboard.instance)) continue;
        final plain = !activator.control && !activator.meta;
        if (plain && _typing(state.widget.textField)) continue;
        action();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
