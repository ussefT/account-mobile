import 'dart:math';

import 'package:flutter/material.dart';

import '../accounts/account_scope.dart';
import '../localization/app_localizations.dart';
import '../transactions/account_transaction.dart';
import '../transactions/transaction_scope.dart';
import '../transactions/transaction_type.dart';
import '../utils/money.dart';
import '../utils/persian_formatting.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = AccountScope.of(context);
    final transactions = TransactionScope.of(context);
    final l10n = AppLocalizations.of(context);

    final selectedAccount = accounts.selectedAccount;
    final selectedAccountName = selectedAccount?.name ?? 'Cash';
    final initialBalanceCents = selectedAccount?.initialBalanceCents ?? 0;
    final txList = selectedAccount == null
        ? transactions.transactions
        : transactions.transactionsForAccount(selectedAccount.id);

    final series = _buildBalanceSeries(
      txList,
      initialBalanceCents: initialBalanceCents,
      maxDays: 30,
    );

    var incomeCents = 0;
    var expenseCents = 0;
    for (final t in txList) {
      if (t.type == TransactionType.income) {
        incomeCents += t.amountCents;
      } else {
        expenseCents += t.amountCents;
      }
    }

    final totalCents = incomeCents + expenseCents;
    final incomeRatio = totalCents == 0 ? 0.0 : incomeCents / totalCents;
    final expenseRatio = totalCents == 0 ? 0.0 : expenseCents / totalCents;

    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedAccountName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last ${series.isEmpty ? 0 : series.length} days',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 2.2,
                      child: series.isEmpty
                          ? const Center(child: Text('No data'))
                          : _LineChart(
                              values: series
                                  .map((e) => e.balanceCents)
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Current ${l10n.locale.languageCode == 'fa' ? formatMoneyPersian(series.isEmpty ? initialBalanceCents : series.last.balanceCents) : formatMoneyCents(series.isEmpty ? initialBalanceCents : series.last.balanceCents)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income vs expenses',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 2.2,
                      child: totalCents == 0
                          ? const Center(child: Text('No data'))
                          : Row(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: SizedBox(
                                      width: 160,
                                      height: 160,
                                      child: CustomPaint(
                                        painter: _PieChartPainter(
                                          slices: [
                                            _PieSlice(
                                              ratio: incomeRatio,
                                              color: Colors.green,
                                            ),
                                            _PieSlice(
                                              ratio: expenseRatio,
                                              color: Colors.red,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _LegendRow(
                                        color: Colors.green,
                                        label: 'Income',
                                        value: l10n.locale.languageCode == 'fa'
                                            ? formatMoneyPersian(incomeCents)
                                            : formatMoneyCents(incomeCents),
                                      ),
                                      const SizedBox(height: 8),
                                      _LegendRow(
                                        color: Colors.red,
                                        label: 'Expenses',
                                        value: l10n.locale.languageCode == 'fa'
                                            ? formatMoneyPersian(expenseCents)
                                            : formatMoneyCents(expenseCents),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BalancePoint {
  const _BalancePoint({required this.date, required this.balanceCents});

  final DateTime date;
  final int balanceCents;
}

List<_BalancePoint> _buildBalanceSeries(
  List<AccountTransaction> transactions, {
  required int initialBalanceCents,
  required int maxDays,
}) {
  if (transactions.isEmpty) return const [];

  final byDay = <DateTime, int>{};
  DateTime? minDay;
  DateTime? maxDay;

  for (final t in transactions) {
    final d = DateTime(t.date.year, t.date.month, t.date.day);
    minDay = minDay == null ? d : (d.isBefore(minDay) ? d : minDay);
    maxDay = maxDay == null ? d : (d.isAfter(maxDay) ? d : maxDay);
    final signed = t.type == TransactionType.income
        ? t.amountCents
        : -t.amountCents;
    byDay[d] = (byDay[d] ?? 0) + signed;
  }

  if (minDay == null || maxDay == null) return const [];

  final today = DateTime.now();
  final todayDay = DateTime(today.year, today.month, today.day);
  final endDay = maxDay.isAfter(todayDay) ? todayDay : maxDay;
  final startDayCandidate = endDay.subtract(Duration(days: maxDays - 1));
  final startDay = minDay.isAfter(startDayCandidate)
      ? minDay
      : startDayCandidate;

  var balance = initialBalanceCents;
  for (
    var day = minDay;
    day.isBefore(startDay);
    day = day.add(const Duration(days: 1))
  ) {
    balance += byDay[day] ?? 0;
  }

  final series = <_BalancePoint>[];
  for (
    var day = startDay;
    !day.isAfter(endDay);
    day = day.add(const Duration(days: 1))
  ) {
    balance += byDay[day] ?? 0;
    series.add(_BalancePoint(date: day, balanceCents: balance));
  }
  return series;
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV == 0 ? 1 : maxV - minV;

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : i / (values.length - 1);
      final y = (values[i] - minV) / range;
      points.add(Offset(x, 1.0 - y));
    }

    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _LineChartPainter(
        points: points,
        lineColor: scheme.primary,
        gridColor: scheme.outlineVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
  });

  final List<Offset> points;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (points.length < 2) return;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = Offset(points[i].dx * size.width, points[i].dy * size.height);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _PieSlice {
  const _PieSlice({required this.ratio, required this.color});

  final double ratio;
  final Color color;
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({required this.slices});

  final List<_PieSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0.0, (a, b) => a + b.ratio);
    if (total <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final radius = min(size.width, size.height) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    var start = -pi / 2;
    for (final s in slices) {
      if (s.ratio <= 0) continue;
      final sweep = 2 * pi * (s.ratio / total);
      final paint = Paint()..color = s.color;
      canvas.drawArc(arcRect, start, sweep, true, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}
