import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _selectedRange = 'Day';
  final List<String> _ranges = ['Day', 'Week', 'Month'];

  final double _dailyGoal = 2000;
  final List<double> _weekCalories = [1800, 2100, 1900, 2000, 1700, 2200, 1950];
  final Map<String, double> _macros = {'Protein': 80, 'Fat': 65, 'Carbs': 250};

  @override
  Widget build(BuildContext context) {
    final avgCalories =
        _weekCalories.reduce((a, b) => a + b) / _weekCalories.length;
    final progress = (avgCalories / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.amber[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Time Range:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                DropdownButton<String>(
                  value: _selectedRange,
                  items:
                      _ranges.map((range) {
                        return DropdownMenuItem(
                          value: range,
                          child: Text(range),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRange = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child:
                  _selectedRange == 'Day'
                      ? _buildDailyPieChart()
                      : _selectedRange == 'Week'
                      ? _buildWeeklyBarChart()
                      : _buildMonthlyTrend(),
            ),

            const SizedBox(height: 20),

            Text(
              'You consume ${avgCalories.toStringAsFixed(0)} kcal daily',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: Colors.amber[400],
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              'Achieved ${(progress * 100).toStringAsFixed(1)}% of daily goal',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPieChart() {
    final colors = [Colors.blue, Colors.red, Colors.orange];
    final labels = _macros.keys.toList();
    final values = _macros.values.toList();

    return Column(
      children: [
        const Text(
          'Macronutrients (today)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: List.generate(labels.length, (i) {
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: values[i],
                  title: '${labels[i]}',
                  radius: 70,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // 📈 Wykres słupkowy dla tygodnia
  Widget _buildWeeklyBarChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      children: [
        const Text(
          'Calories this week',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      return Text(days[index % days.length]);
                    },
                  ),
                ),
              ),
              barGroups:
                  _weekCalories.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: Colors.amber[400],
                          width: 16,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrend() {
    return const Center(
      child: Text(
        'Monthly view in preparation...',
        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
      ),
    );
  }
}
