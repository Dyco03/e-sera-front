import 'package:e_sera/app.dart';
import 'package:e_sera/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  //firebase setup
  WidgetsFlutterBinding.ensureInitialized(); // for async setup and Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //supabase setup
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  //run app
  runApp(MyApp());
}
