import 'package:flutter/material.dart';

class PackagePreferencesScreen extends StatefulWidget {
  final String packageType; // 'plaj' veya 'kulturel'
  const PackagePreferencesScreen({required this.packageType, Key? key}) : super(key: key);

  @override
  _PackagePreferencesScreenState createState() => _PackagePreferencesScreenState();
}

class _PackagePreferencesScreenState extends State<PackagePreferencesScreen> {
  final List<String> _selected = [];

  late final Map<String, List<String>> _optionsByType = {
    'plaj': [
      'Kahvaltı', 'Restoran', 'Kafe', 'Bar',
      'Halk Plajı', 'Ücretli Plaj',
    ],
    'kulturel': [
      'Kahvaltı', 'Restoran', 'Kafe', 'Bar',
      'Müze', 'Cami/Türbe', 'Kaleler', 'Açıkhava Müze',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final opts = _optionsByType[widget.packageType]!;

    return Scaffold(
      appBar: AppBar(title: Text('Tercihler (${widget.packageType.toUpperCase()})')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Wrap(
          spacing: 8, runSpacing: 8,
          children: opts.map((opt) {
            final sel = _selected.contains(opt);
            return ChoiceChip(
              label: Text(opt),
              selected: sel,
              onSelected: (on) {
                setState(() {
                  if (on) _selected.add(opt);
                  else _selected.remove(opt);
                });
              },
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Devam Et'),
        icon: Icon(Icons.arrow_forward),
        onPressed: _selected.isEmpty
          ? null
          : () {
              Navigator.of(context).pop(_selected);
            },
      ),
    );
  }
} 