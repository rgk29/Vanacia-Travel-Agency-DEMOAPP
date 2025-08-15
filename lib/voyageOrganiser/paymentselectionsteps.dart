import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentSelectionStep extends StatefulWidget {
  final String totalAmount;
  final Function(Map<String, dynamic>) onCardSelected;
  final Future<void> Function()? onPaymentConfirmed; // Modifié en Future
  final double cardHeight;
  final Color cardColor;
  final Color selectedCardColor;

  const PaymentSelectionStep({
    super.key,
    required this.totalAmount,
    required this.onCardSelected,
    this.onPaymentConfirmed,
    this.cardHeight = 140,
    required this.cardColor,
    required this.selectedCardColor,
  });

  @override
  State<PaymentSelectionStep> createState() => PaymentSelectionStepState();
}

class PaymentSelectionStepState extends State<PaymentSelectionStep> {
  List<Map<String, dynamic>> savedCards = [];
  int? selectedCardIndex;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
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
      } catch (e) {
        _showErrorSnackbar('Erreur_chargement_cartes'.tr());
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

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleContinue() async {
    if (selectedCardIndex == null) {
      _showErrorSnackbar("Veuillez_sélectionner_un_moyen_de_paiement".tr());
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      Map<String, dynamic> selectedCard = savedCards[selectedCardIndex!];

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirmer_le_paiement".tr()),
            content: Text(
              "${'Confirmer_vous_le_paiement_avec_la_carte'.tr()}"
              " ${selectedCard['card_type']} - ****${selectedCard['card_number'].substring(selectedCard['card_number'].length - 4)} ?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("Non".tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text("Oui".tr()),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        widget.onCardSelected(selectedCard);

        if (widget.onPaymentConfirmed != null) {
          await widget.onPaymentConfirmed!();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("✅_Paiement_réussi".tr()),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      _showErrorSnackbar('Erreur_paiement'.tr(args: [e.toString()]));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
              padding: const EdgeInsets.all(16.0),
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
                    card['expiry_date']?.toString() ?? 'Non précisée'.tr();
                final cardType = card['card_type']?.toString() ?? 'Carte'.tr();
                final cardNumber = card['card_number']?.toString() ?? '';

                return GestureDetector(
                  onTap: () {
                    setState(() => selectedCardIndex = index);
                    widget.onCardSelected(card);
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: selectedCardIndex == index
                            ? widget.selectedCardColor
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: widget.cardColor,
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
                  onPressed: _isProcessing ? null : _handleContinue,
                  child: _isProcessing
                      ? const CircularProgressIndicator()
                      : Text(
                          "Payer".tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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
