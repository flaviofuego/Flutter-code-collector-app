import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/barcode_scanner/pages/scanner_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final userName = authState is AuthLoggedIn ? authState.user.name : 'Usuario';
    final userEmail = authState is AuthLoggedIn ? authState.user.email : '';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName[0].toUpperCase(),
                style: const TextStyle(fontSize: 40.0),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.task_alt),
            title: const Text('Gestor de Tareas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, HomePage.route());
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Escáner de Códigos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, ScannerPage.route());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implementar página de configuración
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              context.read<AuthCubit>().logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
