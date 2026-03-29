import 'package:flutter/material.dart';
import '../../data/datasources/db_helper.dart';
import '../../domain/entities/consumable.dart';
import '../../core/theme/app_theme.dart';

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
    item.currentWear = 0.0;
    await DbHelper.instance.updateConsumable(item);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} заменено!'),
          backgroundColor: AppTheme.accentPurple,
        ),
      );
    }
  }

  // МЕТОД УДАЛЕНИЯ РАСХОДНИКА (Новое)
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
                            // ГРУППА КНОПОК: Обновить и Удалить
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
    );
  }
}