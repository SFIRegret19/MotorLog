import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  List<FuelLog> _fuelLogs = [];
  List<ServiceEvent> _serviceLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  void _loadAllStats() async {
    final fuel = await DbHelper.instance.getFuelLogs(widget.vehicleId);
    final service = await DbHelper.instance.getServiceEvents(widget.vehicleId);

    double fuelSum = fuel.fold(0, (sum, item) => sum + item.totalCost);
    double serviceSum = service.fold(0, (sum, item) => sum + item.totalCost);

    setState(() {
      _fuelLogs = fuel;
      _serviceLogs = service;
      _totalFuel = fuelSum;
      _totalService = serviceSum;
      _isLoading = false;
    });
  }

  // Метод для открытия модального окна с деталями
  void _showDetails(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика расходов')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 24),
              const Text('Категории (нажмите для деталей)', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 12),
              
              // КАРТОЧКА ТОПЛИВА
              _buildCategoryTile(
                title: 'Топливо',
                amount: _totalFuel,
                icon: Icons.local_gas_station,
                color: Colors.blueAccent,
                onTap: () => _showDetails('История заправок', _buildFuelList()),
              ),
              
              const SizedBox(height: 12),
              
              // КАРТОЧКА СЕРВИСА
              _buildCategoryTile(
                title: 'Сервис и ТО',
                amount: _totalService,
                icon: Icons.build_circle,
                color: Colors.orangeAccent,
                onTap: () => _showDetails('История обслуживания', _buildServiceList()),
              ),
            ],
          ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.accentPurple, Color(0xFF8E7AB5)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppTheme.accentPurple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Text('Общие затраты', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text('${(_totalFuel + _totalService).toStringAsFixed(0)} ₽', 
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCategoryTile({required String title, required double amount, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryPurple),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
            Text('${amount.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // СПИСОК ЗАПРАВОК (Тот самый дизайн, который понравился)
  Widget _buildFuelList() {
    return _fuelLogs.isEmpty 
      ? const Center(child: Text('Заправок пока нет'))
      : ListView.builder(
          itemCount: _fuelLogs.length,
          itemBuilder: (context, index) {
            final log = _fuelLogs[index];
            return ListTile(
              leading: const CircleAvatar(backgroundColor: AppTheme.primaryPurple, child: Icon(Icons.ev_station, color: AppTheme.accentPurple)),
              title: Text('${log.liters} л  •  ${log.totalCost.toStringAsFixed(0)} ₽'),
              subtitle: Text('${log.odometer} км • ${DateFormat('dd.MM.yyyy').format(log.date)}'),
            );
          },
        );
  }

// СПИСОК СЕРВИСА
  Widget _buildServiceList() {
    return _serviceLogs.isEmpty 
      ? const Center(child: Text('Сервисных записей нет'))
      : ListView.builder(
          itemCount: _serviceLogs.length,
          itemBuilder: (context, index) {
            final event = _serviceLogs[index];
            DateTime date = DateTime.parse(event.date);
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withOpacity(0.2), 
                child: const Icon(Icons.build, color: Colors.orange),
              ),
              title: Text(event.description),
              subtitle: Text(DateFormat('dd.MM.yyyy').format(date)),
              trailing: Text(
                '${event.totalCost.toStringAsFixed(0)} ₽', 
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        );
  }
}

// Добавим расширение для цвета в тему или используем:
extension on Colors { static const Color orangeOpacity = Color(0xFFFFECB3); }