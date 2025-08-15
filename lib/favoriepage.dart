import 'package:agencedevoyage/favorie.dart';
import 'package:agencedevoyage/hotels/data.dart';
import 'package:agencedevoyage/hotels/resultat.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final favoriteHotels =
        localHotels.where((h) => favoriteIds.contains(h.id)).toList();
    return WillPopScope(
      onWillPop: () async {
        // Navigation vers HomePage et empêcher l'action par défaut
        Navigator.of(context).pushReplacementNamed('/HomePage');
        return false; // Empêche le retour naturel
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mes_Favoris'.tr()),
          backgroundColor: const Color.fromARGB(255, 237, 247, 255),
        ),
        body: favoriteHotels.isEmpty
            ? Center(child: Text('Aucun_hôtel_favori'.tr()))
            : ListView.builder(
                itemCount: favoriteHotels.length,
                itemBuilder: (context, index) => HotelCard(
                  hotel: favoriteHotels[index],
                  nights: 1, // Adaptez selon vos besoins
                ),
              ),
      ),
    );
  }
}
