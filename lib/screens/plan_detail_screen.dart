import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/map_service.dart';
import '../models/itinerary.dart';

class PlanDetailScreen extends StatefulWidget {
  static const String routeName = '/plan-detail';
  
  final Itinerary plan;

  const PlanDetailScreen({
    Key? key,
    required this.plan,
  }) : super(key: key);

  static PlanDetailScreen fromArguments(Map<String, dynamic> args) {
    return PlanDetailScreen(
      plan: args['plan'] as Itinerary,
    );
  }

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  bool _isMapVisible = false;
  late GoogleMapController _mapController;
  List<Polyline> _polylines = [];
  bool _isLoadingPolylines = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadPolylines() async {
    setState(() => _isLoadingPolylines = true);
    final polylines = await MapService().getRoutes(widget.plan);
    setState(() {
      _polylines = polylines;
      _isLoadingPolylines = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(
                  widget.plan.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Color(0xFF1a237e),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${widget.plan.numberOfDays} Günlük Plan',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF5c6bc0)),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(_isMapVisible ? Icons.close : Icons.map),
                    label: Text(_isMapVisible ? 'HARİTAYI GİZLE' : 'GEZİ ROTASINI HARİTADA GÖSTER'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      backgroundColor: const Color(0xFF5c6bc0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: Colors.blueAccent.withOpacity(0.3),
                    ),
                    onPressed: () async {
                      setState(() {
                        _isMapVisible = !_isMapVisible;
                      });
                      if (_isMapVisible && _polylines.isEmpty) {
                        await _loadPolylines();
                      }
                    },
                  ),
                ),
              ),
              if (_isMapVisible)
                _isLoadingPolylines
                    ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                    : Container(
                        height: 300,
                        margin: const EdgeInsets.only(top: 12, left: 8, right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.15),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(widget.plan.items.first.latitude!, widget.plan.items.first.longitude!),
                            zoom: 12,
                          ),
                          markers: _createMarkers(),
                          polylines: Set<Polyline>.of(_polylines),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                        ),
                      ),
              if (_isMapVisible) const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.plan.items.length,
                  separatorBuilder: (context, index) {
                    if (index < widget.plan.items.length - 1) {
                      final duration = widget.plan.items[index].travelDurationToNext;
                      if (duration != null && duration > 0) {
                        return Center(
                          child: Chip(
                            label: Text('Yol: $duration dk'),
                            backgroundColor: const Color(0xFFe3f2fd),
                            avatar: const Icon(Icons.directions_car, size: 18, color: Color(0xFF1976d2)),
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                  itemBuilder: (context, index) {
                    final activity = widget.plan.items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 6,
                      shadowColor: Colors.blueAccent.withOpacity(0.15),
                      color: Colors.white.withOpacity(0.95),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF5c6bc0),
                          child: Icon(Icons.location_on, color: Colors.white),
                        ),
                        title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1a237e))),
                        subtitle: Text(activity.description, style: const TextStyle(color: Color(0xFF5c6bc0))),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Set<Marker> _createMarkers() {
    return widget.plan.items.map((activity) {
      return Marker(
        markerId: MarkerId(activity.id),
        position: LatLng(activity.latitude!, activity.longitude!),
        infoWindow: InfoWindow(title: activity.title),
      );
    }).toSet();
  }
} 