import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'proses':
        return Colors.blue;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'proses':
        return 'Diproses';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color),
      ),
      child: Text(_label,
          style: TextStyle(
              color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
