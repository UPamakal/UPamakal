import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';  // <-- add this import
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
import 'services/user_service.dart';
import 'views/chat_detail_page.dart';
import 'repositories/user_repository.dart';

void main() async {
  // Ensure Flutter binding is initialized (required for both Firebase and splash)
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the native splash screen – it will stay visible until we call remove()
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create service instances (these are synchronous)
  final authService = AuthService();
  final listingService = ListingService();
  final chatService = ChatService();
  final fcmService = FCMService();
  final navigatorKey = GlobalKey<NavigatorState>();

  // Set up chat open handler for notifications
  fcmService.setChatOpenHandler((chatRoomId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final authVM = context.read<AuthViewModel>();
    final currentUserId = authVM.user?.uid;
    if (currentUserId == null) return;

    final room = await chatService.getChatRoom(chatRoomId);
    if (room == null || !room.participants.contains(currentUserId)) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => ChatDetailPage(chatRoom: room)),
    );
  });

  // All async initialization is done – remove the splash screen
  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        Provider<ListingService>(
          create: (_) => listingService,
        ),
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authService: authService,
            userRepository: UserRepository(),
          ),
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
          update: (context, authVM, chatVM) {
            final vm = chatVM ??
                ChatViewModel(
                  chatService: chatService,
                  fcmService: fcmService,
                  currentUserId: '',
                );
            vm.updateCurrentUser(authVM.user?.uid ?? '');
            return vm;
          },
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(listingService: listingService),
        ),
      ],
      child: UpamakalApp(navigatorKey: navigatorKey),
    ),
  );
}