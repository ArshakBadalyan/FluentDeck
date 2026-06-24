import 'package:flutter/material.dart';

MaterialPageRoute<T> matheMaterialPageRoute<T>({
  required String name,
  required Widget Function(BuildContext context) builder,
  bool fullscreenDialog = false,
}) {
  return MaterialPageRoute<T>(
    settings: RouteSettings(name: name),
    fullscreenDialog: fullscreenDialog,
    builder: builder,
  );
}
