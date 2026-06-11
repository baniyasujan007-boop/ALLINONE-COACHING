import 'dart:async';

import 'package:flutter/material.dart';

String _friendlyError(Object error) {
  final String message = error.toString().trim();
  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length).trim();
  }
  return message.isEmpty ? 'Update failed' : message;
}

Future<bool> submitEditableForm({
  required BuildContext context,
  GlobalKey<FormState>? formKey,
  required FutureOr<void> Function() submit,
  ValueChanged<bool>? setLoading,
  bool popOnSuccess = true,
  String successMessage = 'Updated successfully',
}) async {
  if (formKey != null && !(formKey.currentState?.validate() ?? false)) {
    return false;
  }

  setLoading?.call(true);
  try {
    await submit();
    if (!context.mounted) {
      return false;
    }

    setLoading?.call(false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));

    if (popOnSuccess && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
    return true;
  } catch (error) {
    if (!context.mounted) {
      return false;
    }
    setLoading?.call(false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    return false;
  }
}
