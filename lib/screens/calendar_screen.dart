import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  final List<Map<String, dynamic>> _classes = [
    {
      'subject': 'Biology',
      'chapter': 'Chapter 2: Kingdom',
      'time': '12:00 - 12:30 pm',
      'color': const Color(0xFFE3F2FD),
      'iconColor': const Color(0xFF2196F3),
      'icon': Icons.science_outlined,
    },
    {
      'subject': 'Chemistry',
      'chapter': 'Chapter 2: Chapter 2:',
      'time': '12:40 - 01:30 pm',
      'color': const Color(0xFFE8F5E9),
      'iconColor': const Color(0xFF4CAF50),
      'icon': Icons.biotech_outlined,
    },
    {
      'subject': 'Physics',
      'chapter': 'Chapter 3: Motion',
      'time': '02:00 - 02:45 pm',
      'color': const Color(0xFFFFF4E6),
      'iconColor': const Color(0xFFFF9800),
      'icon': Icons.rocket_launch_outlined,
    },
    {
      'subject': 'Mathematics',
      'chapter': 'Chapter 5: Algebra',
      'time': '03:00 - 03:45 pm',
      'color': const Color(0xFFFCE4EC),
      'iconColor': const Color(0xFFE91E63),
      'icon': Icons.calculate_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildCalendar(),
              const SizedBox(height: 24),
              _buildClassList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'Class calender',
        style: AppTextStyles.heading1.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 20),
          _buildWeekDays(),
          const SizedBox(height: 12),
          _buildCalendarDays(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month - 1,
              );
            });
          },
        ),
        Text(
          _getMonthName(_focusedMonth.month),
          style: AppTextStyles.heading3.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildWeekDays() {
    final weekDays = ['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarDays() {
    final daysInMonth = _getDaysInMonth(_focusedMonth);
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startingWeekday = (firstDayOfMonth.weekday + 1) % 7; // Adjust to start from Saturday

    final weeks = <Widget>[];
    var dayIndex = 1 - startingWeekday;

    while (dayIndex <= daysInMonth) {
      final week = <Widget>[];
      for (var i = 0; i < 7; i++) {
        if (dayIndex < 1 || dayIndex > daysInMonth) {
          // Empty cell or previous/next month day
          final displayDay = dayIndex < 1
              ? _getDaysInMonth(DateTime(_focusedMonth.year, _focusedMonth.month - 1)) + dayIndex
              : dayIndex - daysInMonth;
          week.add(
            Expanded(
              child: _buildDayCell(
                displayDay.toString(),
                false,
                false,
              ),
            ),
          );
        } else {
          final currentDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayIndex);
          final isSelected = _isSameDay(currentDate, _selectedDate);
          final isToday = _isSameDay(currentDate, DateTime.now());
          week.add(
            Expanded(
              child: _buildDayCell(
                dayIndex.toString(),
                true,
                isSelected,
                isToday: isToday,
                date: currentDate,
              ),
            ),
          );
        }
        dayIndex++;
      }
      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: week),
        ),
      );
    }

    return Column(children: weeks);
  }

  Widget _buildDayCell(
    String day,
    bool isCurrentMonth,
    bool isSelected, {
    bool isToday = false,
    DateTime? date,
  }) {
    return GestureDetector(
      onTap: isCurrentMonth && date != null
          ? () {
              setState(() {
                _selectedDate = date;
              });
            }
          : null,
      child: Container(
        height: 36,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            day,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : isCurrentMonth
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassList() {
    return Column(
      children: _classes.map((classData) {
        return _buildClassCard(
          subject: classData['subject'],
          chapter: classData['chapter'],
          time: classData['time'],
          color: classData['color'],
          iconColor: classData['iconColor'],
          icon: classData['icon'],
        );
      }).toList(),
    );
  }

  Widget _buildClassCard({
    required String subject,
    required String chapter,
    required String time,
    required Color color,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Class info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chapter,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Arrow icon
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

