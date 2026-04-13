import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для форматирования ввода
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
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _vinController = TextEditingController(); // НОВОЕ ПОЛЕ ДЛЯ VIN

  final Map<String, List<String>> _carDatabase = {
    'Toyota':['Camry', 'Corolla', 'RAV4', 'Land Cruiser'],
    'BMW':['3 Series', '5 Series', 'X5', 'X6'],
    'Mercedes-Benz':['C-Class', 'E-Class', 'GLC', 'GLE'],
    'Kia':['Rio', 'Sportage', 'Optima', 'Sorento'],
    'Lada': ['Vesta', 'Granta', 'Niva'],
    'Cadillac': ['Escalade', 'XT5', 'CT6'],
  };

  String? _selectedBrand;
  String? _selectedModel;

  // --- ЛОГИКА ВАЛИДАЦИИ VIN ---
  bool _isValidVin(String vin) {
    // Регулярное выражение: ровно 17 символов, буквы A-Z и цифры 0-9. 
    // Буквы I, O, Q - исключены.
    final RegExp vinRegex = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');
    return vinRegex.hasMatch(vin);
  }

  void _saveVehicle() async {
    // 1. Проверка на пустоту
    if (_selectedBrand == null || _selectedModel == null || 
        _yearController.text.isEmpty || _mileageController.text.isEmpty || _vinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    // 2. ВАЛИДАЦИЯ VIN НОМЕРА
    final vin = _vinController.text.toUpperCase();
    if (!_isValidVin(vin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неверный VIN! Должно быть 17 символов (без букв I, O, Q)'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    var uuid = const Uuid(); 
    final newVehicle = Vehicle(
      id: uuid.v4(),
      brand: _selectedBrand!,
      model: _selectedModel!,
      year: int.parse(_yearController.text),
      vin: vin, // Передаем валидный VIN
      currentMileage: int.parse(_mileageController.text),
      isSynced: 0, // Для синхронизации
    );

    await DbHelper.instance.insertVehicle(newVehicle);
    await DbHelper.instance.initDefaultConsumables(newVehicle.id!);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableModels = _selectedBrand != null ? _carDatabase[_selectedBrand]! :[];

    return Scaffold(
      appBar: AppBar(title: const Text('Добавить автомобиль')),
      body: SingleChildScrollView( // Чтобы клавиатура не перекрывала поля
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Марка автомобиля'),
              value: _selectedBrand,
              items: _carDatabase.keys.map((String brand) {
                return DropdownMenuItem<String>(value: brand, child: Text(brand));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedBrand = newValue;
                  _selectedModel = null;
                });
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Модель автомобиля'),
              value: _selectedModel,
              isExpanded: true,
              items: availableModels.map((String model) {
                return DropdownMenuItem<String>(value: model, child: Text(model));
              }).toList(),
              onChanged: availableModels.isEmpty ? null : (newValue) {
                setState(() => _selectedModel = newValue);
              },
            ),
            const SizedBox(height: 16),

            Row(
              children:[
                Expanded(child: _buildTextField(_yearController, 'Год', keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_mileageController, 'Пробег (км)', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),

            // ПОЛЕ ДЛЯ VIN НОМЕРА
            TextField(
              controller: _vinController,
              maxLength: 17, // Ограничение ввода до 17 символов
              textCapitalization: TextCapitalization.characters, // Клавиатура сразу пишет заглавными
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), // Запрещаем вводить пробелы и спецсимволы
              ],
              decoration: _inputDecoration('VIN номер (17 символов)').copyWith(
                counterText: '', // Убираем счетчик 0/17 снизу
              ),
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: _saveVehicle,
              child: const Text('Сохранить в гараж', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.primaryPurple.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label),
    );
  }
}