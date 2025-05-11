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
import 'package:gezzy_buddy/models/time_slot.dart';
import 'package:gezzy_buddy/models/activity_type.dart';
import '../providers/plan_provider.dart';
import 'package:intl/intl.dart';

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
  List<DayPlan>? _generatedPlan;

  @override
  void initState() {
    super.initState();
    _generatePlan();
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<PlanProvider>();
      await provider.createPlan(
        location: widget.location.toString(),
        startDate: widget.startTime,
        endDate: widget.endTime,
        preferences: widget.preferences,
      );
      setState(() {
        _generatedPlan = provider.plans;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
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
      textDirection: ui.TextDirection.ltr,
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
                        child: activity.photoUrl?.isNotEmpty == true
                            ? Image.network(
                                activity.photoUrl ?? '',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Oluşturuluyor'),
        backgroundColor: const Color(0xFF1a237e),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5c6bc0)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Planınız oluşturuluyor...',
                      style: TextStyle(
                        color: Color(0xFF1a237e),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hata: $_error',
                          style: const TextStyle(
                            color: Color(0xFF1a237e),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _generatePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5c6bc0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : _generatedPlan == null || _generatedPlan!.isEmpty
                    ? const Center(
                        child: Text(
                          'Plan oluşturulamadı',
                          style: TextStyle(
                            color: Color(0xFF1a237e),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _generatedPlan!.length,
                        itemBuilder: (context, index) {
                          final dayPlan = _generatedPlan![index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5c6bc0),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Gün ${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: dayPlan.activities.length,
                                  itemBuilder: (context, activityIndex) {
                                    final activity = dayPlan.activities[activityIndex];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFFe0eafc),
                                        child: Icon(
                                          _getActivityIcon(activity.type),
                                          color: const Color(0xFF5c6bc0),
                                        ),
                                      ),
                                      title: Text(
                                        activity.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1a237e),
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${DateFormat('HH:mm').format(activity.startTime)} - ${DateFormat('HH:mm').format(activity.endTime)}',
                                            style: const TextStyle(
                                              color: Color(0xFF5c6bc0),
                                            ),
                                          ),
                                          if (activity.photoUrl?.isNotEmpty == true)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  activity.photoUrl ?? '',
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.start:
        return Icons.home;
      case ActivityType.end:
        return Icons.flag;
      case ActivityType.accommodation:
        return Icons.hotel;
      case ActivityType.restaurant:
        return Icons.restaurant;
      case ActivityType.attraction:
        return Icons.attractions;
      case ActivityType.afternoon:
        return Icons.wb_sunny;
      case ActivityType.breakfast:
        return Icons.breakfast_dining;
      case ActivityType.lunch:
        return Icons.lunch_dining;
      case ActivityType.dinner:
        return Icons.dinner_dining;
      case ActivityType.beach:
        return Icons.beach_access;
      case ActivityType.cafe:
        return Icons.local_cafe;
      case ActivityType.bar:
        return Icons.local_bar;
      case ActivityType.night:
        return Icons.nightlight_round;
      case ActivityType.returnHome:
        return Icons.home;
    }
  }
} 