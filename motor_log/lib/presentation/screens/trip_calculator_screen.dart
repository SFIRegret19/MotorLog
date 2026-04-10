import 'package:flutter/material.dart';
import '../../data/datasources/db_helper.dart';
import '../../core/theme/app_theme.dart';

class TripCalculatorScreen extends StatefulWidget {
  final String vehicleId;
  const TripCalculatorScreen({super.key, required this.vehicleId});

  @override
  State<TripCalculatorScreen> createState() => _TripCalculatorScreenState();
}

class _TripCalculatorScreenState extends State<TripCalculatorScreen> {
  final _distanceController = TextEditingController();
  final _priceController = TextEditingController(text: "55"); // Средняя цена по умолчанию
  
  double _avgConsumption = 10.0; // Значение по умолчанию, если нет данных в базе
  double _neededFuel = 0;
  double _neededMoney = 0;

  @override
  void initState() {
    super.initState();
    _loadAvgConsumption();
  }

  void _loadAvgConsumption() async {
    final logs = await DbHelper.instance.getFuelLogs(widget.vehicleId);
    if (logs.length >= 2) {
      logs.sort((a, b) => a.odometer.compareTo(b.odometer));
      int distance = logs.last.odometer - logs.first.odometer;
      double totalLiters = logs.fold<double>(0.0, (sum, item) => sum + item.liters) - logs.first.liters;
      if (distance > 0) {
        setState(() {
          _avgConsumption = (totalLiters / distance) * 100;
        });
      }
    }
  }

  void _calculate() {
    final distance = double.tryParse(_distanceController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    setState(() {
      _neededFuel = (distance / 100) * _avgConsumption;
      _neededMoney = _neededFuel * price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор поездки')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ваш средний расход: ${_avgConsumption.toStringAsFixed(1)} л/100 км', 
                 style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: _distanceController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Расстояние поездки (км)'),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Цена за литр (₽)'),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 30),
            
            // ПАНЕЛЬ РЕЗУЛЬТАТОВ
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentPurple),
              ),
              child: Column(
                children: [
                  _resultRow('Потребуется топлива:', '${_neededFuel.toStringAsFixed(1)} л'),
                  const Divider(),
                  _resultRow('Примерная стоимость:', '${_neededMoney.toStringAsFixed(0)} ₽'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentPurple)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}