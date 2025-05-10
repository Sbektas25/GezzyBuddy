import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/itinerary.dart';
import '../utils/app_utils.dart';

class ActivityCard extends StatelessWidget {
  final ItineraryItem activity;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ActivityCard({
    Key? key,
    required this.activity,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (activity.travelDurationSec != null && activity.travelDurationSec! > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text('${(activity.travelDurationSec! / 60).round()} dk'),
                  avatar: Icon(Icons.directions_car, size: 18),
                ),
              ],
            ),
          ),
        Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(activity.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.description),
                const SizedBox(height: 4),
                Text(
                  '${activity.startTime.hour}:${activity.startTime.minute.toString().padLeft(2, '0')} - '
                  '${activity.endTime.hour}:${activity.endTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (activity.cost > 0)
                  Text(
                    'Cost: \$${activity.cost.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: onDelete,
                ),
              ],
            ),
            onTap: onTap,
          ),
        ),
      ],
    );
  }
} 