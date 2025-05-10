import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profil')),
        body: Center(child: Text('Kullanıcı bilgisi bulunamadı.')),
      );
    }

    return Scaffold(
      // 1) SliverAppBar ile içe gömülen profil fotoğrafı
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            elevation: 2,
            backgroundColor: Colors.teal,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
              title: Text(user.displayName ?? user.email ?? '',
                  style: TextStyle(fontSize: 18)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Arka planda bir renk gradyanı
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade700, Colors.teal.shade300],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Profil fotoğrafı
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: user.photoURL != null
                            ? Image.network(
                                user.photoURL!,
                                width: 92,
                                height: 92,
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.person, size: 64, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2) Profil detayları & menü
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  // Email satırı
                  ListTile(
                    leading: Icon(Icons.email, color: Colors.teal),
                    title: Text(user.email ?? '',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Divider(),
                  // Örnek menü öğeleri
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Hesap Ayarları'),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/settings');
                          },
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.history),
                          title: Text('Geçmiş Planlarım'),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/history');
                          },
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.help_outline),
                          title: Text('Yardım & Destek'),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/support');
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  // 3) Çıkış butonu
                  ElevatedButton.icon(
                    icon: Icon(Icons.logout),
                    label: Text('Oturumu Kapat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: StadiumBorder(),
                    ),
                    onPressed: () {
                      auth.signOut();
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (_) => false);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 