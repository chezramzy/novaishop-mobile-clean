import 'package:flutter/material.dart';

import '../../../design/design_system.dart';

/// Lightweight, dependency-free charts for the seller analytics screen.

/// A single bar in [SellerBarChart].
class SellerBarDatum {
  const SellerBarDatum({
    required this.label,
    required this.value,
    this.color = AppColors.deepInk,
  });

  final String label;
  final double value;
  final Color color;
}

/// An animated vertical bar chart. Bars grow from zero on first build.
class SellerBarChart extends StatelessWidget {
  const SellerBarChart({
    required this.data,
    this.height = 150,
    this.valueLabel,
    super.key,
  });

  final List<SellerBarDatum> data;
  final double height;

  /// Formats the value shown above the tallest bar (e.g. price formatting).
  final String Function(double value)? valueLabel;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Aucune donnée pour le moment.',
            style: TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
        ),
      );
    }
    final maxValue = data
        .map((datum) => datum.value)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < data.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _Bar(
                  datum: data[i],
                  fraction: (data[i].value / safeMax).clamp(0.0, 1.0),
                  delay: Duration(milliseconds: 40 * i),
                  valueLabel: valueLabel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatefulWidget {
  const _Bar({
    required this.datum,
    required this.fraction,
    required this.delay,
    this.valueLabel,
  });

  final SellerBarDatum datum;
  final double fraction;
  final Duration delay;
  final String Function(double value)? valueLabel;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final Animation<double> _grow = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.standard,
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = widget.valueLabel;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (formatter != null)
          AnimatedBuilder(
            animation: _grow,
            builder: (context, _) => Opacity(
              opacity: _grow.value,
              child: Text(
                formatter(widget.datum.value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _grow,
          builder: (context, _) {
            return FractionallySizedBox(
              heightFactor: (widget.fraction * _grow.value).clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.datum.color,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          widget.datum.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

/// An animated sparkline drawn from a list of values.
class SellerSparkline extends StatefulWidget {
  const SellerSparkline({
    required this.values,
    this.height = 90,
    this.color = AppColors.deepInk,
    super.key,
  });

  final List<double> values;
  final double height;
  final Color color;

  @override
  State<SellerSparkline> createState() => _SellerSparklineState();
}

class _SellerSparklineState extends State<SellerSparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.length < 2) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Pas assez de données.',
            style: TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
        ),
      );
    }
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _SparklinePainter(
            values: widget.values,
            color: widget.color,
            progress: Curves.easeOutCubic.transform(_controller.value),
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.progress,
  });

  final List<double> values;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.fold<double>(0, (a, b) => a > b ? a : b);
    final minValue = values.fold<double>(
      values.first,
      (a, b) => a < b ? a : b,
    );
    final range =
        (maxValue - minValue).abs() < 0.0001 ? 1.0 : maxValue - minValue;
    final stepX = size.width / (values.length - 1);

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          i * stepX,
          size.height -
              ((values[i] - minValue) / range) * (size.height - 8) -
              4,
        ),
    ];

    final visibleCount =
        (points.length * progress).ceil().clamp(2, points.length);
    final visible = points.sublist(0, visibleCount);

    final linePath = Path()..moveTo(visible.first.dx, visible.first.dy);
    for (final point in visible.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(visible.last.dx, size.height)
      ..lineTo(visible.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: .25),
            color.withValues(alpha: .02),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
      visible.last,
      4,
      Paint()..color = color,
    );
    canvas.drawCircle(
      visible.last,
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}

/// A horizontal proportion bar used for the order-status distribution.
class SellerProportionBar extends StatelessWidget {
  const SellerProportionBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    super.key,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: fraction),
              duration: AppMotion.slow,
              curve: AppMotion.standard,
              builder: (context, animatedFraction, _) => Stack(
                children: [
                  Container(height: 8, color: context.colors.surfaceMuted),
                  FractionallySizedBox(
                    widthFactor:
                        animatedFraction == 0 ? 0.001 : animatedFraction,
                    child: Container(height: 8, color: color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
