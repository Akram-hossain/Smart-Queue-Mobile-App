import 'package:flutter/material.dart';

import '../core/constants.dart';

enum TaskType {
  ct('CT', 'CT Exam', Icons.quiz_outlined),
  lab('LAB', 'Lab Exam', Icons.biotech_outlined),
  viva('VIVA', 'Viva', Icons.record_voice_over_outlined),
  assignment('ASSIGNMENT', 'Assignment', Icons.assignment_outlined),
  finalExam('FINAL', 'Final Exam', Icons.school_outlined);

  const TaskType(this.dbValue, this.label, this.icon);

  final String dbValue;
  final String label;
  final IconData icon;

  static TaskType fromDb(String value) =>
      TaskType.values.firstWhere((e) => e.dbValue == value,
          orElse: () => TaskType.assignment);

  Color get color {
    switch (this) {
      case TaskType.ct:
        return AppColors.primary;
      case TaskType.lab:
        return AppColors.info;
      case TaskType.viva:
        return AppColors.accent;
      case TaskType.assignment:
        return AppColors.warning;
      case TaskType.finalExam:
        return AppColors.danger;
    }
  }
}

enum TaskPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High');

  const TaskPriority(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static TaskPriority fromDb(String value) =>
      TaskPriority.values.firstWhere((e) => e.dbValue == value,
          orElse: () => TaskPriority.medium);

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return AppColors.success;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.high:
        return AppColors.danger;
    }
  }
}

enum TaskStatus {
  pending('pending', 'Pending'),
  inProgress('in_progress', 'In progress'),
  completed('completed', 'Completed');

  const TaskStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static TaskStatus fromDb(String value) =>
      TaskStatus.values.firstWhere((e) => e.dbValue == value,
          orElse: () => TaskStatus.pending);
}

enum Grade {
  aPlus('A+', 4.00),
  a('A', 3.75),
  aMinus('A-', 3.50),
  bPlus('B+', 3.25),
  b('B', 3.00),
  bMinus('B-', 2.75),
  cPlus('C+', 2.50),
  c('C', 2.25),
  d('D', 2.00),
  f('F', 0.00);

  const Grade(this.label, this.points);

  final String label;
  final double points;

  static Grade fromLabel(String label) =>
      Grade.values.firstWhere((e) => e.label == label,
          orElse: () => Grade.f);
}
