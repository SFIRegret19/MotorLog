import 'package:flutter/material.dart';
import '../../data/datasources/db_helper.dart';
import '../../domain/entities/consumable.dart';
import '../../core/theme/app_theme.dart';
import 'add_consumable_screen.dart'; 
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

      final event = ServiceEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vehicleId: widget.vehicleId,
        date: DateTime.now().toIso8601String(),
        mileage: 0, 
        totalCost: cost,
        description: 'Замена: ${item.name}',
      );

      await DbHelper.instance.insertServiceEvent(event);

      item.currentWear = 0.0;
      await DbHelper.instance.updateConsumable(item);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} заменено! Сумма: $cost ₽'), 
            backgroundColor: AppTheme.accentPurple
          ),
        );
      }
    }
  }

  void _deleteItem(Consumable item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить деталь?'),
        content: Text('Вы уверены, что хотите удалить "${item.name}" из списка?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DbHelper.instance.deleteConsumable(item.id);
      _loadData(); 
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
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Текст по левому краю
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Заголовок и заметка в колонке
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      // --- ОТОБРАЖЕНИЕ ЗАМЕТКИ ---
                                      if (item.notes.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            item.notes,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.refresh, color: AppTheme.accentPurple),
                                      onPressed: () => _resetWear(item),
                                      tooltip: 'Заменил деталь',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _deleteItem(item),
                                      tooltip: 'Удалить деталь',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Прогресс-бар
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: item.currentWear,
                                minHeight: 10,
                                backgroundColor: AppTheme.primaryPurple.withOpacity(0.3),
                                color: item.currentWear > 0.8 ? Colors.red : AppTheme.accentPurple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Техническая информация
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ресурс: ${item.resourceLimit} км',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                                Text(
                                  'Износ: ${(item.currentWear * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.bold,
                                    color: item.currentWear > 0.8 ? Colors.red : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryPurple,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddConsumableScreen(vehicleId: widget.vehicleId),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        child: const Icon(Icons.add, color: AppTheme.accentPurple),
      ),
    );
  }
}