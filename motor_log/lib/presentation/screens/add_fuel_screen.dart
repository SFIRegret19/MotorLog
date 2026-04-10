import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/fuel_log.dart';
import '../../data/datasources/db_helper.dart';

class AddFuelScreen extends StatefulWidget {
  final String vehicleId;
  final int currentMileage;

  const AddFuelScreen({super.key, required this.vehicleId, required this.currentMileage});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  late TextEditingController _odometerController;
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  
  double _totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    // Подставляем текущий пробег авто по умолчанию
    _odometerController = TextEditingController(text: widget.currentMileage.toString());
    
    // Слушатели для авто-расчета итоговой стоимости
    _litersController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final liters = double.tryParse(_litersController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    setState(() {
      _totalCost = liters * price;
    });
  }

  void _saveFuelLog() async {
    // 1. Проверка на пустые поля
    if (_litersController.text.isEmpty || _priceController.text.isEmpty || _odometerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    final int inputOdometer = int.parse(_odometerController.text);

    // --- 2. ВАЛИДАЦИЯ ПРОБЕГА (ТО, ЧТО ТЫ ПРОСИЛ) ---
    if (inputOdometer < widget.currentMileage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка! Пробег не может быть меньше текущего (${widget.currentMileage} км).'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
      return; // Прерываем сохранение
    }

    // 3. Если всё ок, сохраняем в базу
    final log = FuelLog(
      id: const Uuid().v4(),
      vehicleId: widget.vehicleId,
      date: DateTime.now(),
      odometer: inputOdometer,
      liters: double.parse(_litersController.text),
      pricePerLiter: double.parse(_priceController.text),
      totalCost: _totalCost,
    );

    await DbHelper.instance.insertFuelLog(log);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Заправка добавлена, данные авто обновлены!'),
        backgroundColor: AppTheme.accentPurple,
      ),
    );
    Navigator.pop(context, true); // Возвращаемся в гараж
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новая заправка')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            _buildTextField(_odometerController, 'Пробег на одометре (км)'),
            const SizedBox(height: 16),
            Row(
              children:[
                Expanded(child: _buildTextField(_litersController, 'Залито (Литров)')),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_priceController, 'Цена за литр (₽)')),
              ],
            ),
            const SizedBox(height: 24),
            
            // Красивый блок с итоговой суммой
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.accentPurple, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  const Text('Итого к оплате:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${_totalCost.toStringAsFixed(2)} ₽', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.accentPurple)
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: _saveFuelLog,
              child: const Text('Сохранить', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.primaryPurple.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}