import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import 'package_selection_screen.dart';
import '../widgets/location_search_field.dart';
import '../config/api_keys.dart';
import '../services/places_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _selectedLocation;
  String? _selectedAddress;
  String? _selectedAccommodationName;
  bool _isLoading = false;

  void _onPlaceSelected(PlaceDetails details) {
    setState(() {
      _selectedLocation = details.location;
      _selectedAddress = details.formattedAddress;
      _selectedAccommodationName = details.name;
    });
  }

  Future<void> _createNewPlan() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir konaklama lokasyonu seçin.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PackageSelectionScreen(
            location: _selectedLocation!,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 3)),
            accommodationName: _selectedAccommodationName ?? _selectedAddress ?? '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GezzyBuddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                    'Hoş geldin, ${user?.displayName ?? 'Misafir'}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                        ),
                  const SizedBox(height: 24),
                  LocationSearchField(
                    apiKey: ApiKeys.googlePlacesApiKey,
                    hintText: 'Konaklama lokasyonunu seçin',
                    onPlaceSelected: _onPlaceSelected,
                            ),
                  if (_selectedAddress != null)
                                Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Seçilen lokasyon: $_selectedAddress',
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _createNewPlan,
                      style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                        ),
                    child: const Text('Yeni Plan Oluştur'),
                    ),
                  ],
              ),
      ),
    );
  }
} 