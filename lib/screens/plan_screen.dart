import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plan_provider.dart';
import '../widgets/plan_tile.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/itinerary.dart';
import '../services/map_service.dart';
import 'plan_detail_screen.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({Key? key}) : super(key: key);

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // İlk yükleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().loadPlans();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePlans();
    }
  }

  Future<void> _loadMorePlans() async {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });
      await context.read<PlanProvider>().loadMorePlans();
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seyahat Planlarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PlanProvider>().loadPlans();
            },
          ),
        ],
      ),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, child) {
          if (planProvider.isLoading && planProvider.plans.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (planProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hata: ${planProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      planProvider.loadPlans();
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (planProvider.plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Henüz seyahat planınız yok',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/create-plan');
                    },
                    child: const Text('Yeni Plan Oluştur'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await planProvider.loadPlans();
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: planProvider.plans.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == planProvider.plans.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final plan = planProvider.plans[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      PlanDetailScreen.routeName,
                      arguments: plan,
                    );
                  },
                  child: PlanTile(plan: plan),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-plan');
        },
        child: const Icon(Icons.add),
      ),
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