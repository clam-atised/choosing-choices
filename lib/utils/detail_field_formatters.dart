import '../models/choice_card.dart';
import 'card_date_utils.dart';

String detailFieldDisplayValue(CardDetailField detail) {
  return switch (detail.type) {
    DetailFieldType.text => detail.textValue ?? '',
    DetailFieldType.yesNo => detail.yesNoValue == true ? 'Yes' : 'No',
    DetailFieldType.dropdown => detail.dropdownValue ?? '',
    DetailFieldType.time => _formatTimeRange(detail.timeFrom, detail.timeTo),
    DetailFieldType.days => _formatWeekDays(detail.weekDays),
    DetailFieldType.date => _formatDateRange(detail),
  };
}

String normalizeDetailLabel(String label) {
  var value = label.trim();
  while (value.endsWith(':')) {
    value = value.substring(0, value.length - 1).trimRight();
  }
  return value;
}

String formatDetailLine(CardDetailField detail) {
  final label = normalizeDetailLabel(detail.label);
  if (label.isEmpty) {
    return detailFieldDisplayValue(detail);
  }
  return '$label: ${detailFieldDisplayValue(detail)}';
}

String detailFieldPreviewLabel(CardDetailField field) {
  final normalized = normalizeDetailLabel(field.label);
  final label = normalized.isEmpty ? 'Detail' : normalized;
  final filled = detailFieldDisplayValue(field);
  if (filled.isNotEmpty) {
    return '$label: $filled';
  }
  final placeholder = switch (field.type) {
    DetailFieldType.text => '<text>',
    DetailFieldType.yesNo => '<yes/no>',
    DetailFieldType.dropdown => '<dropdown>',
    DetailFieldType.time => '<time>',
    DetailFieldType.days => '<days>',
    DetailFieldType.date => '<date>',
  };
  return '$label: $placeholder';
}

String _formatTimeRange(String? from, String? to) {
  if ((from == null || from.isEmpty) && (to == null || to.isEmpty)) {
    return '';
  }
  if (from != null && from.isNotEmpty && to != null && to.isNotEmpty) {
    return '$from – $to';
  }
  return from ?? to ?? '';
}

String _formatDateRange(CardDetailField detail) {
  final range = dateRangeForField(detail);
  if (range == null) {
    return '';
  }
  final fromLabel = _formatDisplayDate(range.from);
  if (range.isSingleDay) {
    return fromLabel;
  }
  return '$fromLabel – ${_formatDisplayDate(range.to)}';
}

String _formatDisplayDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatWeekDays(List<bool> weekDays) {
  if (weekDays.length != 7) {
    return '';
  }

  final selected = <String>[];
  for (var index = 0; index < 7; index++) {
    if (weekDays[index]) {
      selected.add(kWeekDayLabels[index]);
    }
  }
  return selected.join(', ');
}

List<bool> normalizeWeekDays(List<bool> weekDays) {
  if (weekDays.length == 7) {
    return [...weekDays];
  }
  return List<bool>.filled(7, false);
}
