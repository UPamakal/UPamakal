import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/landing_view_model.dart'; // <-- required import
import 'services/auth_service.dart';

/// --------------------------------------------------------------------------
/// UPamakal — Entry Point
/// --------------------------------------------------------------------------
/// Initializes Firebase, sets up both ViewModels using MultiProvider,
/// then launches the root App widget.
/// --------------------------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final authService = AuthService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(authService: authService),
        ),
        ChangeNotifierProvider<LandingViewModel>(
          create: (context) =>
              LandingViewModel(),
        ),
      ],
      child: const UpamakalApp(),
    ),
  );
}
