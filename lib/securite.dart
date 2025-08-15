import 'dart:async';
import 'package:agencedevoyage/currency_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key, this.refreshKey});
  final Key? refreshKey;

  @override
  ConsumerState<SecurityPage> createState() => SecurityPageState();
}

class SecurityPageState extends ConsumerState<SecurityPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _travelColors = _TravelColors();

  late TextEditingController _passportController;
  String? _currentPassport;
  String? _selectedCountry;
  String? _currentPhoneNumber;
  StreamSubscription<User?>? _authSubscription;
  String? _pendingEmail;
  DateTime? _dateOfBirth;
  TextEditingController _dateController = TextEditingController();

  final Map<String, String> _countries = const {
    'Algeria': 'DZD',
    'France': 'EUR',
    'Spain': 'EUR',
    'Italy': 'EUR',
    'Germany': 'EUR',
    'Arab Emirates': 'USD',
    'United States': 'USD'
  };

  @override
  void initState() {
    super.initState();
    _passportController = TextEditingController();
    _dateController = TextEditingController();
    _loadUserData();
    _startAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _passportController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // Toutes les méthodes existantes restent ici (loadUserData, checkEmailVerification, etc.)
  // ... [Conserver toutes les méthodes fonctionnelles existantes] ...
// Modifier la méthode _checkEmailVerification
  Future<void> _checkEmailVerification(User user) async {
    await user.reload();
    final updatedUser = _auth.currentUser;

    if (updatedUser != null && updatedUser.emailVerified) {
      try {
        // Demande le mot de passe pour la réauthentification
        final passwordController = TextEditingController();
        final passwordResult = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Re_authentification_requise'.tr()),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration:
                  InputDecoration(labelText: 'Entrez_votre_mot_de_passe'.tr()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: Text('Annuler'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'verify'),
                child: Text('Vérifier'.tr()),
              ),
            ],
          ),
        );

        if (passwordResult != 'verify' || passwordController.text.isEmpty) {
          return;
        }

        // Création de nouvelles credentials avec le nouvel email
        final credential = EmailAuthProvider.credential(
          email: updatedUser.email!,
          password: passwordController.text,
        );

        // Réauthentification pour récupérer un token valide
        await updatedUser.reauthenticateWithCredential(credential);

        // Mise à jour de Firestore avec le nouvel email
        await _updateFirestoreEmail(updatedUser);

        // Supprimer l'email en attente
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pendingEmail');
        await _loadUserData();

        if (mounted) {
          setState(() => _pendingEmail = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email_mis_à_jour_avec_succès'.tr())),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur de réauthentification : ${e.toString()}')),
        );
      }
    }
  }

  void _startAuthListener() {
    _authSubscription =
        FirebaseAuth.instance.userChanges().listen((User? user) async {
      if (user != null && _pendingEmail != null) {
        await _checkEmailVerification(user);
        _refreshUI(user);
      }
    });
  }

  Future<void> _updateFirestoreEmail(User user) async {
    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(user.uid);
      batch.update(userRef, {
        'email': user.email!,
        'email_verified': true,
        'updated_at': FieldValue.serverTimestamp()
      });

      // Force refresh de toutes les données utilisateur
      // await _loadUserData();
      await batch.commit();
    } catch (e) {
      if (kDebugMode) print("Erreur Firestore: $e");
    }
  }

  void _refreshUI(User user) {
    if (mounted) {
      setState(() {
        _pendingEmail = null;
      });
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        setState(() {
          _selectedCountry = _countries.keys.contains(data['country'])
              ? data['country']
              : 'Algeria';
          _currentPhoneNumber = data['phone'] ?? '';
          _currentPassport = data['passport'] ?? '';
          _passportController.text = _currentPassport ?? '';
          _dateOfBirth = data['date_of_birth']?.toDate();
          _dateController.text = _dateOfBirth != null
              ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
              : '';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur de chargement: $e");
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _checkPendingEmail() async {
    if (_pendingEmail != null) {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified && user.email == _pendingEmail) {
          await _updateFirestoreEmail(user);
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pendingEmail');
          if (mounted) {
            setState(() => _pendingEmail = null);
          }
        }
      }
    }
  }

  // Ajoutez cette méthode dans la classe SecurityPageState
  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // Étape 1: Vérification de l'ancien mot de passe
    final authResult = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('verification_ancien_mot_de_passe'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'ancien_mot_de_passe'.tr(),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('mot_de_passe_oublie'.tr()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('annuler'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('continuer'.tr()),
          ),
        ],
      ),
    );

    if (authResult == false) {
      // Si l'utilisateur a cliqué sur "Mot de passe oublié"
      await _sendPasswordResetEmail();
      return;
    }

    if (authResult != true) return;

    try {
      // Vérification des identifiants
      final user = _auth.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ancien_mot_de_passe_incorrect'.tr())),
      );
      return;
    }

    // Étape 2: Saisie du nouveau mot de passe
    final passwordResult = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('nouveau_mot_de_passe'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'nouveau_mot_de_passe'.tr(),
              ),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'confirmer_nouveau_mot_de_passe'.tr(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('annuler'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('confirmer'.tr()),
          ),
        ],
      ),
    );

    if (passwordResult != true) return;

    // Validation des mots de passe
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mots_de_passe_non_identiques'.tr())),
      );
      return;
    }

    try {
      // Mise à jour du mot de passe
      await _auth.currentUser!.updatePassword(newPasswordController.text);

      // Déconnexion et redirection
      await _auth.signOut();

      // Affichage d'un message de confirmation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('mot_de_passe_modifie'.tr()),
          content: Text('veuillez_vous_reconnecter'.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/AuthPage', (route) => false);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('erreur_mise_a_jour_mot_de_passe'.tr())),
      );
    }
  }

// Ajoutez ce widget dans la méthode _buildUserCard, après le _buildDateOfBirthField

  Future<void> _changeEmail() async {
    final passwordController = TextEditingController();
    final newEmailController = TextEditingController();

    final passwordResult = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('verification_mot_de_passe'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'mot_de_passe'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'reset'),
              child: Text('mot_de_passe_oublie'.tr()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text('annuler'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'verify'),
            child: Text('verifier'.tr()),
          ),
        ],
      ),
    );

    if (passwordResult == 'reset') {
      await _sendPasswordResetEmail();
      return;
    }

    if (passwordResult != 'verify' || !mounted) return;

    try {
      final user = _auth.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mot_de_passe_incorrect'.tr())),
      );
      return;
    }

    final emailResult = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('nouvel_email'.tr()),
        content: TextField(
          controller: newEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: 'entrez_nouvel_email'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('annuler'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('continuer'.tr()),
          ),
        ],
      ),
    );

    if (!mounted || emailResult != true) return;

    try {
      final newEmail = newEmailController.text;
      await _auth.currentUser!.verifyBeforeUpdateEmail(newEmail);
      setState(() => _pendingEmail = newEmail);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingEmail', newEmail);

      // 🔥 Afficher un message et rediriger vers l'authentification
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Modification_email_avec_succes'.tr()),
          content:
              Text('Veuillez_vous_reconnecter_avec_votre_nouvel_email'.tr()),
          actions: [
            TextButton(
              onPressed: () async {
                await _auth.signOut(); // 🔥 Déconnexion de l'utilisateur
                Navigator.pushReplacementNamed(context,
                    '/AuthPage'); // 🔥 Redirection vers la page de connexion
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'email_update_error'.tr()} ${e.toString()}')),
      );
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      final email = _auth.currentUser!.email!;
      await _auth.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'reset_email_sent'.tr()} $email'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'reset_email_error'.tr()} ${e.toString()}')),
      );
    }
  }

  // Modifiez la sauvegarde pour rafraîchir les données
  Future<void> _saveSettings() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      final currentCurrency = _countries[_selectedCountry] ?? 'DZD';

      await _firestore.collection('users').doc(user.uid).update({
        'phone': _currentPhoneNumber,
        'country': _selectedCountry,
        'currency': currentCurrency,
        'passport': _currentPassport,
        'updated_at':
            FieldValue.serverTimestamp(), // 🔥 Forcer une nouvelle version
        'date_of_birth': _dateOfBirth,
      });
      // Étape 2: Rafraîchir IMMÉDIATEMENT le provider
      ref.read(currencyProvider.notifier).setCurrency(currentCurrency);
      // Rafraîchir les données locales
      await _loadUserData();
      if (mounted) {
        setState(() {
          // Forcer un rebuild même si les données semblent identiques
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings_saved'.tr())),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SecurityPage(
              refreshKey: UniqueKey(), // 🌀 Nouvelle clé à chaque sauvegarde
            ),
            transitionDuration: Duration.zero,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print("Erreur de sauvegarde: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final displayEmail = _pendingEmail ?? user?.email ?? '';

    return Scaffold(
      key: widget.refreshKey,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildUserCard(displayEmail),
            const SizedBox(height: 25),
            _buildRegionalSection(),
            const SizedBox(height: 25),
            _buildDocumentsSection(),
            const SizedBox(height: 35),
            _buildSaveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('security_privacy'.tr(),
          style: TextStyle(
            color: _travelColors.primaryDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          )),
      centerTitle: true,
      backgroundColor: _travelColors.background,
      elevation: 2,
      iconTheme: IconThemeData(color: _travelColors.primaryDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(15),
        ),
      ),
    );
  }

  Widget _buildUserCard(String email) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _travelColors.primaryLight.withOpacity(0.1),
              _travelColors.primaryLight.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildUserHeader(),
              const SizedBox(height: 20),
              _buildInfoRow(
                icon: Icons.email_outlined,
                label: 'Email'.tr(),
                value: email,
                onEdit: _changeEmail,
              ),
              _buildInfoRow(
                icon: Icons.lock_outlined,
                label: 'Mot_de_passe'.tr(),
                value: '••••••••',
                onEdit: _changePassword,
              ),
              const SizedBox(height: 15),
              _buildDateOfBirthField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: _travelColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _travelColors.primaryLight.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.cake_outlined, color: _travelColors.secondary, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date_de_naissance'.tr(),
                    style: TextStyle(
                      color: _travelColors.primaryDark.withOpacity(0.7),
                      fontSize: 14,
                    )),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'JJ/MM/AAAA'.tr(),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    color: _travelColors.primaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onTap: _selectDate,
                ),
              ],
            ),
          ),
          if (_dateOfBirth != null)
            IconButton(
              icon: Icon(Icons.clear_outlined,
                  color: _travelColors.primary, size: 22),
              onPressed: () => setState(() {
                _dateOfBirth = null;
                _dateController.clear();
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        Icon(Icons.person_pin_circle_outlined,
            color: _travelColors.primary, size: 30),
        const SizedBox(width: 10),
        Text('Informations_personnelles'.tr(),
            style: TextStyle(
              color: _travelColors.primaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Function() onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: _travelColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _travelColors.primaryLight.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _travelColors.secondary, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: _travelColors.primaryDark.withOpacity(0.7),
                      fontSize: 14,
                    )),
                const SizedBox(height: 5),
                Text(value,
                    style: TextStyle(
                      color: _travelColors.primaryDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: _travelColors.primary, size: 22),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 12),
          child: Text('Préférences_régionales'.tr(),
              style: TextStyle(
                color: _travelColors.primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
        ),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildCountryDropdown(),
                const SizedBox(height: 20),
                _buildCurrencyField(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    return Consumer(builder: (context, ref, _) {
      return DropdownButtonFormField<String>(
        value: _selectedCountry,
        decoration: InputDecoration(
          labelText: 'Pays_de_residence'.tr(),
          prefixIcon: Icon(Icons.flag_outlined, color: _travelColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _travelColors.primaryLight),
          ),
        ),
        dropdownColor: _travelColors.background,
        style: TextStyle(color: _travelColors.primaryDark),
        onChanged: (String? newValue) {
          if (newValue != null) {
            final newCurrency = _countries[newValue]!;
            ref.read(currencyProvider.notifier).setCurrency(newCurrency);
            setState(() => _selectedCountry = newValue);
          }
        },
        items: _countries.keys.map((String country) {
          return DropdownMenuItem<String>(
            value: country,
            child: Text(country.tr(), style: TextStyle(fontSize: 15)),
          );
        }).toList(),
      );
    });
  }

  Widget _buildCurrencyField() {
    return Consumer(builder: (context, ref, _) {
      final currency = ref.watch(currencyProvider).currency;
      return TextFormField(
        decoration: InputDecoration(
          labelText: 'Devise'.tr(),
          prefixIcon: Icon(Icons.currency_exchange_outlined,
              color: _travelColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: _travelColors.background,
        ),
        enabled: false,
        style: TextStyle(
            color: _travelColors.primaryDark, fontWeight: FontWeight.w500),
        initialValue: currency,
      );
    });
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 12),
          child: Text('Documents_de_voyage'.tr(),
              style: TextStyle(
                color: _travelColors.primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
        ),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextFormField(
                  controller: _passportController,
                  decoration: InputDecoration(
                    labelText: 'Numéro_de_passeport'.tr(),
                    prefixIcon: Icon(Icons.credit_card_outlined,
                        color: _travelColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear_outlined,
                          color: _travelColors.secondary),
                      onPressed: () => setState(() {
                        _passportController.clear();
                        _currentPassport = null;
                      }),
                    ),
                    counterText: '', // Masque le compteur par défaut
                    counter: _buildCounter(), // Compteur personnalisé
                  ),
                  maxLength: 20, // Longueur maximale de 20 caractères
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  onChanged: (value) => setState(() {
                    _currentPassport = value.isEmpty ? null : value;
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter() {
    return Consumer(
      builder: (context, ref, _) {
        final length = _passportController.text.length;
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$length/20',
            style: TextStyle(
              color: length == 20
                  ? _travelColors.error
                  : _travelColors.primaryDark.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _travelColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        onPressed: _saveSettings,
        child: Text(
          'Enregistrer_les_modifications'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TravelColors {
  final Color primary = const Color(0xFF2A5C82);
  final Color primaryDark = const Color(0xFF1A3A4F);
  final Color primaryLight = const Color(0xFF7EA8C4);
  final Color secondary = const Color(0xFFFFA34D);
  final Color background = Colors.white;
  final Color error = const Color(0xFFE57373);
}
