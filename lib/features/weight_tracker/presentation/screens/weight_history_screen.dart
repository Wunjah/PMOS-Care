import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/weight_provider.dart';

class WeightHistoryScreen extends ConsumerWidget {
  const WeightHistoryScreen({super.key});

  void _showAddWeightDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final weightController = TextEditingController();
    final waistController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Log Weight & Waist',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Date:', style: TextStyle(fontWeight: FontWeight.w600)),
                          TextButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 72.5',
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Weight is required';
                          final numVal = double.tryParse(val);
                          if (numVal == null || numVal <= 0) return 'Enter a valid positive weight';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: waistController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Waist Size (inches)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 32.0',
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Waist size is required';
                          final numVal = double.tryParse(val);
                          if (numVal == null || numVal <= 0) return 'Enter a valid waist size';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final w = double.parse(weightController.text);
                      final ws = double.parse(waistController.text);
                      await ref.read(weightStateNotifierProvider.notifier).addWeight(w, ws, selectedDate);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Weight logged successfully!'),
                            backgroundColor: AppTheme.glycemicLow,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weightStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Weight & Waist Logger',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(weightStateNotifierProvider.notifier).loadWeights(),
          ),
        ],
      ),
      body: state.isLoading && state.weights.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Quick Summary Card
                if (state.weights.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: AppTheme.primaryLight,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Current Weight',
                                  style: TextStyle(fontFamily: 'Inter', color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.weights.first.weightKg} kg',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryWellness,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 40, color: Colors.grey.withAlpha(100)),
                            Column(
                              children: [
                                const Text(
                                  'Waist Size',
                                  style: TextStyle(fontFamily: 'Inter', color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.weights.first.waistSizeInches} in',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryWellness,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                // Log history list
                Expanded(
                  child: state.weights.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.scale_outlined,
                                  size: 64,
                                  color: AppTheme.primaryWellness.withAlpha(150),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No weight logged yet',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Track weight and waist changes to evaluate metabolic progress and monitor PCOS outcomes.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddWeightDialog(context, ref),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Log First Metric'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(200, 48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: state.weights.length,
                          itemBuilder: (context, index) {
                            final log = state.weights[index];
                            final dateStr =
                                '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.withAlpha(50)),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.scale, color: AppTheme.primaryWellness),
                                title: Text(
                                  dateStr,
                                  style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Weight: ${log.weightKg} kg | Waist: ${log.waistSizeInches} in',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.glycemicHigh),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Log'),
                                        content: const Text('Are you sure you want to delete this log?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              ref.read(weightStateNotifierProvider.notifier).removeWeight(log.id);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: AppTheme.glycemicHigh)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryWellness,
        foregroundColor: Colors.white,
        onPressed: () => _showAddWeightDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
