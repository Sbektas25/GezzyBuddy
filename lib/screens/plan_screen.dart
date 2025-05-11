import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plan_provider.dart';
import '../widgets/plan_tile.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/itinerary.dart';
import '../services/map_service.dart';
import 'plan_detail_screen.dart';
import 'plan_creation_screen.dart';
import '../models/time_slot.dart';
import '../models/activity_type.dart';
import '../models/day_plan.dart';
import '../models/activity.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({Key? key}) : super(key: key);

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showMap = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Scroll işlemleri için gerekirse buraya eklenebilir
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Seyahat Planlarım', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1a237e))),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5c6bc0)),
            onPressed: () {
              // Yenileme işlemi için gerekirse buraya eklenebilir
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<PlanProvider>(
          builder: (context, planProvider, child) {
            final plans = planProvider.plans;
            return Column(
              children: [
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(_showMap ? Icons.close : Icons.map),
                  label: Text(_showMap ? 'Haritayı Gizle' : 'Gezi Rotasını Haritada Göster'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5c6bc0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  onPressed: () {
                    setState(() => _showMap = !_showMap);
                  },
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: plans.isEmpty
                      ? const SizedBox(height: 300)
                      : SizedBox(
                          height: 300,
                          child: GoogleMap(
                            onMapCreated: (c) => _mapController = c,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(plans.first.activities.first.position.latitude, plans.first.activities.first.position.longitude),
                              zoom: 13,
                            ),
                            markers: _buildMarkers(plans),
                            polylines: {_buildPolyline(plans)},
                          ),
                        ),
                  crossFadeState: _showMap ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      // Yenileme işlemi için gerekirse buraya eklenebilir
                    },
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: plans.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 6,
                          shadowColor: Colors.blueAccent.withOpacity(0.10),
                          color: Colors.white.withOpacity(0.97),
                          child: ListTile(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                PlanDetailScreen.routeName,
                                arguments: {'plan': plan},
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF5c6bc0),
                              child: const Icon(Icons.map, color: Colors.white),
                            ),
                            title: Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1a237e))),
                            subtitle: Text('${plan.numberOfDays} gün  |  ${plan.location}', style: const TextStyle(color: Color(0xFF5c6bc0))),
                            trailing: const Icon(Icons.chevron_right, color: Color(0xFF5c6bc0)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5c6bc0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        onPressed: () {
          Navigator.pushNamed(context, PlanCreationScreen.routeName);
        },
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Set<Marker> _buildMarkers(List<DayPlan> plans) {
    final activities = plans.expand((plan) => plan.activities).toList();
    return activities.asMap().entries.map((entry) {
      final activity = entry.value;
      return Marker(
        markerId: MarkerId(activity.id),
        position: activity.position,
        infoWindow: InfoWindow(
          title: activity.name,
          snippet: activity.address,
        ),
      );
    }).toSet();
  }

  Polyline _buildPolyline(List<DayPlan> plans) {
    final activities = plans.expand((plan) => plan.activities).toList();
    return Polyline(
      polylineId: const PolylineId('route'),
      points: activities.map((a) => a.position).toList(),
      color: Colors.blue,
      width: 3,
    );
  }
}

// Plan detay ekranı
// PlanTile veya plan seçimi yapılan yerde:
// KALDIRILDI: Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => PlanDetailScreen(plan: plan),
//   ),
// ); 