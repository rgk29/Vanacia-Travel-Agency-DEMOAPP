import 'package:agencedevoyage/admin/admin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminRouteGuard extends ConsumerWidget {
  final Widget child;

  const AdminRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = FirebaseAuth.instance;
    final adminService = AdminService();

    return FutureBuilder<bool>(
      future: adminService.isAdmin(auth.currentUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/HomePage');
          });
          return const Scaffold(body: Center(child: Text('Accès refusé')));
        }

        return child;
      },
    );
  }
}
