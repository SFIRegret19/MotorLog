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
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();

  // Наша локальная база марок и моделей (Мок-справочник)
  // В будущем можно грузить этот список из API или JSON-файла
  final Map<String, List<String>> _carDatabase = {
    'Toyota':['Camry', 'Corolla', 'RAV4', 'Land Cruiser'],
    'BMW':['3 Series', '5 Series', 'X5', 'X6'],
    'Mercedes-Benz':['C-Class', 'E-Class', 'GLC', 'GLE'],
    'Kia': ['Rio', 'Sportage', 'Optima', 'Sorento'],
    'Lada': ['Vesta', 'Granta', 'Niva'],
    'Cadillac': ['Escalade', 'XT5', 'CT6'],
  };

  String? _selectedBrand;
  String? _selectedModel;

  void _saveVehicle() async {
    if (_selectedBrand == null || _selectedModel == null || _yearController.text.isEmpty || _mileageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    var uuid = const Uuid(); 
    final newVehicle = Vehicle(
      id: uuid.v4(),
      brand: _selectedBrand!,
      model: _selectedModel!,
      year: int.parse(_yearController.text),
      vin: "Не указан",
      currentMileage: int.parse(_mileageController.text),
    );

    await DbHelper.instance.insertVehicle(newVehicle);
    await DbHelper.instance.initDefaultConsumables(newVehicle.id!);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    // Получаем список моделей для выбранной марки, если марка не выбрана - список пуст
    List<String> availableModels = _selectedBrand != null ? _carDatabase[_selectedBrand]! :[];

    return Scaffold(
      appBar: AppBar(title: const Text('Добавить автомобиль')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            // ВЫПАДАЮЩИЙ СПИСОК МАРОК
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Марка автомобиля'),
              value: _selectedBrand,
              items: _carDatabase.keys.map((String brand) {
                return DropdownMenuItem<String>(value: brand, child: Text(brand));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedBrand = newValue;
                  _selectedModel = null; // Сбрасываем модель при смене марки
                });
              },
            ),
            const SizedBox(height: 16),

            // ВЫПАДАЮЩИЙ СПИСОК МОДЕЛЕЙ (зависит от марки)
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Модель автомобиля'),
              value: _selectedModel,
              isExpanded: true,
              // Если марка не выбрана, блокируем список моделей
              items: availableModels.map((String model) {
                return DropdownMenuItem<String>(value: model, child: Text(model));
              }).toList(),
              onChanged: availableModels.isEmpty ? null : (newValue) {
                setState(() {
                  _selectedModel = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

            _buildTextField(_yearController, 'Год выпуска', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(_mileageController, 'Текущий пробег (км)', keyboardType: TextInputType.number),
            
            const Spacer(),
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