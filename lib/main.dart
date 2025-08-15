import 'package:agencedevoyage/aboutus.dart';
// import 'package:agencedevoyage/admin/admin.dart';
import 'package:agencedevoyage/admin/adminUsers.dart';
import 'package:agencedevoyage/admin/adminwrap.dart';
import 'package:agencedevoyage/api/firebase_api.dart';
import 'package:agencedevoyage/help.dart';
import 'package:agencedevoyage/homepage.dart';
import 'package:agencedevoyage/notifscreen.dart';
import 'package:agencedevoyage/paymentInfoPage.dart';
import 'package:agencedevoyage/profile_screen.dart';
import 'package:agencedevoyage/securite.dart';
import 'package:agencedevoyage/signin_screen.dart';
import 'package:agencedevoyage/vol/baggage.dart';
import 'package:agencedevoyage/vol/reservationsteps.dart';
import 'package:agencedevoyage/vol/seat_selection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseApi().initialize();
  // Configurer FCM
  FirebaseMessaging.onBackgroundMessage(FirebaseApi.backgroundHandler);
  try {
    // Configurer FCM

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Enregistrer le token avec gestion d'erreur
    final token = await messaging.getToken();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && token != null) {
      try {
        await FirebaseFirestore.instance
            .collection('userTokens')
            .doc(user.uid)
            .set({'token': token}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Erreur enregistrement token: $e');
      }
    }

    // Écouter les nouveaux tokens
    messaging.onTokenRefresh.listen((newToken) async {
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('userTokens')
              .doc(user.uid)
              .set({'token': newToken}, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Erreur mise à jour token: $e');
        }
      }
    });

    await EasyLocalization.ensureInitialized();

    runApp(
      ProviderScope(
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          path: 'assets/lang',
          fallbackLocale: const Locale('fr'),
          child: const Travelapp(),
        ),
      ),
    );
  } catch (e) {
    debugPrint('Erreur initialisation Firebase: $e');
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Erreur d\'initialisation'.tr()),
        ),
      ),
    );
  }
}

// runApp(
// ProviderScope(
// child: MaterialApp(
// theme: AppTheme.lightTheme,
// home: StreamBuilder<User?>(
// stream: FirebaseAuth.instance.authStateChanges(),
// builder: (context, snapshot) {
// if (snapshot.connectionState == ConnectionState.waiting) {
// return const Center(child: CircularProgressIndicator());
// }
// return snapshot.hasData ? const HomeScreen() : const AuthPage();
// },
// ),
// ),
// ),
// );
// }

// Ajoutez une clé globale pour la navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class Travelapp extends StatelessWidget {
  const Travelapp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,

      theme: ThemeData(
        primaryColor: Colors.blue[800],
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.amber,
        ),
        fontFamily: 'PlayfairDisplay',
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      title: 'Agence De Voyage'.tr(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomePage(),
        '/HomePage': (context) => HomePage(),
        '/AuthPage': (context) => AuthPage(),
        '/profile': (context) => ProfileScreen(),
        '/payment': (context) => PaymentInfoPage(),
        '/security': (context) => SecurityPage(),
        '/help': (context) => ChatHelpPage(),
        '/reservationSteps': (context) => ReservationStepsPage(),
        '/aboutus': (context) => AboutUsPage(),
        // '/adminDashboard': (context) =>
        //     AdminRouteGuard(child: AdminDashboard()),
        '/admin/users': (context) => AdminRouteGuard(child: AdminUsersPage()),
        '/luggageSelection': (context) => const LuggageSelectionPage(),
        NotificationsScreen.route: (_) => const NotificationsScreen(),
        'seatSelection': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return SeatSelectionWidget(
            basePrice: args?['basePrice'] ?? 0.0, // Valeur par défaut si null
          );
        },
      },
      onGenerateRoute: (settings) {
        // Gestion des liens de vérification d'email

        if (settings.name == '/auth') {
          return MaterialPageRoute(builder: (context) => AuthPage());
        }
        return null;
      },
      // Gestion du premier lancement via un lien
    );
  }
}
// home: HomePage(),
// home: StreamBuilder<User?>(
// stream: FirebaseAuth.instance.authStateChanges(),
// builder: (context, snapshot) {
// if (snapshot.connectionState == ConnectionState.waiting) {
// return const Center(child: CircularProgressIndicator());
// }
// if (snapshot.hasData) {
// return const HomePage(); // Utilisateur connecté
//  }
// return const HomePage(); // Non connecté
// },
// ),
// );
// }
// }

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  WelcomePageState createState() => WelcomePageState();
}

class WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  // late Animation _bounceAnimation;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _showButton = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset('assets/welcomfin.webm')
      ..initialize().then((_) {
        setState(() => _isVideoInitialized = true);
        _videoController.setLooping(true);
        _videoController.play();
      });

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showButton = true);
    });

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isVideoInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.08,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'Vaccancia',
                    textStyle: const TextStyle(
                      fontSize: 40.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PlayfairDisplay',
                      color: Color.fromARGB(255, 255, 255, 255),
                      shadows: [
                        Shadow(
                          blurRadius: 30.0,
                          color: Colors.black54,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    speed: const Duration(milliseconds: 200),
                  ),
                ],
                totalRepeatCount: 1,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              opacity: _showButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 350),
              child: Container(
                width: 350.0, // Largeur fixe
                height: 66, // Hauteur fixe
                margin: const EdgeInsets.only(bottom: 30.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SecondPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(181, 36, 126, 171),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minWidth: 320),
                    child: Text(
                      'welcome',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: Color.fromARGB(255, 247, 246, 246),
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _titleAnimation;
  final List<String> _features = [
    'Réservation d\'hôtel de luxe 🏨'.tr(),
    'Location de voiture premium 🚗'.tr(),
    'Billets & Événements exclusifs ✈️'.tr(),
    'Maisons de vacances exceptionnelles 🏡'.tr(),
    'Promotions exclusives 💎'.tr()
  ];
  int _visibleFeatureIndex = -1;
  bool _showButton = false;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _showSlideButton = false;
  double _dragPercent = 0.0;

  void navigateToHomePage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset('assets/welcom2fin.webm')
      ..initialize().then((_) {
        setState(() => _isVideoInitialized = true);
        _videoController.setLooping(true);
        _videoController.play();
      });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _titleAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: const Offset(0.0, 0.20),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _controller.forward().then((_) => _animateFeaturesSequentially());
      }
    });
  }

  void _animateFeaturesSequentially() async {
    for (int i = 0; i < _features.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _visibleFeatureIndex = i);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showButton = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isVideoInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _titleAnimation,
              child: const Text(
                'Vaccancia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PlayfairDisplay',
                  color: Color.fromARGB(255, 220, 227, 236),
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 15,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 200),
            child: ListView.builder(
              itemCount: _features.length,
              itemBuilder: (context, index) {
                return AnimatedOpacity(
                  opacity: _visibleFeatureIndex >= index ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutQuint,
                  child: AnimatedPadding(
                    padding: EdgeInsets.only(
                      left: _visibleFeatureIndex >= index ? 5.0 : 10.0,
                      top: 0,
                    ),
                    duration: const Duration(milliseconds: 800),
                    child: _FeatureItem(
                      text: _features[index],
                      delay: index * 100,
                      index: 0,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 20,
            child: AnimatedOpacity(
              opacity: _showButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(163, 58, 124, 165),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                ),
                onPressed: () => setState(() {
                  _showSlideButton = true;
                  _showButton = false;
                }),
                child: Text(
                  'Découvrir plus'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (_showSlideButton)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPercent += details.primaryDelta! / 200;
                      _dragPercent = _dragPercent.clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragPercent > 0.7) {
                      navigateToHomePage(context);
                    }
                    setState(() => _dragPercent = 0.0);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 290,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: const Color.fromARGB(185, 255, 255, 255)
                              .withValues(),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _dragPercent > 0.7
                              ? "Let's go 🛫!!"
                              : "      Prêt pour l'aventure ! 🛫".tr(),
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A5C82),
                          ),
                        ),
                      ),
                      Positioned(
                        left: _dragPercent * 230,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF2A5C82), Color(0xFF3A7CA5)],
                            ),
                          ),
                          child: const Icon(
                            Icons.airplanemode_active,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  final int index;
  final int delay;

  const _FeatureItem({
    required this.text,
    required this.index,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (delay)),
      builder: (context, value, child) {
        return Transform(
          transform: Matrix4.identity()
            ..translate((1 - value) * 50.0)
            ..scale(value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber[300], size: 24),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
