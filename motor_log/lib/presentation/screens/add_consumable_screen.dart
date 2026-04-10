import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/consumable.dart';
import '../../data/datasources/db_helper.dart';

class AddConsumableScreen extends StatefulWidget {
  final String vehicleId;
  const AddConsumableScreen({super.key, required this.vehicleId});

  @override
  State<AddConsumableScreen> createState() => _AddConsumableScreenState();
}

class _AddConsumableScreenState extends State<AddConsumableScreen> {
  // Наш "Справочник" деталей и их стандартный ресурс (в км)
  final Map<String, String> _partsCatalog = {
    'Свечи зажигания': '60000',
    'Ремень ГРМ': '90000',
    'Антифриз': '60000',
    'Тормозная жидкость': '40000',
    'Масло трансмиссионное': '60000',
    'Салонный фильтр': '15000',
    'Топливный фильтр': '30000',
    'Свой вариант...': '',
  };

  String? _selectedPart;
  final _customNameController = TextEditingController();
  final _limitController = TextEditingController();

  void _saveConsumable() async {
    // Определяем финальное название детали
    final partName = _selectedPart == 'Свой вариант...' 
        ? _customNameController.text 
        : _selectedPart;

    if (partName == null || partName.isEmpty || _limitController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    final int limit = int.parse(_limitController.text);

    final newItem = Consumable(
      id: const Uuid().v4(),
      vehicleId: widget.vehicleId,
      name: partName,
      resourceLimit: limit,
      currentWear: 0.0, // Новая деталь - износ 0%
    );

    await DbHelper.instance.insertConsumable(newItem);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$partName добавлено в список ТО!'), backgroundColor: AppTheme.accentPurple),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить деталь')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Выберите деталь из справочника'),
              value: _selectedPart,
              items: _partsCatalog.keys.map((String part) {
                return DropdownMenuItem<String>(value: part, child: Text(part));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedPart = newValue;
                  // Если выбрали не "свой вариант", подставляем ресурс автоматически
                  if (newValue != null && newValue != 'Свой вариант...') {
                    _limitController.text = _partsCatalog[newValue]!;
                  } else {
                    _limitController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Показываем поле ввода названия только если выбрали "Свой вариант..."
            if (_selectedPart == 'Свой вариант...') ...[
              TextField(
                controller: _customNameController,
                decoration: _inputDecoration('Название вашей детали'),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Ресурс до замены (км)'),
            ),
            
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: _saveConsumable,
              child: const Text('Сохранить деталь', style: TextStyle(color: Colors.white, fontSize: 16)),
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
}