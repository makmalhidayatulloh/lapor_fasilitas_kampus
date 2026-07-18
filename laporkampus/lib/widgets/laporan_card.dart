import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/laporan.dart';
import 'status_badge.dart';

class LaporanCard extends StatelessWidget {
  final Laporan laporan;
  final VoidCallback onTap;

  const LaporanCard({super.key, required this.laporan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: laporan.fotoUrl != null
                  ? Image.network(
                      laporan.fotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    )
                  : const Icon(Icons.image_not_supported),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(laporan.judul,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(laporan.kategoriNama,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 6),
                    StatusBadge(status: laporan.status),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm')
                          .format(laporan.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
