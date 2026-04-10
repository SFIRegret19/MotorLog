import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Добавь в pubspec.yaml: intl: ^0.19.0
import '../../data/datasources/db_helper.dart';
import '../../domain/entities/fuel_log.dart';
import '../../domain/entities/service_event.dart';
import '../../core/theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  final String vehicleId;
  const StatisticsScreen({super.key, required this.vehicleId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  double _totalFuel = 0;
  double _totalService = 0;
  Map<String, double> _monthlyExpenses = {}; // Месяц -> Сумма
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  void _calculateStats() async {
    final fuelLogs = await DbHelper.instance.getFuelLogs(widget.vehicleId);
    final serviceEvents = await DbHelper.instance.getServiceEvents(
      widget.vehicleId,
    );

    double fuelSum = 0;
    double serviceSum = 0;
    Map<String, double> monthly = {};

    for (var log in fuelLogs) {
      fuelSum += log.totalCost;
      String monthKey = DateFormat('MMM yyyy').format(log.date);
      monthly[monthKey] = (monthly[monthKey] ?? 0) + log.totalCost;
    }

    for (var event in serviceEvents) {
      serviceSum += event.totalCost;
      DateTime date = DateTime.parse(event.date);
      String monthKey = DateFormat('MMM yyyy').format(date);
      monthly[monthKey] = (monthly[monthKey] ?? 0) + event.totalCost;
    }

    setState(() {
      _totalFuel = fuelSum;
      _totalService = serviceSum;
      _monthlyExpenses = monthly;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Финансовый отчет')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ОБЩИЙ ИТОГ
                _buildMainBalance(),
                const SizedBox(height: 20),

                const Text(
                  'Расходы по месяцам',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // ГРАФИК (Упрощенный в виде списка баров)
                ..._monthlyExpenses.entries
                    .map((e) => _buildMonthRow(e.key, e.value))
                    .toList(),

                const SizedBox(height: 20),
                const Text(
                  'Разделение затрат',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                _buildCategoryTile(
                  'Топливо',
                  _totalFuel,
                  Icons.local_gas_station,
                  Colors.blue,
                ),
                _buildCategoryTile(
                  'Сервис и ТО',
                  _totalService,
                  Icons.build,
                  Colors.orange,
                ),
              ],
            ),
    );
  }

  Widget _buildMainBalance() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.accentPurple,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'Всего потрачено на авто',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_totalFuel + _totalService).toStringAsFixed(0)} ₽',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthRow(String month, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(month)),
          Expanded(
            child: LinearProgressIndicator(
              value: amount / (_totalFuel + _totalService + 1),
              backgroundColor: AppTheme.primaryPurple.withOpacity(0.3),
              color: AppTheme.accentPurple,
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Text('${amount.toInt()} ₽'),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          '${amount.toStringAsFixed(0)} ₽',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
