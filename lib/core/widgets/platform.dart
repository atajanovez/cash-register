import 'package:flutter/material.dart';

/// Desktop has a hardware keyboard, so focusing the first field on open helps.
/// On touch devices it would pop the on-screen keyboard over the form instead.
bool shouldAutofocus(BuildContext context) =>
    switch (Theme.of(context).platform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };
