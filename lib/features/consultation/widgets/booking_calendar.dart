import 'package:flutter/material.dart';
import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class BookingCalendar extends StatefulWidget {
  final DateTime? initialDate;
  final bool Function(DateTime date)? isDateEnabled;
  final List<TimeOfDay> availableTimeSlots;
  final Function(DateTime selectedDate) onDateSelected;
  final Function(TimeOfDay selectedTime) onTimeSelected;

  const BookingCalendar({
    super.key,
    this.initialDate,
    this.isDateEnabled,
    this.availableTimeSlots = const [],
    required this.onDateSelected,
    required this.onTimeSelected,
  });

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void didUpdateWidget(covariant BookingCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialDate != null &&
        (widget.initialDate!.year != _selectedDate.year ||
            widget.initialDate!.month != _selectedDate.month ||
            widget.initialDate!.day != _selectedDate.day)) {
      _selectedDate = widget.initialDate!;
      _selectedTime = null;
    }

    if (_selectedTime != null) {
      final stillAvailable = widget.availableTimeSlots.any(
        (slot) =>
            slot.hour == _selectedTime!.hour &&
            slot.minute == _selectedTime!.minute,
      );
      if (!stillAvailable) {
        _selectedTime = null;
      }
    }
  }

  bool _dateEnabled(DateTime date) => widget.isDateEnabled?.call(date) ?? true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14, // Next 2 weeks
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index + 1));
              final isEnabled = _dateEnabled(date);
              final isSelected =
                  _selectedDate.day == date.day &&
                  _selectedDate.month == date.month;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: isEnabled
                      ? () {
                          setState(() {
                            _selectedDate = date;
                            _selectedTime = null;
                          });
                          widget.onDateSelected(date);
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 70,
                    decoration: BoxDecoration(
                      color: !isEnabled
                          ? Colors.grey.shade200
                          : isSelected
                              ? AppColors.primary
                              : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !isEnabled
                            ? Colors.grey.shade300
                            : isSelected
                                ? AppColors.primary
                                : AppColors.border,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date),
                          style: TextStyle(
                            color: !isEnabled
                                ? Colors.grey.shade500
                                : isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: !isEnabled
                                ? Colors.grey.shade500
                                : isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Select Time Slot',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.availableTimeSlots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'No available slots for this date. Please select another day.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.availableTimeSlots.map((time) {
              final isSelected = _selectedTime != null &&
                  _selectedTime!.hour == time.hour &&
                  _selectedTime!.minute == time.minute;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedTime = time);
                  widget.onTimeSelected(time);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    time.format(context),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
