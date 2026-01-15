import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:diet_app/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  Map<String, dynamic>? data;
  Map<String, double> userGoals = {};
  bool isLoading = true;
  String selectedMetric = 'kcal';
  DateTime currentWeekDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadUserGoals();
    _loadStats();
  }

  Future<void> _loadStats() async {
    String date = DateFormat('yyyy-MM-dd').format(currentWeekDate);
    try {
      final result = await ApiService.getWeeklyStats(date);
      setState(() {
        data = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> loadUserGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? kcal = prefs.getDouble('kcal');
      final double? protein = prefs.getDouble('protein');
      final double? fats = prefs.getDouble('fats');
      final double? carbs = prefs.getDouble('carbs');

      if (kcal != null && protein != null && fats != null && carbs != null) {
        setState(() {
          userGoals = {
            'kcal': kcal,
            'protein': protein,
            'fats': fats,
            'carbs': carbs,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading user goals: $e');
    }
  }

  void _previousWeek() {
    setState(() {
      currentWeekDate = currentWeekDate.subtract(const Duration(days: 7));
    });
    _loadStats();
  }

  void _nextWeek() {
    final nextWeek = currentWeekDate.add(const Duration(days: 7));
    if (nextWeek.isAfter(DateTime.now())) return;

    setState(() {
      currentWeekDate = nextWeek;
    });
    _loadStats();
  }

  String _formatWeekLabel() {
    final startOfWeek = currentWeekDate.subtract(
      Duration(days: currentWeekDate.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final formatter = DateFormat('dd MMM');
    return '${formatter.format(startOfWeek)} - ${formatter.format(endOfWeek)}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final daily = data?['daily'] ?? [];
    final macrosPercent = data?['macros_percent'] ?? {};

    // 🔹 Konwersja dynamic -> double bezpiecznie
    final List<double> values =
        daily.map<double>((d) {
          final dynamic val = d[selectedMetric];
          if (val is num) return val.toDouble();
          return 0.0;
        }).toList();

    values.add(userGoals[selectedMetric] ?? 0);

    final double maxValue =
        values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionCard(
              title: 'Week',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousWeek,
                  ),
                  Text(
                    _formatWeekLabel(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color:
                          currentWeekDate
                                  .add(const Duration(days: 7))
                                  .isAfter(DateTime.now())
                              ? Colors.grey
                              : Colors.black,
                    ),
                    onPressed:
                        currentWeekDate
                                .add(const Duration(days: 7))
                                .isAfter(DateTime.now())
                            ? null
                            : _nextWeek,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _sectionCard(
              title: 'Metric',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    ['kcal', 'protein', 'fats', 'carbs'].map((metric) {
                      final bool isSelected = selectedMetric == metric;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isSelected ? Colors.indigo : Colors.grey[200],
                              foregroundColor:
                                  isSelected ? Colors.white : Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed:
                                () => setState(() => selectedMetric = metric),
                            child: Text(
                              metric.toUpperCase(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            _sectionCard(
              title: 'Weekly overview',
              subtitle:
                  selectedMetric == 'kcal'
                      ? 'Calories per day'
                      : 'Grams per day',
              child: SizedBox(
                height: 260,
                child: BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    maxY: (maxValue * 1.2).ceilToDouble(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(
                          selectedMetric == 'kcal' ? 'kcal' : 'g',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        axisNameSize: 28,
                        sideTitles: const SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                days[value.toInt() % 7],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: userGoals[selectedMetric] ?? 0,
                          color: Colors.redAccent,
                          strokeWidth: 2,
                          dashArray: [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            labelResolver:
                                (_) =>
                                    'Goal: ${userGoals[selectedMetric] ?? 0}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    barGroups: List.generate(daily.length, (i) {
                      final entry = daily[i];
                      double value = 0;
                      final dynamic v = entry[selectedMetric];
                      if (v is num) value = v.toDouble();
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: value,
                            color:
                                value > ((userGoals[selectedMetric] ?? 0) * 1.1)
                                    ? Colors.redAccent
                                    : Colors.green,
                            borderRadius: BorderRadius.circular(6),
                            width: 18,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Macro distribution',
              subtitle: 'Percentage split',
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          _pie(
                            'Protein',
                            macrosPercent['protein_pct'],
                            Colors.green,
                          ),
                          _pie('Fat', macrosPercent['fat_pct'], Colors.purple),
                          _pie('Carbs', macrosPercent['carb_pct'], Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _Legend(color: Colors.green, label: 'Protein'),
                      _Legend(color: Colors.purple, label: 'Fat'),
                      _Legend(color: Colors.blue, label: 'Carbs'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- UI HELPERS ----------

Widget _sectionCard({required String title, String? subtitle, Widget? child}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
            ),
          if (child != null) ...[const SizedBox(height: 10), child],
        ],
      ),
    ),
  );
}

PieChartSectionData _pie(String label, dynamic value, Color color) {
  double v = 0;
  if (value is num) v = value.toDouble();
  return PieChartSectionData(
    value: v,
    color: color,
    title: '${v.toStringAsFixed(1)}%',
    titleStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    radius: 70,
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
