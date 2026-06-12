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

  ScheduleType _scheduleType = ScheduleType.daily;
  List<int> _selectedDays = [];
  DateTime? _startDate;

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
      _scheduleType = medicine.scheduleType;
      _selectedDays = List<int>.from(medicine.selectedDays);
      _startDate = medicine.startDate;
    } else {
      _nameController.clear();
      _qtyController.clear();
      _doseTimes.clear();
      _doseTimes.add('08:00');
      _scheduleType = ScheduleType.daily;
      _selectedDays = [];
      _startDate = DateTime.now();
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalization.translate('medicine_name', langCode),
                        prefixIcon: const Icon(Icons.medication_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: langCode == 'ar' ? 'الكمية المتبقية في العلبة' : 'Remaining Quantity in Box',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Advanced Scheduling Section
                    Text(
                      langCode == 'ar' ? 'نظام الجدولة (المنبه)' : 'Scheduling System',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ScheduleType>(
                      segments: [
                        ButtonSegment(value: ScheduleType.daily, label: Text(langCode == 'ar' ? 'يومياً' : 'Daily')),
                        ButtonSegment(value: ScheduleType.specificDays, label: Text(langCode == 'ar' ? 'أيام معينة' : 'Specific Days')),
                        ButtonSegment(value: ScheduleType.alternateDays, label: Text(langCode == 'ar' ? 'يوم بعد يوم' : 'Alternate')),
                      ],
                      selected: {_scheduleType},
                      onSelectionChanged: (val) => setModalState(() => _scheduleType = val.first),
                    ),
                    const SizedBox(height: 16),

                    if (_scheduleType == ScheduleType.specificDays) ...[
                      const Text('اختر الأيام:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: List.generate(7, (index) {
                          final dayIndex = index + 1;
                          final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];
                          final isSelected = _selectedDays.contains(dayIndex);
                          return FilterChip(
                            label: Text(dayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) _selectedDays.add(dayIndex);
                                else _selectedDays.remove(dayIndex);
                              });
                            },
                          );
                        }),
                      ),
                    ],

                    const SizedBox(height: 24),
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
                          onDeleted: () => setModalState(() => _doseTimes.remove(time)),
                          deleteIconColor: AppColors.error,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _timeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'HH:MM',
                              prefixIcon: const Icon(Icons.alarm_add_rounded),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today_rounded),
                                onPressed: () async {
                                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                  if (time != null) {
                                    setModalState(() => _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(AppLocalization.translate('cancel', langCode)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_nameController.text.isEmpty || _qtyController.text.isEmpty || _doseTimes.isEmpty) return;
                              final qty = int.tryParse(_qtyController.text) ?? 0;
                              final med = Medicine(
                                id: medicine?.id ?? const Uuid().v4(),
                                name: _nameController.text,
                                dosagesPerDay: List<String>.from(_doseTimes),
                                remainingQuantity: qty,
                                initialQuantity: medicine?.initialQuantity ?? qty,
                                scheduleType: _scheduleType,
                                selectedDays: _selectedDays,
                                startDate: _startDate ?? DateTime.now(),
                              );
                              if (medicine != null) context.read<MedicineCubit>().editMed(med);
                              else context.read<MedicineCubit>().addMed(med);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: Text(AppLocalization.translate('save', langCode), style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
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
        if (state.isLoading) return const Center(child: CircularProgressIndicator());

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEditSheet(context, null),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalization.translate('medication_list', langCode),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: state.medicines.isEmpty
                      ? const Center(child: Text('لا توجد أدوية مضافة'))
                      : ListView.builder(
                    itemCount: state.medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = state.medicines[index];
                      // 3. التنبيه باللون الأحمر عند نفاذ الدواء (2 حبة أو أقل)
                      final isLowStock = medicine.remainingQuantity <= 2;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isLowStock ? Colors.red : (isDark ? Colors.white10 : Colors.black12),
                            width: isLowStock ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _showAddEditSheet(context, medicine),
                          title: Text(medicine.name, style: TextStyle(fontWeight: FontWeight.bold, color: isLowStock ? Colors.red : null)),
                          subtitle: Text(langCode == 'ar' ? 'المتبقي: ${medicine.remainingQuantity} حبة' : 'Stock: ${medicine.remainingQuantity}'),
                          trailing: isLowStock ? const Icon(Icons.warning_amber_rounded, color: Colors.red) : const Icon(Icons.edit),
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
