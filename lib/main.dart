import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/landing_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/chat_view_model.dart';
import 'services/auth_service.dart';
import 'services/listing_service.dart';
import 'services/chat_service.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authService = AuthService();
  final listingService = ListingService();
  final chatService = ChatService();
  final fcmService = FCMService();

  runApp(
    MultiProvider(
      providers: [
        // Expose ListingService itself so any widget deeper in the tree
        // (e.g. SearchViewModel created inside a pushed route) can read it
        // via context.read<ListingService>() without a ProviderNotFoundException.
        Provider<ListingService>(
          create: (_) => listingService,
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(authService: authService),
        ),
        ChangeNotifierProvider<LandingViewModel>(
          create: (context) => LandingViewModel(),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, ChatViewModel>(
          create: (context) => ChatViewModel(
            chatService: chatService,
            fcmService: fcmService,
            currentUserId: '',
          ),
          update: (context, authVM, chatVM) => ChatViewModel(
            chatService: chatService,
            fcmService: fcmService,
            currentUserId: authVM.user?.uid ?? '',
          ),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(listingService: listingService),
        ),
      ],
      child: const UpamakalApp(),
    ),
  );
}