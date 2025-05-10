import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/activity.dart';
import '../models/day_plan.dart';
import '../services/plan_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/directions_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;

class PlanCreationScreen extends StatefulWidget {
  static const String routeName = '/plan-creation';
  
  final LatLng location;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> preferences;
  final String accommodationName;

  const PlanCreationScreen({
    Key? key,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.preferences,
    required this.accommodationName,
  }) : super(key: key);

  static PlanCreationScreen fromArguments(Map<String, dynamic> args) {
    return PlanCreationScreen(
      location: args['location'] as LatLng,
      startTime: args['startTime'] as DateTime,
      endTime: args['endTime'] as DateTime,
      preferences: args['preferences'] as List<String>,
      accommodationName: args['accommodationName'] as String,
    );
  }

  @override
  State<PlanCreationScreen> createState() => _PlanCreationScreenState();
}

class _PlanCreationScreenState extends State<PlanCreationScreen> {
  final PlanService _planService = PlanService();
  final DirectionsService _directionsService = DirectionsService();
  List<Activity> _activities = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _error;
  GoogleMapController? _mapController;
  String? _currentPlanId;

  @override
  void initState() {
    super.initState();
    _generatePlan();
  }

  Future<void> _generatePlan() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final dayPlans = await _planService.generatePlan(
        location: widget.location,
        startTime: widget.startTime,
        endTime: widget.endTime,
        preferences: widget.preferences,
        accommodationName: widget.accommodationName,
      );

      setState(() {
        _activities = dayPlans
            .expand((dayPlan) => dayPlan.activities)
            .toList();
        _updateMarkers();
        _updateRoutes();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateMarkers() async {
    _markers.clear();
    for (int i = 0; i < _activities.length; i++) {
      final activity = _activities[i];
      final markerId = String.fromCharCode(65 + i); // A, B, C ...
      final markerIcon = await _createMarkerIcon(markerId);
      _markers.add(Marker(
        markerId: MarkerId(activity.placeId),
        position: activity.position,
        infoWindow: InfoWindow(
          title: activity.name,
          snippet: (activity.tags.contains('accommodation') || activity.type == ActivityType.start || activity.type == ActivityType.end)
              ? widget.accommodationName
              : activity.address,
        ),
        icon: markerIcon,
        zIndex: i.toDouble(),
      ));
    }
    setState(() {});
  }

  Future<BitmapDescriptor> _createMarkerIcon(String label) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = Colors.blue;
    final radius = 32.0;
    canvas.drawCircle(const Offset(32, 32), radius, paint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(32 - textPainter.width / 2, 32 - textPainter.height / 2));
    final image = await pictureRecorder.endRecording().toImage(64, 64);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _updateRoutes() async {
    if (_markers.isEmpty) return;

    final directionsService = DirectionsService();
    _polylines.clear();

    final markerList = _markers.toList();
    for (int i = 0; i < markerList.length - 1; i++) {
      final origin = markerList[i].position;
      final destination = markerList[i + 1].position;

      final directions = await directionsService.getDirections(
        origin: origin,
        destination: destination,
      );

      List<LatLng> points = [];
      if (directions != null && directions.polylinePoints.isNotEmpty) {
        points = Directions.decodePolyline(directions.polylinePoints);
      } else {
        points = [origin, destination];
      }

      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          points: points,
          color: Colors.blue,
          width: 5,
        ),
      );
    }

    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    final bounds = _markers.fold<LatLngBounds>(
      LatLngBounds(
        southwest: _markers.first.position,
        northeast: _markers.first.position,
      ),
      (bounds, marker) => LatLngBounds(
        southwest: LatLng(
          min(bounds.southwest.latitude, marker.position.latitude),
          min(bounds.southwest.longitude, marker.position.longitude),
        ),
        northeast: LatLng(
          max(bounds.northeast.latitude, marker.position.latitude),
          max(bounds.northeast.longitude, marker.position.longitude),
        ),
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  Future<void> _handleFavorite(Activity activity) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.toggleFavoriteActivity(activity.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authProvider.favoriteActivities.contains(activity.id)
              ? 'Favorilere eklendi!'
              : 'Favorilerden çıkarıldı!',
        ),
      ),
    );
  }

  Future<void> _handleSavePlan() async {
    if (_currentPlanId == null) {
      // Create new plan
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final planId = DateTime.now().millisecondsSinceEpoch.toString();
      await authProvider.savePlan(planId);
      _currentPlanId = planId;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan kaydedildi!')),
      );
    }
  }

  Future<void> _handleMarkAsVisited(Activity activity) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.markActivityAsVisited(activity.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ziyaret edildi olarak işaretlendi!')),
    );
  }

  Future<void> _handleRateActivity(Activity activity) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktiviteyi Değerlendir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Puanınız:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < 4 ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () => Navigator.pop(context, (index + 1).toDouble()),
                );
              }),
            ),
          ],
        ),
      ),
    );

    if (rating != null) {
      await authProvider.rateActivity(activity.id, rating, null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Değerlendirmeniz kaydedildi!')),
      );
    }
  }

  void _showActivityDetailModal(Activity activity, String markerLetter) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<bool>(
          future: authProvider.isActivityVisited(activity.id),
          builder: (context, snapshotVisited) {
            final isVisited = snapshotVisited.data ?? false;
            final isFavorite = authProvider.favoriteActivities.contains(activity.id);
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(markerLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              activity.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: activity.photoUrl.isNotEmpty
                            ? Image.network(
                                activity.photoUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.place, size: 64),
                              )
                            : const Icon(Icons.place, size: 64),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (activity.tags.contains('accommodation') || activity.type == ActivityType.start || activity.type == ActivityType.end)
                                  ? widget.accommodationName
                                  : activity.address,
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.map, color: Colors.green),
                            tooltip: "Google Maps'te Aç",
                            onPressed: () {
                              // Google Maps'te aç
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.orange, size: 22),
                          const SizedBox(width: 4),
                          Text('${activity.rating} / 5', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text('(${activity.reviews} yorum)'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (!(activity.tags.contains('accommodation') || activity.type == ActivityType.start || activity.type == ActivityType.end)) ...[
                            Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                              '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')} - '
                              '${activity.endTime.hour.toString().padLeft(2, '0')}:${activity.endTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(_turkceZamanDilimi(activity.timeSlot)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Tooltip(
                            message: 'Favori',
                            child: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                              onPressed: () => _handleFavorite(activity),
                            ),
                          ),
                          Tooltip(
                            message: 'Ziyaret Edildi',
                            child: IconButton(
                              icon: Icon(
                                isVisited ? Icons.check_circle : Icons.check_circle_outline,
                                color: isVisited ? Colors.green : Colors.grey,
                              ),
                              onPressed: () => _handleMarkAsVisited(activity),
                            ),
                          ),
                          Tooltip(
                            message: 'Beğen',
                            child: IconButton(
                              icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.blue),
                              onPressed: () {},
                            ),
                          ),
                          Tooltip(
                            message: 'Kaydet',
                            child: IconButton(
                              icon: const Icon(Icons.bookmark_border, color: Colors.purple),
                              onPressed: () {},
                            ),
                          ),
                          Tooltip(
                            message: 'Değerlendir',
                            child: IconButton(
                              icon: const Icon(Icons.star_border, color: Colors.amber),
                              onPressed: () => _handleRateActivity(activity),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generatePlan,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _handleSavePlan,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: widget.location,
                          zoom: 14,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        onMapCreated: _onMapCreated,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: true,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _activities.length,
                        separatorBuilder: (context, index) {
                          // İki aktivite arası geçiş süresi ve ok
                          final from = _activities[index];
                          final to = _activities[index + 1];
                          final duration = to.startTime.difference(from.endTime).inMinutes.abs();
                          return Column(
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_downward, color: Colors.blueGrey, size: 20),
                                  const SizedBox(width: 4),
                                  Chip(
                                    label: Text('$duration dk', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    backgroundColor: Colors.blue.shade50,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                          );
                        },
                        itemBuilder: (context, index) {
                          final activity = _activities[index];
                          final isFavorite = authProvider.favoriteActivities.contains(activity.id);
                          final markerLetter = String.fromCharCode(65 + index); // A, B, C ...
                          return GestureDetector(
                            onTap: () => _showActivityDetailModal(activity, markerLetter),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Zaman ve harf etiketi
                                Column(
                                  children: [
                                    Text(
                                      '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Text(markerLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                // Kart
                                Expanded(
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  activity.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                                  color: isFavorite ? Colors.red : Colors.grey,
                                                ),
                                                tooltip: 'Favoriye ekle',
                                                onPressed: () => _handleFavorite(activity),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: activity.photoUrl.isNotEmpty
                                                ? Image.network(
                                                    activity.photoUrl,
                                                    width: double.infinity,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) =>
                                                        const Icon(Icons.place, size: 48),
                                                  )
                                                : const Icon(Icons.place, size: 48),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            (activity.tags.contains('accommodation') || activity.type == ActivityType.start || activity.type == ActivityType.end)
                                                ? widget.accommodationName
                                                : activity.address,
                                            style: const TextStyle(color: Colors.grey)),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.orange, size: 18),
                                              const SizedBox(width: 4),
                                              Text('${activity.rating} / 5'),
                                              const SizedBox(width: 8),
                                              Text('(${activity.reviews} yorum)'),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              if (!(activity.tags.contains('accommodation') || activity.type == ActivityType.start || activity.type == ActivityType.end)) ...[
                                                Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')} - '
                                                  '${activity.endTime.hour.toString().padLeft(2, '0')}:${activity.endTime.minute.toString().padLeft(2, '0')}',
                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Text(_turkceZamanDilimi(activity.timeSlot)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Tooltip(
                                                message: 'Ziyaret edildi',
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.check_circle,
                                                    color: isFavorite ? Colors.green : Colors.grey,
                                                  ),
                                                  onPressed: () => _handleMarkAsVisited(activity),
                                                ),
                                              ),
                                              Tooltip(
                                                message: 'Beğen',
                                                child: IconButton(
                                                  icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.blue),
                                                  onPressed: () {},
                                                ),
                                              ),
                                              Tooltip(
                                                message: 'Kaydet',
                                                child: IconButton(
                                                  icon: const Icon(Icons.bookmark_border, color: Colors.purple),
                                                  onPressed: () {},
                                                ),
                                              ),
                                              Tooltip(
                                                message: 'Değerlendir',
                                                child: IconButton(
                                                  icon: const Icon(Icons.star_border, color: Colors.amber),
                                                  onPressed: () => _handleRateActivity(activity),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  String _turkceZamanDilimi(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.breakfast:
        return 'Kahvaltı';
      case TimeSlot.lunch:
        return 'Öğle';
      case TimeSlot.dinner:
        return 'Akşam';
      case TimeSlot.night:
        return 'Gece';
      default:
        return '';
    }
  }
} 