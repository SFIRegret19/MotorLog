import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/vehicle.dart';
import '../../data/datasources/db_helper.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  // Контроллеры для полей ввода
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();

  void _saveVehicle() async {
    if (_brandController.text.isEmpty || _modelController.text.isEmpty) return;

    var uuid = const Uuid();

    final newVehicle = Vehicle(
      id: uuid
          .v4(), // Создает уникальный ID типа '6c84fb90-12c4-11e1-840d-7b25c5ee775a'
      brand: _brandController.text,
      model: _modelController.text,
      year: int.parse(_yearController.text),
      vin: "Не указан",
      currentMileage: int.parse(_mileageController.text),
    );

    await DbHelper.instance.insertVehicle(newVehicle);
    // ОБЯЗАТЕЛЬНО ЖДЕМ, пока создадутся расходники:
    await DbHelper.instance.initDefaultConsumables(newVehicle.id!);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить автомобиль')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTextField(_brandController, 'Марка (например, BMW)'),
            const SizedBox(height: 12),
            _buildTextField(_modelController, 'Модель (например, X5)'),
            const SizedBox(height: 12),
            _buildTextField(
              _yearController,
              'Год выпуска',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _mileageController,
              'Текущий пробег',
              keyboardType: TextInputType.number,
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: _saveVehicle,
              child: const Text(
                'Сохранить в гараж',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.primaryPurple.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
