import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dark mode only for now — toggle to be added in a future update
final themeProvider = Provider<ThemeMode>((_) => ThemeMode.dark);