// PATH: lib/modules/dashboard/widgets/chart_placeholder.dart

import 'package:flutter/material.dart';

class ChartPlaceholder extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final String valueLabel;

  const ChartPlaceholder({
    super.key,
    required this.title,
    required this.data,
    required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: ChartPainter(data: data),
                child: Container(),
              ),
            ),
            SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final colors = [
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.red,
                ];

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text('${item['label']}: ${item[valueLabel]}'),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  ChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    // Draw simple bar chart
    final barWidth = size.width / (data.length + 1);
    final maxValue = data
        .map((d) => d['value'] as num)
        .reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final value = item['value'] as num;
      final height = (value / maxValue) * (size.height - 40);

      paint.color = colors[i % colors.length];

      final x = (i + 1) * barWidth;
      final y = size.height - height - 20;

      canvas.drawRect(
        Rect.fromLTWH(x - barWidth / 3, y, barWidth / 1.5, height),
        paint..style = PaintingStyle.fill,
      );
    }

    // Draw axes
    paint.color = Colors.grey;
    paint.style = PaintingStyle.stroke;

    // Y-axis
    canvas.drawLine(Offset(20, 10), Offset(20, size.height - 20), paint);
    // X-axis
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(size.width - 10, size.height - 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
