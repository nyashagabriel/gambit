// lib/main.dart — GAMBIT TSL
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "app.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait on phones; allow landscape on tablets/web
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:      Colors.transparent,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const GambitApp());
}