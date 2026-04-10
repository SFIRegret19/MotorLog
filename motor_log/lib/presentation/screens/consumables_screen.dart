import 'package:flutter/material.dart';
import '../../data/datasources/db_helper.dart';
import '../../domain/entities/consumable.dart';
import '../../core/theme/app_theme.dart';
import 'add_consumable_screen.dart'; // Импорт экрана добавления
import '../../domain/entities/service_event.dart';

class ConsumablesScreen extends StatefulWidget {
  final String vehicleId;
  const ConsumablesScreen({super.key, required this.vehicleId});

  @override
  State<ConsumablesScreen> createState() => _ConsumablesScreenState();
}

class _ConsumablesScreenState extends State<ConsumablesScreen> {
  List<Consumable> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final data = await DbHelper.instance.getConsumables(widget.vehicleId);
    if (mounted) {
      setState(() {
        _items = data;
        _isLoading = false;
      });
    }
  }

  void _resetWear(Consumable item) async {
    final priceController = TextEditingController();

    // 1. Спрашиваем цену обслуживания
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Замена: ${item.name}'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Стоимость (₽)',
            hintText: 'Введите сумму за запчасть и работу',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ОК')),
        ],
      ),
    );

    if (confirmed == true) {
      final cost = double.tryParse(priceController.text) ?? 0.0;

      // 2. Создаем сервисное событие (для статистики)
      final event = ServiceEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vehicleId: widget.vehicleId,
        date: DateTime.now().toIso8601String(),
        mileage: 0, // В идеале тут передать текущий пробег авто
        totalCost: cost,
        description: 'Замена: ${item.name}',
      );

      await DbHelper.instance.insertServiceEvent(event);

      // 3. Обнуляем износ
      item.currentWear = 0.0;
      await DbHelper.instance.updateConsumable(item);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} заменено! Сумма: $cost ₽'), backgroundColor: AppTheme.accentPurple),
        );
      }
    }
  }

  void _deleteItem(Consumable item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить деталь?'),
        content: Text(
          'Вы уверены, что хотите удалить "${item.name}" из списка?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DbHelper.instance.deleteConsumable(item.id);
      _loadData(); // Обновляем список
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Состояние расходников')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Список пуст.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.refresh,
                                        color: AppTheme.accentPurple,
                                      ),
                                      onPressed: () => _resetWear(item),
                                      tooltip: 'Заменил деталь',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => _deleteItem(item),
                                      tooltip: 'Удалить деталь',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: item.currentWear,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                              color: item.currentWear > 0.8
                                  ? Colors.red
                                  : AppTheme.accentPurple,
                            ),
                            const SizedBox(height: 5),
                            Text('Износ: ${(item.currentWear * 100).toInt()}%'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      // --- НОВОЕ: КНОПКА ДОБАВЛЕНИЯ РАСХОДНИКА ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryPurple,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddConsumableScreen(vehicleId: widget.vehicleId),
            ),
          );
          // Если на экране добавления нажали "Сохранить", обновляем список здесь
          if (result == true) {
            _loadData();
          }
        },
        child: const Icon(Icons.add, color: AppTheme.accentPurple),
      ),
    );
  }
}