import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentInfoPage extends StatefulWidget {
  const PaymentInfoPage({super.key});

  @override
  PaymentInfoPageState createState() => PaymentInfoPageState();
}

class PaymentInfoPageState extends State<PaymentInfoPage>
    with TickerProviderStateMixin {
  String? selectedCard;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  late AnimationController _titleController;
  late AnimationController _cardsController;
  late AnimationController _formController;
  int _completedSteps = 0;
  List<Map<String, dynamic>> savedCards = [];

  final Map<String, LinearGradient> cardGradients = {
    'Visa': LinearGradient(
        colors: [Colors.blue.shade300, const Color.fromARGB(255, 40, 83, 148)]),
    'Mastercard': LinearGradient(colors: [
      const Color.fromARGB(255, 255, 184, 77),
      Colors.orange.shade900
    ]),
    'CIB': LinearGradient(colors: [
      Colors.green.shade300,
      const Color.fromARGB(255, 59, 142, 64)
    ]),
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedCards();
  }

  void _initializeAnimations() {
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    Future.delayed(
        const Duration(milliseconds: 300), () => _titleController.forward());
    Future.delayed(
        const Duration(milliseconds: 800), () => _cardsController.forward());
  }

  void _loadSavedCards() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> paymentMethods = data['payment_methods'] ?? [];

        setState(() {
          savedCards = List<Map<String, dynamic>>.from(paymentMethods);
          _completedSteps = savedCards.length.clamp(0, 3); // Limite à 3 cartes
        });
      }
    }
  }

  void _deleteCard(int index) async {
    User? user = FirebaseAuth.instance.currentUser;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer_la_suppression'.tr()),
        content: Text('Voulez_vous_vraiment_supprimer_cette_carte'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer'.tr(), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      if (user != null) {
        // Crée une copie sans le timestamp
        Map<String, dynamic> cardToRemove = Map.from(savedCards[index]);
        cardToRemove.remove('timestamp');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'payment_methods': FieldValue.arrayRemove([cardToRemove])
        });
        _loadSavedCards(); // Ajout de await
      }
    }
  }

  void _handleCardSelection(String cardType) {
    final cardExists = savedCards.any((c) => c['card_type'] == cardType);

    if (cardExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modifiez ou supprimez la carte $cardType existante'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      selectedCard = cardType;
      _formController.forward(from: 0);
    });
  }

  Future<void> savePaymentInfo() async {
    if (_formKey.currentState!.validate() && selectedCard != null) {
      // Vérifier si la carte existe déjà
      final cardExists =
          savedCards.any((card) => card['card_type'] == selectedCard);

      if (cardExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Vous avez déjà Remplie cette carte $selectedCard enregistrée'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Map<String, dynamic> newCard = {
          'card_type': selectedCard,
          'card_number': cardNumberController.text,
          'full_name': fullNameController.text,
          'expiry_date': expiryDateController.text,
          'cvv': cvvController.text,
          // Retirer le timestamp
        };

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'payment_methods': FieldValue.arrayUnion([newCard])
          });
        } on FirebaseException catch (error) {
          if (error.code == 'not-found') {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'payment_methods': [newCard]
            }, SetOptions(merge: true));
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Carte_enregistrée_avec_succès'.tr())),
          );
          Navigator.pop(context, true); // Retour automatique après sauvegarde
          _clearForm();
          _loadSavedCards(); // Remplacer l'incrémentation manuelle
        }
      }
    }
  }

  void _clearForm() {
    cardNumberController.clear();
    fullNameController.clear();
    expiryDateController.clear();
    cvvController.clear();
    setState(() => selectedCard = null);
  }

  void showDatePickerDialog() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      expiryDateController.text = DateFormat('MM/yy').format(pickedDate);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cardsController.dispose();
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedOpacity(
          opacity: _titleController.value,
          duration: const Duration(milliseconds: 500),
          child: Text("Information_de_Paiement".tr()),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleAnimation(),
              _buildCardCarousel(),
              if (selectedCard != null) _buildFormAnimation(),
              _buildSavedCardsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleAnimation() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _titleController,
          curve: Curves.easeOutCubic,
        )),
        child: Text(
          "Choisissez_votre_méthode_de_paiement".tr(
            namedArgs: {'step': _completedSteps.clamp(0, 3).toString()},
          ),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      ),
    );
  }

  Widget _buildCardCarousel() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardsController,
        curve: Curves.easeOutBack,
      )),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          itemCount: cardGradients.length,
          itemBuilder: (context, index) {
            final cardType = cardGradients.keys.elementAt(index);
            final isLocked = savedCards.any((c) => c['card_type'] == cardType);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: AnimatedCardItem(
                animation: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _cardsController,
                    curve: Interval(
                      (0.2 * index).clamp(0.0, 1.0),
                      1.0,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                cardType: cardType,
                imagePath: _getImagePath(cardType),
                gradient: cardGradients[cardType]!,
                isSelected: selectedCard == cardType,
                isLocked: isLocked,
                onTap: isLocked ? null : () => _handleCardSelection(cardType),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormAnimation() {
    return FadeTransition(
      opacity: _formController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_formController),
        child: _buildPaymentForm(),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: cardGradients[selectedCard],
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withValues(),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: cardNumberController,
              label: "Numéro_de_carte".tr(),
              icon: Icons.credit_card,
              maxLength: 16,
              validator: (value) =>
                  value!.length == 16 ? null : "16_chiffres_requis".tr(),
            ),
            _buildTextField(
              controller: fullNameController,
              label: "Nom_complet".tr(),
              icon: Icons.person,
              validator: (value) =>
                  value!.isNotEmpty ? null : "Champ_obligatoire".tr(),
            ),
            _buildTextField(
              controller: expiryDateController,
              label: "Date_dexpiration".tr(),
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: showDatePickerDialog,
            ),
            _buildTextField(
              controller: cvvController,
              label: "CVV".tr(),
              icon: Icons.lock,
              maxLength: 3,
              obscureText: true,
              validator: (value) =>
                  value!.length == 3 ? null : "3_chiffres_requis".tr(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  savePaymentInfo();
                }
              },
              child: Text("Enregistrer_la_carte".tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLength,
    bool obscureText = false,
    bool readOnly = false,
    FormFieldValidator<String>? validator,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: const Color.fromARGB(
                  207, 255, 255, 255)), // Appliquer la couleur au label
          prefixIcon:
              Icon(icon, color: Colors.white), // Optionnel : couleur de l'icône
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: textColor ??
                    const Color.fromARGB(255, 244, 245, 246)), // Bordure focus
          ),
        ),
        maxLength: maxLength,
        obscureText: obscureText,
        readOnly: readOnly,
        validator: validator,
        onTap: onTap,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildSavedCardsSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cartes_enregistrées".tr(),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ...savedCards.asMap().entries.map((entry) => _SavedCardItem(
                card: entry.value,
                onDelete: () => _deleteCard(entry.key),
              )),
        ],
      ),
    );
  }

  String _getImagePath(String cardType) {
    switch (cardType) {
      case 'Visa':
        return 'assets/visa.jpg';
      case 'Mastercard':
        return 'assets/mastercardd.JPG';
      case 'CIB':
        return 'assets/cib.jpg';
      default:
        return 'assets/visa.jpg';
    }
  }
}

class AnimatedCardItem extends StatelessWidget {
  final Animation<double> animation;
  final String cardType;
  final String imagePath;
  final Gradient gradient;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isLocked;

  const AnimatedCardItem({
    super.key,
    required this.animation,
    required this.cardType,
    required this.imagePath,
    required this.gradient,
    required this.isSelected,
    required this.onTap,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 50),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: isLocked ? null : onTap,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: isLocked
                ? LinearGradient(colors: [Colors.grey[300]!, Colors.grey[500]!])
                : gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    isSelected ? Colors.black.withValues() : Colors.transparent,
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Stack(
            children: [
              if (isLocked)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    imagePath,
                    width: 500,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    cardType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedCardItem extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback onDelete;

  const _SavedCardItem({required this.card, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Badge(
        backgroundColor: Colors.red,
        label: Text('Active'.tr(), style: TextStyle(fontSize: 10)),
        isLabelVisible: true,
        child: Image.asset(
          _getImagePath(
              card['card_type'], false), // Toujours actif dans la liste
          width: 30,
          height: 20,
          fit: BoxFit.contain,
        ),
      ),
      title: Text('•••• ${card['card_number'].toString().substring(12)}'),
      subtitle: Text(
        'Expire_le'.tr(namedArgs: {'date': card['expiry_date']}),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
      ),
    );
  }

  String _getImagePath(String cardType, bool isLocked) {
    final suffix = isLocked ? '_locked' : '';
    switch (cardType) {
      case 'Visa':
        return 'assets/visa$suffix.jpg';
      case 'Mastercard':
        return 'assets/mastercardd$suffix.JPG';
      case 'CIB':
        return 'assets/cib$suffix.jpg';
      default:
        return 'assets/visa$suffix.jpg';
    }
  }
}
