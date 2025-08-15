import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des utilisateurs'.tr()),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['email'] ?? ''),
                subtitle:
                    Text(data['isAdmin'] == true ? 'Admin' : 'Utilisateur'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditUserDialog(context, document.id, data);
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddUserDialog(context);
        },
      ),
    );
  }

  void _showEditUserDialog(
      BuildContext context, String userId, Map<String, dynamic> userData) {
    final emailController = TextEditingController(text: userData['email']);
    final isAdmin = ValueNotifier<bool>(userData['isAdmin'] ?? false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier utilisateur'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'.tr()),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isAdmin,
              builder: (context, value, child) => CheckboxListTile(
                title: Text('Administrateur'.tr()),
                value: value,
                onChanged: (bool? newValue) {
                  isAdmin.value = newValue ?? false;
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({
                'isAdmin': isAdmin.value,
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Enregistrer'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final isAdmin = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter utilisateur'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'.tr()),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Mot de passe'.tr()),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isAdmin,
              builder: (context, value, child) => CheckboxListTile(
                title: Text('Administrateur'.tr()),
                value: value,
                onChanged: (bool? newValue) {
                  isAdmin.value = newValue ?? false;
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final userCredential =
                    await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text,
                );

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userCredential.user?.uid)
                    .set({
                  'email': emailController.text,
                  'isAdmin': isAdmin.value,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text('Ajouter'.tr()),
          ),
        ],
      ),
    );
  }
}
