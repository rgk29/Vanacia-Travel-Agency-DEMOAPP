import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/HomePage', (route) => false);
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        print('Erreur_de_déconnexion: $e');
      }
    }
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'.tr()),
        content: Text('Voulez_vous_vraiment_vous_déconnecter'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            child: Text('Déconnecter'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'.tr()),
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: Colors.white,
          fontSize: 29,
          fontWeight: FontWeight.w400,
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 42, 94, 116), Color(0xFF34B5E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          StreamBuilder<User?>(
            stream: _auth.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _showLogoutConfirmation,
                );
              }
              return Container();
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/profil.jpg'),
            colorFilter: ColorFilter.mode(
                const Color.fromARGB(255, 0, 0, 0).withValues(),
                BlendMode.dstATop),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<User?>(
          stream: _auth.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              return _UserProfileSection(
                user: snapshot.data!,
              );
            }

            // Partie pour les utilisateurs non connectés
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _GuestMenuSection(
                    onShowComingSoon: () => _showComingSoon(context),
                  ),
                  const SizedBox(height: 40),
                  _LoginPrompt(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Ajoutez ces nouvelles classes
class _GuestMenuSection extends StatelessWidget {
  final VoidCallback onShowComingSoon;

  const _GuestMenuSection({
    required this.onShowComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuTile(
          icon: Icons.info,
          title: 'qui_sommes_nous'.tr(),
          onTap: () =>
              Navigator.pushNamed(context, '/aboutus'), // Nouvelle route
        ),
        _MenuTile(
          icon: Icons.help,
          title: 'besoin_daide'.tr(),
          onTap: () => Navigator.pushNamed(context, '/help'), // Nouvelle route
        ),
      ],
    );
  }
}

class _UserProfileSection extends StatelessWidget {
  final User user;

  const _UserProfileSection({
    required this.user,
  });

  String _getAvatarText(String email) {
    final emailPrefix = email.split('@').first;
    return emailPrefix.length >= 3
        ? emailPrefix.substring(0, 3).toUpperCase()
        : emailPrefix.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String userEmail = user.email ?? '';
    final String avatarText = _getAvatarText(userEmail);
    CircleAvatar(
      radius: 60,
      backgroundColor: Color(0xFF34B5E5),
      child: CircleAvatar(
        radius: 55,
      ),
    );

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur_de_chargement_des_données'.tr()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('Profil non trouvé'.tr()));
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final String displayName =
            userData?['fullName'] ?? userEmail.split('@').first;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color.fromARGB(255, 5, 8, 9),
                backgroundImage: userData?['photoUrl'] != null
                    ? NetworkImage(userData!['photoUrl'])
                    : null,
                child: userData?['photoUrl'] == null
                    ? Text(
                        avatarText,
                        style: const TextStyle(
                          fontSize: 24,
                          fontFamily: 'PlayfairDisplay',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PlayfairDisplay',
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                userEmail,
                style: TextStyle(
                  fontSize: 20,
                  color: const Color.fromARGB(255, 249, 248, 248),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _ProfileMenuSection(),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileMenuSection extends StatelessWidget {
  const _ProfileMenuSection();

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('bientot_disponible'.tr()),
        content: Text('cette_fonctionnalite_arrive_bientot'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuTile(
          icon: Icons.payment,
          title: 'informations_paiement'.tr(),
          onTap: () => Navigator.pushNamed(context, '/payment'),
        ),
        _MenuTile(
          icon: Icons.security,
          title: 'securite'.tr(),
          onTap: () =>
              Navigator.pushNamed(context, '/security'), // Nouvelle route
        ),
        _MenuTile(
          icon: Icons.info,
          title: 'qui_sommes_nous'.tr(),
          onTap: () => Navigator.pushNamed(context, '/aboutus'),
        ),
        _MenuTile(
          icon: Icons.help,
          title: 'besoin_daide'.tr(),
          onTap: () => Navigator.pushNamed(context, '/help'), // Nouvelle route
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // return ListTile(
    // leading: Icon(icon),
    // title: Text(title),
    // trailing: const Icon(Icons.chevron_right),
    // onTap: onTap,

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(199, 255, 255, 255).withValues(),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 15, 71, 93).withValues(),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFF34B5E5)),
        ),
        title: Text(title,
            style: TextStyle(
              color: Color(0xFF0F3443),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            )),
        trailing:
            Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF34B5E5)),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.travel_explore, size: 100, color: Color(0xFF34B5E5)),
          const SizedBox(height: 30),
          Text(
            'Connectez_vous_pour_accéder_à_votre_profil'.tr(),
            style: TextStyle(
              fontSize: 20, // Taille augmentée
              color: Color(0xFF0F3443),
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: Icon(Icons.login, color: Colors.white),
            label: Text(
              'Se_connecter'.tr(),
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/AuthPage', (route) => false),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              backgroundColor: Color(0xFF34B5E5),
              elevation: 5,
              shadowColor: Color.fromARGB(255, 6, 16, 20).withValues(),
            ),
          ),
        ],
      ),
    );
  }
}

// Ajoutez cette méthode dans ProfileScreenState
void _showComingSoon(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('bientot_disponible'.tr()),
      content: Text('cette_fonctionnalite_arrive_bientot'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
