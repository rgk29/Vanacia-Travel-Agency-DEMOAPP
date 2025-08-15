import 'dart:ui';
import 'package:agencedevoyage/admin/admin_service.dart';
import 'package:agencedevoyage/api/firebase_api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';

final authServiceProvider = Provider((ref) => AuthService());
final adminProvider = StateProvider<bool>((ref) => false);

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final AdminService _adminService = AdminService();

  Future<bool> isAdmin(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['isAdmin'] ?? false;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!result.user!.emailVerified) {
        await _auth.signOut();
        throw Exception('Veuillez vérifier votre email'.tr());
      }

      // Charge immédiatement le statut admin
      final doc =
          await _firestore.collection('users').doc(result.user?.uid).get();
      // final isAdmin = doc.data()?['isAdmin'] ?? false;

      // if (isAdmin) {
      //   debugPrint('Utilisateur reconnu comme ADMIN');
      // } else {
      //   debugPrint('Utilisateur normal');
      // }
      final isAdmin = await _adminService.isAdmin(result.user);
      debugPrint('User ${result.user?.email} is admin: $isAdmin');

      return result.user;
    } catch (e) {
      throw Exception('Erreur de connexion : ${e.toString()}'.tr());
    }
  }

  Future<User?> registerWithEmail(
      String email, String password, String fullName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Envoi de l'email de vérification
      if (result.user != null) {
        await result.user!.sendEmailVerification();
      }

      await _firestore.collection('users').doc(result.user?.uid).set({
        'fullName'.tr(): fullName,
        'email'.tr(): email,
        'emailVerified': false, // Ajouter un champ de vérification
        'createdAt': FieldValue.serverTimestamp(),
      });

      return result.user;
    } catch (e) {
      print("Erreur d'inscription : $e"); // Affiche l'erreur dans la console
      throw Exception('Erreur d\'inscription : ${e.toString()}'.tr());
    }
  }

  Future<User?> signInWithSocial(AuthProvider provider) async {
    try {
      UserCredential result;
      switch (provider) {
        case AuthProvider.google:
          final GoogleSignInAccount? googleUser =
              await googleSignIn.signIn(); // Correction ici

          if (googleUser == null) {
            throw Exception('Annulation_par_l_utilisateur'.tr());
          }

          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;

          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          result = await _auth.signInWithCredential(credential);
          break;
      }

      if (result.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(result.user?.uid).set({
          'fullName': result.user?.displayName ?? '',
          'email': result.user?.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return result.user;
    } catch (e) {
      // Gestion des erreurs spécifiques
      String errorMessage = 'Erreur_de_connexion_Google'.tr();

      if (e is FirebaseAuthException) {
        errorMessage += ' : ${e.message}';
      } else if (e is PlatformException) {
        errorMessage += ' : ${e.message}';
      } else if (e.toString().contains('Annulation'.tr())) {
        errorMessage = 'Connexion_annulée'.tr();
      }

      throw Exception(errorMessage.tr());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Échec_envoi_email'.tr());
    }
  }
}

// ... reste du code inchangé ...

enum AuthProvider { google }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final PageController _pageController = PageController();
  final _signInFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  // final adminProvider = StateProvider<bool>((ref) => false);
  // Contrôleurs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regConfirmPasswordController =
      TextEditingController();

  void _navigateToMain() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/HomePage');
    }
  }

  Future<void> _handleSocialSignIn(AuthProvider provider) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithSocial(provider);
      if (mounted) _navigateToMain();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2A5C82);
    const accentColor = Color(0xFFF5A623);

    return Scaffold(
      extendBodyBehindAppBar:
          true, // Permet au background de passer derrière l'AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent background
        elevation: 0, // Supprime l'ombre
        systemOverlayStyle:
            SystemUiOverlayStyle.light, // Adapte la couleur des icônes système

        // Language change icon at the top left
        leading: IconButton(
          icon: Icon(Icons.language),
          onPressed: () {
            // Open a dialog to select language
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('sign_in_Page'.tr()),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        // francais
                        ListTile(
                          leading:
                              Image.asset('assets/flags/france.png', width: 32),
                          title: Text('Français'),
                          onTap: () {
                            context.setLocale(Locale('fr'));
                            Navigator.pop(context);
                          },
                        ),
                        // Arabic
                        ListTile(
                          leading:
                              Image.asset('assets/flags/arabic.png', width: 32),
                          title: Text('العربية'),
                          onTap: () {
                            context.setLocale(Locale('ar'));
                            Navigator.pop(context);
                          },
                        ),
                        // ENGLISH
                        ListTile(
                          leading: Image.asset('assets/flags/english.png',
                              width: 32),
                          title: Text('English'),
                          onTap: () {
                            context.setLocale(Locale('en'));
                            Navigator.pop(context);
                          },
                        ),
                        // Spanish
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/singinbackground.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Auth Panel
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildAuthPanel(context, true, primaryColor, accentColor),
              _buildAuthPanel(context, false, primaryColor, accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPanel(BuildContext context, bool isLogin, Color primaryColor,
      Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(26.0),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(140, 236, 234, 234).withValues(),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(102, 0, 0, 0).withValues(),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: isLogin ? _signInFormKey : _registerFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLogin
                              ? 'Bienvenue_à_Bord'.tr()
                              : 'Créer_un_compte'.tr(),
                          style: TextStyle(
                            fontSize: 28,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PlayfairDisplay',
                          ),
                        ),
                        const SizedBox(height: 15),

                        if (!isLogin)
                          _buildInputField(_regNameController,
                              'Nom_complet'.tr(), Icons.person, primaryColor),
                        if (!isLogin) const SizedBox(height: 15),

                        _buildInputField(
                          isLogin ? _emailController : _regEmailController,
                          'Email'.tr(),
                          Icons.email,
                          primaryColor,
                        ),
                        const SizedBox(height: 15),

                        _buildPasswordField(
                          isLogin
                              ? _passwordController
                              : _regPasswordController,
                          'Mot_de_passe'.tr(),
                          primaryColor,
                        ),
                        const SizedBox(height: 15),

                        if (!isLogin)
                          _buildPasswordField(
                            _regConfirmPasswordController,
                            'Confirmez_le_mot_de_passe'.tr(),
                            primaryColor,
                            validator: (value) {
                              if (value != _regPasswordController.text) {
                                return 'Les_mots_de_passe_ne_correspondent_pas'
                                    .tr();
                              }
                              return null;
                            },
                          ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPasswordDialog(context),
                            child: Text(
                              'mot_de_passe_oublie'.tr(),
                              style: TextStyle(
                                color: primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        _buildAuthButton(
                          isLogin ? 'Se_connecter'.tr() : 'Sinscrire'.tr(),
                          isLogin ? _handleSignIn : _handleRegister,
                          accentColor,
                        ),
                        const SizedBox(height: 8),

                        // Social Buttons
                        _buildSocialButtons(primaryColor),

                        TextButton(
                          onPressed: () => _pageController.animateToPage(
                            isLogin ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: Text(
                            isLogin
                                ? 'Créer_un_compte'.tr()
                                : 'Déjà_un_compte'.tr(),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label,
      IconData icon, Color color) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color.withValues()),
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color.withValues()),
        ),
      ),
      validator: (value) =>
          value!.isEmpty ? 'Ce_champ_est_obligatoire'.tr() : null,
    );
  }

  Widget _buildPasswordField(
      TextEditingController controller, String label, Color color,
      {FormFieldValidator<String>? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color.withValues()),
        prefixIcon: Icon(Icons.lock, color: color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color.withValues()),
        ),
      ),
      validator: validator ??
          (value) => value!.isEmpty ? 'Ce_champ_est_obligatoire'.tr() : null,
    );
  }

  Widget _buildAuthButton(String text, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons(Color color) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          'Ou_continuer_avec'.tr(),
          style: TextStyle(
            color: color.withValues(),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            _buildSocialButton(Buttons.google, AuthProvider.google, color),
            const SizedBox(height: 10),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
      Buttons buttonType, AuthProvider provider, Color color) {
    return SignInButton(
      buttonType,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues()),
      ),
      onPressed: () => _handleSocialSignIn(provider),
    );
  }

  Future<void> _handleSignIn() async {
    if (_signInFormKey.currentState!.validate()) {
      try {
        final authService = ref.read(authServiceProvider);
        final user = await authService.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );

        if (user != null) {
          final adminService = AdminService();
          final isAdmin = await adminService.isAdmin(user);

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              isAdmin ? '/adminDashboard' : '/HomePage',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_registerFormKey.currentState!.validate()) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.registerWithEmail(
          _regEmailController.text,
          _regPasswordController.text,
          _regNameController.text,
        );

        FirebaseApi.instance.addLocalNotification(
          title: 'Inscription réussie !'.tr(),
          body:
              'Un email de vérification a été envoyé à ${_regEmailController.text}'
                  .tr(),
          data: {'type': 'email_verification'},
        );

        // Afficher une alerte au lieu de naviguer directement
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Vérifiez votre email'.tr()),
              content: Text(
                'Un email de vérification a été envoyé à ${_regEmailController.text}.'
                        ' Veuillez vérifier votre boîte de réception.'
                    .tr(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/HomePage');
                  },
                  child: Text('OK'.tr()),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final primaryColor = Color.fromARGB(255, 10, 54, 90);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('réinitialiser_mdp'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('entrez_email_reinit'.tr()),
            const SizedBox(height: 15),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email'.tr(),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email, color: primaryColor),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('annuler'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                final authService = ref.read(authServiceProvider);
                await authService.sendPasswordResetEmail(emailController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('email_envoye'.tr())),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: Text('envoyer'.tr()),
          ),
        ],
      ),
    );
  }
}
