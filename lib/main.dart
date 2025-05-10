import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/package_selection_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/location_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/plan_detail_screen.dart';
import 'screens/plan_creation_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/itinerary.dart';
import 'firebase_options.dart';
import 'services/plan_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  
  try {
    // Daha önce init edilmişse Exception fırlatır
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
    // duplicate-app ise sessizce geç
  }
  
  await initializeDateFormatting('tr_TR', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PlanProvider(
            planService: PlanService(),
            authProvider: ctx.read<AuthProvider>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GezzyBuddy',
        theme: ThemeData(
          textTheme: GoogleFonts.nunitoSansTextTheme(
            Theme.of(context).textTheme,
          ),
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Colors.white,
          cardTheme: CardTheme(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          appBarTheme: AppBarTheme(
            titleTextStyle: GoogleFonts.nunitoSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (ctx) => WelcomeScreen(),
          '/login': (ctx) => LoginScreen(),
          '/register': (ctx) => RegisterScreen(),
          '/home': (ctx) => HomeScreen(),
          '/plan': (ctx) => PlanScreen(),
          SplashScreen.routeName: (_) => SplashScreen(),
          OnboardingScreen.routeName: (_) => OnboardingScreen(),
          ProfileScreen.routeName: (_) => ProfileScreen(),
          PlanDetailScreen.routeName: (context) => PlanDetailScreen.fromArguments(
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
          ),
          PlanCreationScreen.routeName: (context) => PlanCreationScreen.fromArguments(
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
          ),
        },
      ),
    );
  }
} 