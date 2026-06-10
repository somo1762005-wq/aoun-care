import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/localization.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/medicine.dart';
import '../../../../logic/medicine/medicine_cubit.dart';
import '../../../../logic/language/language_cubit.dart';

class MedicationTab extends StatefulWidget {
  const MedicationTab({super.key});

  @override
  State<MedicationTab> createState() => _MedicationTabState();
}

class _MedicationTabState extends State<MedicationTab> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final List<String> _doseTimes = [];
  final _timeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _showAddEditSheet(BuildContext context, Medicine? medicine) {
    if (medicine != null) {
      _nameController.text = medicine.name;
      _qtyController.text = medicine.remainingQuantity.toString();
      _doseTimes.clear();
      _doseTimes.addAll(medicine.dosagesPerDay);
    } else {
      _nameController.clear();
      _qtyController.clear();
      _doseTimes.clear();
      // default starting dose time
      _doseTimes.add('08:00');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final langCode = context.watch<LanguageCubit>().state;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalization.translate(
                        medicine != null ? 'edit_medicine' : 'add_medicine',
                        langCode,
                      ),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Name Field
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalization.translate('medicine_name', langCode),
                        prefixIcon: const Icon(Icons.medication_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Remaining Quantity
                    TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppLocalization.translate('initial_stock', langCode),
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Dose timings listing
                    Text(
                      AppLocalization.translate('dose_times', langCode),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _doseTimes.map((time) {
                        return Chip(
                          label: Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
                          onDeleted: () {
                            setModalState(() {
                              _doseTimes.remove(time);
                            });
                          },
                          deleteIconColor: AppColors.error,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    
                    // Add Dose time input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _timeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'HH:MM (e.g. 14:30)',
                              prefixIcon: const Icon(Icons.alarm_add_rounded),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today_rounded),
                                onPressed: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                    _timeController.text = formatted;
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: () {
                            if (_timeController.text.isNotEmpty && !_doseTimes.contains(_timeController.text)) {
                              setModalState(() {
                                _doseTimes.add(_timeController.text);
                                _timeController.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Actions buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(AppLocalization.translate('cancel', langCode)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_nameController.text.isEmpty || _qtyController.text.isEmpty || _doseTimes.isEmpty) {
                                return;
                              }
                              
                              final qty = int.tryParse(_qtyController.text) ?? 0;
                              final med = Medicine(
                                id: medicine?.id ?? const Uuid().v4(),
                                name: _nameController.text,
                                dosagesPerDay: List<String>.from(_doseTimes),
                                remainingQuantity: qty,
                                initialQuantity: medicine?.initialQuantity ?? qty,
                              );

                              if (medicine != null) {
                                context.read<MedicineCubit>().editMed(med);
                              } else {
                                context.read<MedicineCubit>().addMed(med);
                              }
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              AppLocalization.translate('save', langCode),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (medicine != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          context.read<MedicineCubit>().deleteMed(medicine.id);
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                        label: Text(
                          AppLocalization.translate('delete', langCode),
                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<MedicineCubit, MedicineState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEditSheet(context, null),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalization.translate('medication_list', langCode),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: state.medicines.isEmpty
                      ? Center(
                          child: Text(
                            langCode == 'ar' ? 'لا توجد أدوية مضافة حالياً' : 'No medicines added yet',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black45),
                          ),
                        )
                      : ListView.builder(
                          itemCount: state.medicines.length,
                          itemBuilder: (context, index) {
                            final medicine = state.medicines[index];
                            // Warning check: Stock <= threshold (3)
                            final isLowStock = medicine.remainingQuantity <= medicine.thresholdQuantity;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isLowStock 
                                      ? AppColors.error.withValues(alpha: 0.4) 
                                      : (isDark ? Colors.white10 : Colors.black12),
                                  width: isLowStock ? 2 : 1,
                                ),
                              ),
                              color: isDark ? AppColors.cardDark : Colors.white,
                              child: InkWell(
                                onTap: () => _showAddEditSheet(context, medicine),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Name & Stock
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              medicine.name,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : AppColors.darkNavy,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: isLowStock 
                                                  ? AppColors.error.withValues(alpha: 0.12)
                                                  : AppColors.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            child: Text(
                                              AppLocalization.translate(
                                                'remaining_doses',
                                                langCode,
                                                arguments: {'count': medicine.remainingQuantity.toString()},
                                              ),
                                              style: TextStyle(
                                                color: isLowStock ? AppColors.error : AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Dose Schedules
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule_rounded, size: 18, color: Colors.blueGrey),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              medicine.dosagesPerDay.join('  |  '),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blueGrey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Stock low threshold warning card
                                      if (isLowStock) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  AppLocalization.translate(
                                                    'stock_warning',
                                                    langCode,
                                                    arguments: {'name': medicine.name},
                                                  ),
                                                  style: const TextStyle(
                                                    color: AppColors.error,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
