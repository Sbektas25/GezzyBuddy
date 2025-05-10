import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Tema'),
            subtitle: Text(themeProvider.isDarkMode ? 'Karanlık' : 'Aydınlık'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
            ),
          ),
          ListTile(
            title: const Text('Çıkış Yap'),
            leading: const Icon(Icons.logout),
            onTap: () => authProvider.signOut(),
          ),
        ],
      ),
    );
  }
} 