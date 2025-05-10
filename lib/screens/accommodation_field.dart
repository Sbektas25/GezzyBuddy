import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/places_autocomplete_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccommodationField extends StatefulWidget {
  final void Function(LatLng latLng, String address) onSelected;
  const AccommodationField({required this.onSelected, Key? key}) : super(key: key);

  @override
  State<AccommodationField> createState() => _AccommodationFieldState();
}

class _AccommodationFieldState extends State<AccommodationField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _service = PlacesAutocompleteService(dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '');
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  title: Text(suggestion.description),
                  onTap: () async {
                    _controller.text = suggestion.description;
                    _removeOverlay();
                    final details = await _service.getPlaceDetails(suggestion.placeId);
                    if (details != null) {
                      widget.onSelected(LatLng(details.lat, details.lng), details.address);
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  final LayerLink _layerLink = LayerLink();

  Future<void> _onChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _suggestions = []);
      _removeOverlay();
      return;
    }
    setState(() => _loading = true);
    final results = await _service.fetchSuggestions(value);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _loading = false;
    });
    if (_suggestions.isNotEmpty && _focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: false,
        decoration: InputDecoration(
          labelText: 'Konaklama Lokasyonu',
          prefixIcon: Icon(Icons.location_on),
          suffixIcon: _loading ? Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ) : (_controller.text.isNotEmpty ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _controller.clear();
                _suggestions = [];
              });
              _removeOverlay();
            },
          ) : null),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: _onChanged,
        onTap: () {
          if (_suggestions.isNotEmpty) _showOverlay();
        },
        validator: (v) => v != null && v.isNotEmpty ? null : 'Lütfen bir lokasyon seçin',
      ),
    );
  }
} 