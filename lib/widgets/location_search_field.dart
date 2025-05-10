import 'package:flutter/material.dart';
import '../services/places_service.dart';
import 'dart:async';

class LocationSearchField extends StatefulWidget {
  final String apiKey;
  final Function(PlaceDetails) onPlaceSelected;
  final String? initialValue;
  final String hintText;

  const LocationSearchField({
    Key? key,
    required this.apiKey,
    required this.onPlaceSelected,
    this.initialValue,
    this.hintText = 'Search for a city...',
  }) : super(key: key);

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final TextEditingController _controller = TextEditingController();
  late PlacesService _placesService;
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _placesService = PlacesService(apiKey: widget.apiKey);
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    setState(() => _isLoading = true);
    final predictions = await _placesService.searchPlaces(query);
    setState(() {
      _predictions = predictions;
      _isLoading = false;
    });
  }

  Future<void> _selectPlace(PlacePrediction prediction) async {
    final details = await _placesService.getPlaceDetails(prediction.placeId);
    if (details != null) {
      widget.onPlaceSelected(details);
      _controller.text = prediction.description;
      setState(() => _predictions = []);
    }
  }

  Future<void> _onChanged(String value) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      await _searchPlaces(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _predictions = []);
                        },
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: _onChanged,
        ),
        if (_predictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(prediction.description),
                  onTap: () => _selectPlace(prediction),
                );
              },
            ),
          ),
      ],
    );
  }
} 