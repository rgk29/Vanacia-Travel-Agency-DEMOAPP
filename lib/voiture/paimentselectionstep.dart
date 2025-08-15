import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentSelectionStep extends StatefulWidget {
  final String totalAmount; // Ajouté
  final Function(Map<String, dynamic>) onCardSelected;
  final VoidCallback? onPaymentConfirmed; // Nouveau callback
  final double cardHeight;

  const PaymentSelectionStep({
    super.key,
    required this.totalAmount, // Ajouté comme paramètre requis
    required this.onCardSelected,
    this.onPaymentConfirmed,
    this.cardHeight = 140,
    required Color cardColor,
    required Color selectedCardColor, // Ajouté
  });
  @override
  State<PaymentSelectionStep> createState() => PaymentSelectionStepState();
}

class PaymentSelectionStepState extends State<PaymentSelectionStep> {
  List<Map<String, dynamic>> savedCards = [];
  int? selectedCardIndex;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  void _loadSavedCards() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        List<dynamic> paymentMethods =
            (doc.data() as Map<String, dynamic>)['payment_methods'] ?? [];
        setState(() {
          savedCards = List<Map<String, dynamic>>.from(paymentMethods);
        });
      }
    }
  }

  Widget _getCardImage(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Image.asset('assets/visa.jpg', height: 40);
      case 'mastercard':
        return Image.asset('assets/mastercardd.JPG', height: 40);
      case 'cib':
        return Image.asset('assets/cib.jpg', height: 40);
      default:
        return const Icon(Icons.credit_card, size: 40);
    }
  }

  void _handleContinue() {
    if (selectedCardIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Veuillez_sélectionner_un_moyen_de_paiement".tr())),
      );
      return;
    }

    Map<String, dynamic> selectedCard = savedCards[selectedCardIndex!];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmer_le_paiement".tr()),
          content: Text(
            "${'Confirmer_vous_le_paiement_avec_la_carte'.tr()}"
                    " ${selectedCard['card_type']} - ****${selectedCard['card_number'].substring(selectedCard['card_number'].length - 4)} ?"
                .tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Non
              child: Text("Non".tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("✅_Paiement_réussi".tr()),
                    backgroundColor: Colors.green,
                  ),
                );
                // Déclenche les deux callbacks
                widget.onCardSelected(selectedCard);
                widget.onPaymentConfirmed
                    ?.call(); // Navigation vers la confirmation
              },

              // Tu peux aussi naviguer à une page de confirmation ou enregistrer le paiement ici

              child: Text("Oui".tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Ajout de l'affichage du montant total
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "${'Montant_total'.tr()}: ${widget.totalAmount}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          if (savedCards.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Aucune_carte_enregistrée".tr()),
            )
          else
            ListView.builder(
              itemCount: savedCards.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final card = savedCards[index];
                final expirationDate =
                    card['expiry_date'] ?? 'Non précisée'.tr();
                final cardType = card['card_type'] ?? 'Carte'.tr();
                final cardNumber = card['card_number'] ?? '';

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCardIndex = index;
                    });
                    widget.onCardSelected(card);
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: selectedCardIndex == index
                            ? Colors.blueAccent
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: _getCardImage(cardType),
                      title: Text(
                          "$cardType - ****${cardNumber.substring(cardNumber.length - 4)}"),
                      subtitle: Text("${'EXP'.tr()} $expirationDate"),
                      trailing: selectedCardIndex == index
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                  ),
                );
              },
            ),
          if (savedCards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  child: Text(
                    "Payer".tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(199, 0, 0, 0),
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
