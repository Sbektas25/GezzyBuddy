import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  static const routeName = '/onboarding';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Spacer(flex: 2),
              // İkon + Başlık
              Icon(Icons.beach_access, size: 96, color: theme.primaryColor),
              SizedBox(height: 16),
              Text(
                'GezzyBuddy',
                style: theme.textTheme.headlineMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Hayalini kurduğun tatili şimdi planla.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              Spacer(flex: 3),

              // Giriş / Kayıt / Atla
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  shape: StadiumBorder(),
                ),
                child: Text('Giriş Yap'),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/login'),
              ),
              SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  shape: StadiumBorder(),
                ),
                child: Text('Kayıt Ol'),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/register'),
              ),
              SizedBox(height: 12),
              TextButton(
                child: Text('Sonra Atla', style: TextStyle(color: theme.primaryColor)),
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacementNamed('/home');
                },
              ),

              Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
} 