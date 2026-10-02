import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';

void showError(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: AppText(message)));
