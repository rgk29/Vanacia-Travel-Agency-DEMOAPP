import 'dart:async';

import 'package:agencedevoyage/api/firebase_api.dart';
import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/destination.dart';
import 'package:agencedevoyage/favoriepage.dart';
import 'package:agencedevoyage/help.dart';
import 'package:agencedevoyage/hotels/data.dart';
import 'package:agencedevoyage/hotels/details.dart';
import 'package:agencedevoyage/hotels/local.dart';
import 'package:agencedevoyage/hotels/rechercher.dart';
import 'package:agencedevoyage/notifscreen.dart';
import 'package:agencedevoyage/profile_screen.dart';
import 'package:agencedevoyage/resumer.dart';
import 'package:agencedevoyage/vol/search_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:agencedevoyage/voiture/recherche.dart';
import 'package:agencedevoyage/voyageOrganiser/trip.dart';
import 'package:agencedevoyage/voyageOrganiser/trips_list_page.dart';
import 'package:agencedevoyage/voyageOrganiser/trip_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseApi _firebaseApi =
      FirebaseApi(); // Ajout de l'instance FirebaseApi
  int _notificationCount = 0; // Compteur de notifications

  final List<Widget> _getpages = [
    const HomeContent(),
    MesReservationsPage(),
    FavoritesPage(), // Page favoris
    const SizedBox(), // Page profil
  ];
  @override
  void initState() {
    super.initState();
    // Écoute des notifications pour mettre à jour le compteur
    _firebaseApi.notificationStream.listen((_) {
      setState(() => _notificationCount++);
      _setupNotifications();
    });
  }

  void _setupNotifications() {
    FirebaseApi.instance.notificationStream.listen((message) {
      if (message.data['type'] == 'new_user' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.body ?? ''),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else if (index == 2) {
      // Favoris
      // Optionnel : Rafraîchir les favoris si nécessaire
      setState(() => _selectedIndex = index);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _getpages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A5C82), Color(0xFF3AB0D5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.white, Color(0xFFF5A623)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds),
        child: Text(
          'Vacancia',
          style: TextStyle(
            fontSize: 28,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.white.withOpacity(0.3),
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.language),
        onPressed: _showLanguageDialog,
      ),
      // Ajout de l'icône de notifications ici
      actions: [
        ValueListenableBuilder<int>(
          valueListenable: FirebaseApi.instance.notificationCount,
          builder: (context, count, _) {
            return Stack(
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () async {
                    await Navigator.pushNamed(
                        context, NotificationsScreen.route);
                    // Quand on revient de la page notifications, reset le compteur
                    FirebaseApi.instance.resetNotificationCounter();
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('sign_in_Page'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildLanguageOption('Français', 'fr', 'assets/flags/france.png'),
              _buildLanguageOption('العربية', 'ar', 'assets/flags/arabic.png'),
              _buildLanguageOption('English', 'en', 'assets/flags/english.png'),
            ],
          ),
        ),
      ),
    );
  }

  ListTile _buildLanguageOption(String label, String code, String flag) {
    return ListTile(
      leading: Image.asset(flag, width: 32),
      title: Text(label),
      onTap: () {
        context.setLocale(Locale(code));
        Navigator.pop(context);
        setState(() {});
      },
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: 'home'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.app_registration),
          label: 'Mes_Réservations'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.favorite_border),
          label: 'favorites'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          label: 'profile'.tr(),
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xFF2A5C82),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      onTap: _onItemTapped,
    );
  }
}

// Le reste de votre code existant pour HomeContent et les autres classes...

// Ajoutez ces classes de pages factices pour la démonstration

class FlightPage extends StatelessWidget {
  const FlightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vols')),
      body: Center(child: Text('Page des Vols')),
    );
  }
}

class HotelPage extends StatelessWidget {
  const HotelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hôtels')),
      body: Center(child: Text('Page des Hôtels')),
    );
  }
}

class TourPage extends StatelessWidget {
  const TourPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voyages Organisés')),
      body: Center(child: Text('Page des Voyages Organisés')),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  double get cardAspectRatio =>
      MediaQuery.of(context).size.aspectRatio > 0.8 ? 1.5 : 1.8;
  double get cardWidth => MediaQuery.of(context).size.width * 0.8;

  final List<Hotells> hotels = localHotels;
  bool _showWelcomeCard = true;
  final Duration _animationDuration = const Duration(milliseconds: 800);
  final List<Trip> trips = getOrganizedTrips(); // Récupérez les voyages
  final selectedTrip =
      getOrganizedTrips().first; // Adaptez selon votre flux de données

  // Ne garder que les hôtels en promotion
  List<Hotells> get _promoHotels =>
      hotels.where((h) => h.hasPromotion).toList();

  int _currentMessageIndex = 0;
  final List<String> _promoMessages = [
    'promo_1',
    'promo_2',
    'promo_3',
    'promo_4',
    'promo_5'
  ];
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _startMessageRotation();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _startMessageRotation() {
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _promoMessages.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildOffersSection()),
        SliverToBoxAdapter(child: _buildPopularDestinations()),
        SliverToBoxAdapter(child: _buildHelpSection()),
      ],
    );
  }

  Widget _buildOffersSection() {
    // Calculer seulement les hôtels en promo + la welcome card si visible
    final int itemCount = _promoHotels.length + (_showWelcomeCard ? 1 : 0);

    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(20),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (_showWelcomeCard && index == 0) {
            return AnimatedSwitcher(
              duration: _animationDuration,
              child: _buildWelcomeCard(),
            );
          }
          // Ajuster l'index pour les offres
          final hotel = _promoHotels[_showWelcomeCard ? index - 1 : index];
          return _buildHotelOfferCard(hotel);
        },
      ),
    );
  }

  Widget _buildHotelOfferCard(Hotells hotel) {
    final double width = MediaQuery.of(context).size.width * 0.8;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelDetailsScreen(hotel: hotel),
        ),
      ),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 20),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  hotel.thumbnailUrl,
                  height: 260,
                  width: width,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 200, 72, 68),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${hotel.discountPercentage}% ${'promo'.tr()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer(
                        builder: (context, ref, _) {
                          // Listen to currency changes
                          ref.watch(currencyProvider);
                          final notifier = ref.read(currencyProvider.notifier);
                          final formattedPrice =
                              notifier.formatPrice(hotel.pricePerNight);
                          return Text(
                            '$formattedPrice/${'night'.tr()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return GestureDetector(
      onTap: () => setState(() => _showWelcomeCard = false),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0062E6), Color(0xFF33A1FD)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône animée
              Icon(
                Icons.percent_rounded,
                size: 50,
                color: Colors.white,
              ).animate().scale(duration: 800.ms),

              const SizedBox(height: 15),

              // Contenu textuel animé
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _promoMessages[_currentMessageIndex].tr(),
                  key: ValueKey<String>(_promoMessages[_currentMessageIndex]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _currentMessageIndex == _promoMessages.length - 1
                        ? 18
                        : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Ajouter le paramètre context
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.3, // Utiliser la variable calculée
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/BeautyofVenice.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(),
              Colors.transparent,
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'discover_world'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildServiceIcon(
                      context,
                      icon: Icons.flight,
                      label: 'flight'.tr(),
                      page: FlightSearchPage(),
                    ),
                    _buildServiceIcon(
                      context,
                      icon: Icons.hotel,
                      label: 'hotel'.tr(),
                      page: HotelSearchScreen(),
                    ),
                    _buildServiceIcon(
                      context,
                      icon: Icons.directions_car,
                      label: 'car'.tr(),
                      page: CarPage(),
                    ),
                    _buildServiceIcon(
                      context,
                      icon: Icons.assignment,
                      label: 'organized_trip'.tr(),
                      page: TripsListPage(
                          trips:
                              trips), // Utilisez TripsListPage avec la liste des voyages
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceIcon(BuildContext context,
      {required IconData icon, required String label, required Widget page}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFF2A5C82), size: 30),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Hotells hotel) {
    final double width = MediaQuery.of(context).size.width * 0.8;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelDetailsScreen(hotel: hotel),
        ),
      ),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 20),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  hotel.thumbnailUrl,
                  height: 260,
                  width: width,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 200, 72, 68),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${hotel.discountPercentage}% ${'promo'.tr()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${hotel.pricePerNight.toStringAsFixed(0)} DA/nuit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // :///////////////////////////
  Widget _buildPopularDestinations() {
    // Liste des destinations populaires avec leurs images
    final List<Map<String, dynamic>> popularDestinations = [
      {
        'city': 'Paris',
        'country': 'France',
        'image': 'assets/paris.jpg',
      },
      {
        'city': 'Barcelone',
        'country': 'Espagne',
        'image': 'assets/barcelona.jpg',
      },
      {
        'city': 'Alger',
        'country': 'Algérie',
        'image': 'assets/capital.jpg',
      },
      {
        'city': 'Oran',
        'country': 'Algérie',
        'image': 'assets/whran.jpg',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Destinations_populaires'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: popularDestinations.length,
            itemBuilder: (context, index) {
              final destination = popularDestinations[index];
              return GestureDetector(
                onTap: () {
                  // Filtrer les hôtels par ville et pays
                  final filteredHotels = localHotels
                      .where((hotel) =>
                          hotel.address.city == destination['city'] &&
                          hotel.address.country == destination['country'])
                      .toList();

                  // Naviguer vers une page affichant les hôtels filtrés
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HotelsByDestinationScreen(
                        city: destination['city'],
                        country: destination['country'],
                        hotels: filteredHotels,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: AssetImage(destination['image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Overlay sombre pour améliorer la lisibilité
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Texte en bas
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination['city'].toString().tr(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                destination['country'].toString().tr(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help_title'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatHelpPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.blue[700]),
                  const SizedBox(width: 15),
                  Text(
                    'go_to_help_center'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.blue[700]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
