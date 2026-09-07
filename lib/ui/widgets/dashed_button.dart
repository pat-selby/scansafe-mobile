import 'package:flutter/material.dart';

import '../theme.dart';

/// The dashed-border scan affordance.
///
/// The one piece of visual wit in the product: the dashes read as a
/// viewfinder, which separates the camera action from the filled primary
/// button without introducing a second accent colour. Flutter has no dashed
/// border, so it is painted.
class DashedButton extends StatelessWidget {
  const DashedButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;

  /// Null renders the disabled state, which drops the accent green —
  /// green means safe, and a disabled control is not a verdict.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground =
        enabled ? AppColors.primary : AppColors.onSurfaceVariant;
    final background =
        enabled ? AppColors.successContainer : AppColors.surfaceVariant;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: CustomPaint(
            // foregroundPainter, not painter: the child's filled Container
            // would paint straight over a background painter's dashes.
            foregroundPainter: _DashedBorderPainter(
              color: foreground,
              radius: AppRadius.md,
            ),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: foreground),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: AppType.button.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          Radius.circular(radius),
        ),
      );

    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
