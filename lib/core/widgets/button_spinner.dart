import 'package:flutter/material.dart';

/// Progress indicator sized to sit inside a button while it is busy.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 22,
    child: CircularProgressIndicator(
      strokeWidth: 2.5,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
