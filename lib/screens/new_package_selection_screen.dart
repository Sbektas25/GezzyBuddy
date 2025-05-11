import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plan_provider.dart';
import 'plan_creation_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NewPackageSelectionScreen extends StatefulWidget {
  final LatLng location;
  final DateTime startDate;
  final DateTime endDate;
  final String accommodationName;

  const NewPackageSelectionScreen({
    Key? key,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.accommodationName,
  }) : super(key: key);

  @override
  State<NewPackageSelectionScreen> createState() => _NewPackageSelectionScreenState();
}

class _NewPackageSelectionScreenState extends State<NewPackageSelectionScreen> {
  final List<String> _selectedPreferences = [];
  bool _isLoading = false;
  DateTime? _selectedStartDateTime;
  DateTime? _selectedEndDateTime;

  void _togglePreference(String preference) {
    setState(() {
      if (_selectedPreferences.contains(preference)) {
        _selectedPreferences.remove(preference);
      } else {
        _selectedPreferences.add(preference);
      }
    });
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: isStart ? 8 : 23, minute: isStart ? 0 : 59),
    );
    if (time == null) return;
    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _selectedStartDateTime = selected;
      } else {
        _selectedEndDateTime = selected;
      }
    });
  }

  Future<void> _createPlan() async {
    if (_selectedPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir tercih seçin')),
      );
      return;
    }
    if (_selectedStartDateTime == null || _selectedEndDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen başlangıç ve bitiş saatini seçin')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final provider = context.read<PlanProvider>();
      await provider.createPlan(
        location: widget.location.toString(),
        startDate: _selectedStartDateTime!,
        endDate: _selectedEndDateTime!,
        preferences: _selectedPreferences,
      );
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        PlanCreationScreen.routeName,
        arguments: {
          'location': widget.location,
          'startTime': _selectedStartDateTime!,
          'endTime': _selectedEndDateTime!,
          'preferences': _selectedPreferences,
          'accommodationName': widget.accommodationName,
        },
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paket Seçimi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Tercihlerinizi Seçin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Kahvaltı',
                          'Restaurant / Lokanta',
                          'Kafe',
                          'Bar',
                          'Halk Plajı',
                          'Ücretli Plaj',
                        ].map((preference) {
                          final isSelected = _selectedPreferences.contains(preference);
                          return FilterChip(
                            label: Text(preference),
                            selected: isSelected,
                            onSelected: (selected) => _togglePreference(preference),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      ListTile(
                        title: const Text('Başlangıç Saati'),
                        subtitle: Text(_selectedStartDateTime != null
                            ? '${_selectedStartDateTime!.day}.${_selectedStartDateTime!.month}.${_selectedStartDateTime!.year}  ${_selectedStartDateTime!.hour.toString().padLeft(2, '0')}:${_selectedStartDateTime!.minute.toString().padLeft(2, '0')}'
                            : 'Seçilmedi'),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _pickDateTime(isStart: true),
                      ),
                      ListTile(
                        title: const Text('Bitiş Saati'),
                        subtitle: Text(_selectedEndDateTime != null
                            ? '${_selectedEndDateTime!.day}.${_selectedEndDateTime!.month}.${_selectedEndDateTime!.year}  ${_selectedEndDateTime!.hour.toString().padLeft(2, '0')}:${_selectedEndDateTime!.minute.toString().padLeft(2, '0')}'
                            : 'Seçilmedi'),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _pickDateTime(isStart: false),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Seçilen Tercihler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedPreferences.isEmpty)
                        const Text('Henüz tercih seçilmedi')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedPreferences.map((preference) {
                            return Chip(
                              label: Text(preference, style: const TextStyle(fontSize: 12)),
                              onDeleted: () => _togglePreference(preference),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _createPlan,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Plan Oluştur'),
                  ),
                ),
              ],
            ),
    );
  }
} 