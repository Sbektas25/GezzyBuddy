import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/plan_provider.dart';
import '../models/itinerary.dart';
import '../services/places_service.dart';
import '../models/activity.dart';
import '../widgets/custom_widgets.dart';

class ActivityFormScreen extends StatefulWidget {
  static const routeName = '/activity-form';
  final Activity? activity;

  const ActivityFormScreen({Key? key, this.activity}) : super(key: key);

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _placesService = PlacesService();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  bool _isMapView = false;
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(39.9334, 32.8597); // Türkiye
  Set<Marker> _markers = {};
  List<PlacePrediction> _predictions = [];
  bool _isSearching = false;
  LatLng? _selectedLocation;
  final FocusNode _locationFocusNode = FocusNode();
  bool _showPredictions = false;

  @override
  void initState() {
    super.initState();
    _locationFocusNode.addListener(() {
      if (_locationFocusNode.hasFocus) {
        setState(() {
          _showPredictions = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _mapController?.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: InfoWindow(title: _locationController.text.isEmpty ? 'Seçilen Konum' : _locationController.text),
        ),
      };
    });
    _updateLocationFromLatLng(position);
  }

  Future<void> _updateLocationFromLatLng(LatLng position) async {
    try {
      final details = await _placesService.getPlaceDetails(position.latitude.toString() + ',' + position.longitude.toString());
      if (details != null) {
        setState(() {
          _locationController.text = details.formattedAddress;
        });
      }
    } catch (e) {
      print('Error getting location details: $e');
    }
  }

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
        _showPredictions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showPredictions = true;
    });

    try {
      final predictions = await _placesService.getPlacePredictions(input);
      if (mounted) {
        setState(() {
          _predictions = predictions;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Error getting place predictions: $e');
      if (mounted) {
        setState(() {
          _predictions = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectPlace(PlacePrediction prediction) async {
    final details = await _placesService.getPlaceDetails(prediction.placeId);
    if (details != null) {
      setState(() {
        _locationController.text = details.formattedAddress;
        _predictions = [];
        _showPredictions = false;
        _selectedLocation = LatLng(details.lat, details.lng);
        
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: LatLng(details.lat, details.lng),
            infoWindow: InfoWindow(title: details.formattedAddress),
          ),
        };
      });
      _locationFocusNode.unfocus();
    }
  }

  void _openMap() {
    setState(() {
      _isMapView = true;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir konum seçin')),
      );
      return;
    }

    final plan = Itinerary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      type: 'custom',
      location: _selectedLocation!,
      peopleCount: 1,
      preferences: [],
      days: [],
      description: _descriptionController.text,
      startDate: _startDate,
      endDate: _endDate,
      budget: 0.0,
      totalDistance: 0.0,
      totalPrice: 0.0,
    );

    try {
      await Provider.of<PlanProvider>(context, listen: false).createPlan(plan);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Klavyeyi ve tahminleri gizle
        FocusScope.of(context).unfocus();
        setState(() {
          _showPredictions = false;
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yeni Plan'),
          actions: [
            if (_isMapView)
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  setState(() {
                    _isMapView = false;
                  });
                },
              ),
          ],
        ),
        body: _isMapView
            ? Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation ?? _initialPosition,
                      zoom: _selectedLocation != null ? 15 : 6,
                    ),
                    onTap: _onMapTap,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                setState(() {
                                  _isMapView = false;
                                });
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  hintText: 'Konum ara...',
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: _searchPlaces,
                              ),
                            ),
                            if (_isSearching)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_predictions.isNotEmpty)
                    Positioned(
                      top: 80,
                      left: 16,
                      right: 16,
                      child: Card(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _predictions.length,
                          itemBuilder: (context, index) {
                            final prediction = _predictions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on),
                              title: Text(prediction.description),
                              onTap: () => _selectPlace(prediction),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Başlık'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen bir başlık girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Açıklama'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          TextFormField(
                            controller: _locationController,
                            focusNode: _locationFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Konum',
                              hintText: 'Konum aramak için yazın veya haritadan seçin',
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Image.network(
                                      'https://maps.gstatic.com/mapfiles/api-3/images/google_gray.png',
                                      width: 60,
                                    ),
                                    onPressed: _openMap,
                                    tooltip: 'Haritada göster',
                                  ),
                                ],
                              ),
                            ),
                            onChanged: _searchPlaces,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Lütfen bir konum seçin';
                              }
                              return null;
                            },
                          ),
                          if (_showPredictions && _predictions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Card(
                                elevation: 4,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _predictions.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final prediction = _predictions[index];
                                    return ListTile(
                                      leading: const Icon(Icons.location_on),
                                      title: Text(prediction.description),
                                      onTap: () => _selectPlace(prediction),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Başlangıç'),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(_startDate),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date == null) return;

                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_startDate),
                          );
                          if (time == null) return;

                          setState(() {
                            _startDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                      ),
                      ListTile(
                        title: const Text('Bitiş'),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(_endDate),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: _startDate,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date == null) return;

                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_endDate),
                          );
                          if (time == null) return;

                          setState(() {
                            _endDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _submitForm,
          child: const Icon(Icons.save),
        ),
      ),
    );
  }
} 