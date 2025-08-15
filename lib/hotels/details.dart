import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/hotels/data.dart';
import 'package:agencedevoyage/hotels/formulaire.dart'
    show HotelPersonalInfoPage;
import 'package:agencedevoyage/hotels/hotelreviews.dart';
import 'package:agencedevoyage/hotels/local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HotelDetailsScreen extends StatefulWidget {
  final Hotells hotel;

  const HotelDetailsScreen({
    super.key,
    required this.hotel,
  });

  @override
  State<HotelDetailsScreen> createState() => HotelDetailsScreenState();
}

class HotelDetailsScreenState extends State<HotelDetailsScreen> {
  RoomType? selectedRoomType;
  int _currentImageIndex = 0;
  final MapController _mapController = MapController();
  final HotelReviewsService _reviewsService = HotelReviewsService();
  final TextEditingController _reviewController = TextEditingController();
  double _reviewRating = 5.0;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  IconData _getNearbyIcon(String category) {
    switch (category) {
      case 'Monuments':
        return Icons.landscape;
      case 'Restaurants':
        return Icons.restaurant;
      case 'Nature':
        return Icons.nature;
      case 'Commodités':
        return Icons.shopping_cart;
      default:
        return Icons.place;
    }
  }

  final List<RoomType> availableRooms = [
    RoomType.double,
    RoomType.single,
    RoomType.triple
  ];

  Future<String> _saveReservation(HotelReservation reservation) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('hotel_reservations')
          .add(reservation.toMap());
      return docRef.id;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de réservation: ${e.toString()}')),
      );
      rethrow;
    }
  }

  void _handleReservation() async {
    if (selectedRoomType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Veuillez_selectionner_un_type_de_chambre'.tr())),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez_vous_connecter'.tr())),
      );
      return;
    }

    final tempReservation = HotelReservation(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      hotelId: widget.hotel.id,
      checkInDate: widget.hotel.arrivalDate,
      checkOutDate: widget.hotel.departureDate,
      teens: 0,
      roomType: selectedRoomType.toString().split('.').last,
      paymentMethod: 'Non défini',
      status: 'pending',
      totalPrice: widget.hotel.pricePerNight * widget.hotel.durationDays,
      createdAt: DateTime.now(),
      userEmail: user.email!,
      hotelDetails: {
        'name': widget.hotel.name,
        'stars': widget.hotel.stars,
        'address': widget.hotel.address.toMap(),
        'province': widget.hotel.address.province,
        'country': widget.hotel.address.country,
        'roomTypes': widget.hotel.availableRooms
            .map((rt) => rt.toString().split('.').last)
            .toList(),
        'duration': widget.hotel.durationDays,
        'pricePerNight': widget.hotel.pricePerNight,
      },
    );

    try {
      final reservationId = await _saveReservation(tempReservation);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelPersonalInfoPage(
            hotel: widget.hotel,
            reservation: tempReservation.copyWith(id: reservationId),
            roomType: selectedRoomType.toString().split('.').last,
            hotelReservation: {
              'totalPrice': tempReservation.totalPrice,
              'originalPrice': tempReservation.totalPrice,
              'durationDays': widget.hotel.durationDays,
              'timestamp': FieldValue.serverTimestamp(),
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur initiale: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hotel.name.tr()),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            _buildHotelInfoSection(),
            _buildPriceAndPaymentSection(),
            _buildFacilitiesSection(),
            _buildRoomTypesSection(),
            _buildNearbyPointsSection(),
            _buildHotelRulesSection(),
            _buildReservationButton(),
            _buildLocationMap(),
            _buildReviewsSection(), // Nouvelle section pour les reviews
          ],
        ),
      ),
    );
  }

//////////////////////////REVIEWS///////
  ///
  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('reviews'.tr()),
        _buildAddReviewSection(),
        _buildReviewsList(),
      ],
    );
  }

  Widget _buildAddReviewSection() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'login_to_review'.tr(),
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('add_review'.tr(),
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(
            children: [
              Text('rating'.tr()),
              SizedBox(width: 8),
              Slider(
                value: _reviewRating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _reviewRating.toStringAsFixed(1),
                onChanged: (value) => setState(() => _reviewRating = value),
              ),
              Icon(Icons.star, color: Colors.amber),
              Text(_reviewRating.toStringAsFixed(1)),
            ],
          ),
          TextField(
            controller: _reviewController,
            decoration: InputDecoration(
              hintText: 'write_your_review'.tr(),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              if (_reviewController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('review_empty_warning'.tr())),
                );
                return;
              }

              try {
                await _reviewsService.addReview(
                  hotelId: widget.hotel.id,
                  text: _reviewController.text,
                  rating: _reviewRating,
                  userName: user.displayName ?? user.email!.split('@')[0],
                );
                _reviewController.clear();
                _reviewRating = 5.0;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('review_added'.tr())),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('review_error'.tr())),
                );
              }
            },
            child: Text('submit_review'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<List<Review>>(
      stream: _reviewsService.getReviewsStream(widget.hotel.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Stream error: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erreur de chargement: ${snapshot.error.toString()}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('no_reviews_yet'.tr()),
          );
        }

        return SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              return _buildReviewCard(reviews[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    final user = FirebaseAuth.instance.currentUser;
    final isCurrentUser = user?.uid == review.userId;

    return Container(
      width: 300,
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.userName,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text(review.rating.toStringAsFixed(1)),
                  Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(review.text),
          SizedBox(height: 8),
          Row(
            children: [
              _buildLikeButton(review, user),
              _buildDislikeButton(review, user),
              Spacer(),
              if (isCurrentUser) ...[
                _buildEditButton(review),
                _buildDeleteButton(review),
              ],
            ],
          ),
          SizedBox(height: 4),
          Text(
            DateFormat.yMMMd().format(review.date),
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton(Review review, User? user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.thumb_up,
              color: review.likedBy.contains(user?.uid)
                  ? Colors.blue
                  : Colors.grey),
          onPressed: user == null
              ? null
              : () {
                  _reviewsService.toggleLike(
                    hotelId: widget.hotel.id,
                    reviewId: review.id,
                    userId: user.uid,
                    isLike: true,
                  );
                },
        ),
        Text(review.likedBy.length.toString()),
      ],
    );
  }

  Widget _buildDislikeButton(Review review, User? user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.thumb_down,
              color: review.dislikedBy.contains(user?.uid)
                  ? Colors.red
                  : Colors.grey),
          onPressed: user == null
              ? null
              : () {
                  _reviewsService.toggleLike(
                    hotelId: widget.hotel.id,
                    reviewId: review.id,
                    userId: user.uid,
                    isLike: false,
                  );
                },
        ),
        Text(review.dislikedBy.length.toString()),
      ],
    );
  }

  Widget _buildEditButton(Review review) {
    return IconButton(
      icon: Icon(Icons.edit, size: 18),
      onPressed: () => _showEditReviewDialog(review),
    );
  }

  Widget _buildDeleteButton(Review review) {
    return IconButton(
      icon: Icon(Icons.delete, size: 18, color: Colors.red),
      onPressed: () => _confirmDeleteReview(review.id),
    );
  }

  void _showEditReviewDialog(Review review) {
    final user = FirebaseAuth.instance.currentUser; // Ajoutez cette ligne
    if (user == null) return; // Gestion si l'utilisateur n'est pas connecté

    _reviewController.text = review.text;
    _reviewRating = review.rating;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit_review'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('rating'.tr(), style: TextStyle(fontSize: 14)),
                SizedBox(width: 5),
                Expanded(
                  child: Slider(
                    value: _reviewRating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _reviewRating.toStringAsFixed(1),
                    onChanged: (value) => setState(() => _reviewRating = value),
                  ),
                ),
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 4),
                Text(
                  _reviewRating.toStringAsFixed(1),
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: 'write_your_review'.tr(),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_reviewController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('review_empty_warning'.tr())),
                );
                return;
              }

              if (_reviewController.text.length > 500) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('review_too_long'.tr())),
                );
                return;
              }

              try {
                await _reviewsService.updateReview(
                  hotelId: widget.hotel.id,
                  reviewId: review.id,
                  text: _reviewController.text,
                  rating: _reviewRating,
                );
                _reviewController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('review_updated'.tr())),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('review_update_error'.tr())),
                );
              }
            },
            child: Text('update'.tr()),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteReview(String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_review'.tr()),
        content: Text('confirm_delete_review'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // Afficher un indicateur de chargement
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      Center(child: CircularProgressIndicator()),
                );

                await _reviewsService.deleteReview(
                  hotelId: widget.hotel.id,
                  reviewId: reviewId,
                );

                // Fermer les dialogues
                Navigator.pop(context); // Fermer l'indicateur
                Navigator.pop(context); // Fermer la boîte de confirmation

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('review_deleted'.tr()),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Fermer l'indicateur si erreur
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('${'review_delete_error'.tr()}: ${e.toString()}'),
                    duration: Duration(seconds: 4),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  /////////////////////REVIEWS//////////
  Widget _buildImageGallery() {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.hotel.imageUrls.length,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) => Image.asset(
              widget.hotel.imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                  '${_currentImageIndex + 1}/${widget.hotel.imageUrls.length}',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelInfoSection() {
    final locale = context.locale; // pour déclencher le rebuild

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hotel.name.tr(), // ✅ Traduction dynamique ici
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              widget.hotel.stars,
              (index) => const Icon(Icons.star, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.hotel.description.tr(), // ✅ Traduction dynamique ici
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndPaymentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final currencyNotifier = ref.watch(currencyProvider.notifier);

              return widget.hotel.hasPromotion
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${currencyNotifier.formatPrice(widget.hotel.originalPrice!)}/ ${'price_per_night'.tr()}',
                          style: TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${currencyNotifier.formatPrice(widget.hotel.pricePerNight)}/ ${'price_per_night'.tr()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '${currencyNotifier.formatPrice(widget.hotel.pricePerNight)} ${'price_per_night'.tr()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    );
            },
          ),
          Row(
            children: [
              Image.asset('assets/visa.jpg', width: 40, height: 25),
              const SizedBox(width: 8),
              Image.asset('assets/mastercardd.JPG', width: 40, height: 25),
              const SizedBox(width: 8),
              Image.asset('assets/cib2.jpg', width: 50, height: 25),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Équipements'.tr()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            children: widget.hotel.facilities.map((facility) {
              String facilityName = _getFacilityTranslation(facility);
              return Chip(
                avatar: Icon(facility.icon),
                label: Text(facilityName),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getFacilityTranslation(Facilities facility) {
    switch (facility) {
      case Facilities.wifi:
        return 'facilities.wifi'.tr(); // traduction pour wifi
      case Facilities.tv:
        return 'facilities.tv'.tr(); // traduction pour tv
      case Facilities.parking:
        return 'facilities.parking'.tr(); // traduction pour parking
      case Facilities.pool:
        return 'facilities.pool'.tr(); // traduction pour piscine
      case Facilities.restaurant:
        return 'facilities.restaurant'.tr(); // traduction pour restaurant
      case Facilities.spa:
        return 'facilities.spa'.tr(); // traduction pour spa
      case Facilities.airportShuttle:
        return 'facilities.airportShuttle'
            .tr(); // traduction pour navette aéroport
      case Facilities.nonSmokingRooms:
        return 'facilities.nonSmokingRooms'
            .tr(); // traduction pour chambres non fumeur
      case Facilities.frontDesk24h:
        return 'facilities.frontDesk24h'.tr(); // traduction pour réception 24h
      case Facilities.heating:
        return 'facilities.heating'.tr(); // traduction pour chauffage
      case Facilities.housekeeping:
        return 'facilities.housekeeping'.tr(); // traduction pour ménage
      case Facilities.luggageStorage:
        return 'facilities.luggageStorage'
            .tr(); // traduction pour consigne à bagages
      case Facilities.airConditioning:
        return 'facilities.airConditioning'
            .tr(); // traduction pour climatisation
      case Facilities.roomService:
        return 'facilities.roomService'.tr(); // traduction pour service d'étage
      case Facilities.familyRooms:
        return 'facilities.familyRooms'
            .tr(); // traduction pour chambres familiales
      case Facilities.breakfast:
        return 'facilities.breakfast'.tr(); // traduction pour petit-déjeuner
      case Facilities.kitchen:
        return 'facilities.kitchen'.tr(); // traduction pour cuisine
      case Facilities.garden:
        return 'facilities.garden'.tr(); // traduction pour jardin
      case Facilities.petsAllowed:
        return 'facilities.petsAllowed'
            .tr(); // traduction pour animaux acceptés
      default:
        return '';
    }
  }

  Widget _buildRoomTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('room_types_available'.tr()),
        ...widget.hotel.availableRooms.map((roomType) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: selectedRoomType == roomType ? Colors.blue[50] : null,
              child: ListTile(
                title: Text(
                  _getRoomTypeTranslation(roomType),
                ),
                trailing: ElevatedButton(
                  onPressed: () => setState(() => selectedRoomType = roomType),
                  child: Text('select'.tr()),
                ),
              ),
            )),
      ],
    );
  }

  String _getRoomTypeTranslation(RoomType roomType) {
    switch (roomType) {
      case RoomType.single:
        return 'roomTypes.single'.tr();
      case RoomType.double:
        return 'roomTypes.double'.tr();
      case RoomType.triple:
        return 'roomTypes.triple'.tr();
      case RoomType.family:
        return 'roomTypes.family'.tr();
      case RoomType.suite:
        return 'roomTypes.suite'.tr();
      default:
        return '';
    }
  }

  Widget _buildNearbyPointsSection() {
    final locale = context.locale; // tu peux l'utiliser si besoin

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('nearby'.tr()),
        ...widget.hotel.nearbyPoints.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(_getNearbyIcon(entry.key)),
                        const SizedBox(width: 8),
                        // Traduction de la catégorie à la volée
                        Text(entry.key.tr(),
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  ...entry.value.map(
                    (pointKey) => Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 4),
                      // Traduction de chaque point d'intérêt
                      child: Text(pointKey.tr()),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildHotelRulesSection() {
    final locale = context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("hotel_rules".tr()),
        ...widget.hotel.hotelRules.entries.map((rule) => ListTile(
              leading: Icon(Icons.rule),
              title: Text(rule.key.tr()), // ✅ Clé traduite ici
              subtitle: Text(
                  rule.value.tr()), // ✅ Valeur traduite aussi, si c'est une clé
            )),
      ],
    );
  }

  Widget _buildLocationMap() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.hotel.address.location.toLatLng(),
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 40,
                  height: 40,
                  point: widget.hotel.address.location.toLatLng(),
                  child: const Icon(Icons.location_pin,
                      color: Colors.red, size: 40),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: selectedRoomType == null ? null : _handleReservation,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text('Continuer_la_reservation'.tr()),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
      ),
    );
  }
}
