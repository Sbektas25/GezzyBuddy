import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String description;
  final String placeId;
  PlaceSuggestion({required this.description, required this.placeId});
}

class PlaceDetails {
  final String address;
  final double lat;
  final double lng;
  PlaceDetails({required this.address, required this.lat, required this.lng});
}

class PlacesAutocompleteService {
  final String apiKey;
  PlacesAutocompleteService(this.apiKey);

  Future<List<PlaceSuggestion>> fetchSuggestions(String input) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&language=tr&key=$apiKey',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);
    if (data['status'] == 'OK') {
      return (data['predictions'] as List)
          .map((p) => PlaceSuggestion(
                description: p['description'],
                placeId: p['place_id'],
              ))
          .toList();
    }
    return [];
  }

  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=formatted_address,geometry&language=tr&key=$apiKey',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);
    if (data['status'] == 'OK') {
      final result = data['result'];
      final loc = result['geometry']['location'];
      return PlaceDetails(
        address: result['formatted_address'],
        lat: loc['lat'],
        lng: loc['lng'],
      );
    }
    return null;
  }
} 