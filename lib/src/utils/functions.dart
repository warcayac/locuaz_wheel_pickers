import 'package:flutter/material.dart';


/// Returns `true` if the UI that the user is *actually seeing* is in dark mode.
bool isDarkModeInUse(BuildContext context) => Theme.brightnessOf(context) == Brightness.dark;