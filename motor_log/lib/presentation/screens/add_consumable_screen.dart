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
  bool _isUsed = false; // Состояние Б/У
  final _customNameController = TextEditingController();
  final _limitController = TextEditingController();
  final _notesController = TextEditingController();
  final _partMileageController = TextEditingController(text: '0');

  void _saveConsumable() async {
    final partName = _selectedPart == 'Свой вариант...' ? _customNameController.text : _selectedPart;

    // ЗАЩИТА ОТ "БУЛКИ ХЛЕБА": Название должно быть длиннее 3 символов
    if (partName == null || partName.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректное название детали (минимум 3 символа)')),
      );
      return;
    }

    if (_limitController.text.isEmpty) return;

    final int limit = int.parse(_limitController.text);
    final int partMileage = int.tryParse(_partMileageController.text) ?? 0;

    // РАСЧЕТ НАЧАЛЬНОГО ИЗНОСА ДЛЯ Б/У:
    double startWear = (partMileage / limit).clamp(0.0, 1.0);

    final newItem = Consumable(
      id: const Uuid().v4(),
      vehicleId: widget.vehicleId,
      name: partName,
      resourceLimit: limit,
      currentWear: startWear,
      notes: _notesController.text,
      initialMileage: partMileage,
    );

    await DbHelper.instance.insertConsumable(newItem);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новая деталь')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Выберите деталь'),
              value: _selectedPart,
              items: _partsCatalog.keys.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() {
                _selectedPart = v;
                if (v != 'Свой вариант...') _limitController.text = _partsCatalog[v]!;
              }),
            ),
            if (_selectedPart == 'Свой вариант...') ...[
              const SizedBox(height: 16),
              TextField(controller: _customNameController, decoration: _inputDecoration('Название детали')),
            ],
            const SizedBox(height: 16),
            TextField(controller: _limitController, keyboardType: TextInputType.number, decoration: _inputDecoration('Ресурс (км)')),
            const SizedBox(height: 16),
            
            // БЛОК Б/У ЗАПЧАСТИ
            SwitchListTile(
              title: const Text('Это Б/У или контрактная деталь'),
              subtitle: const Text('Укажите пробег детали на момент покупки'),
              value: _isUsed,
              activeColor: AppTheme.accentPurple,
              onChanged: (v) => setState(() => _isUsed = v),
            ),
            if (_isUsed)
              TextField(
                controller: _partMileageController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Текущий пробег запчасти (км)'),
              ),
            
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: _inputDecoration('Заметки (бренд, артикул...)'),
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple, minimumSize: const Size(double.infinity, 55)),
              onPressed: _saveConsumable,
              child: const Text('Добавить в список', style: TextStyle(color: Colors.white)),
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