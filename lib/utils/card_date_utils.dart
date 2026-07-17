import '../models/choice_card.dart';

class CardDateRange {
  const CardDateRange({
    required this.from,
    required this.to,
  });

  final DateTime from;
  final DateTime to;

  bool get isSingleDay =>
      from.year == to.year && from.month == to.month && from.day == to.day;
}

DateTime? parseIsoDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String formatIsoDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

CardDateRange? dateRangeForField(CardDetailField field) {
  if (field.type != DetailFieldType.date) {
    return null;
  }

  final from = parseIsoDate(field.dateFrom);
  final to = parseIsoDate(field.dateTo) ?? from;
  if (from == null && to == null) {
    return null;
  }
  if (from == null) {
    return CardDateRange(from: to!, to: to);
  }
  if (to == null) {
    return CardDateRange(from: from, to: from);
  }
  if (to.isBefore(from)) {
    return CardDateRange(from: to, to: from);
  }
  return CardDateRange(from: from, to: to);
}

/// Earliest end date among date fields — used for sort and expiry.
CardDateRange? primaryDateRange(ChoiceCard card) {
  CardDateRange? earliest;
  for (final detail in card.details) {
    final range = dateRangeForField(detail);
    if (range == null) {
      continue;
    }
    if (earliest == null ||
        range.to.isBefore(earliest.to) ||
        (range.to == earliest.to && range.from.isBefore(earliest.from))) {
      earliest = range;
    }
  }
  return earliest;
}

bool isDateExpired(ChoiceCard card, {DateTime? now}) {
  final range = primaryDateRange(card);
  if (range == null) {
    return false;
  }
  final today = dateOnly(now ?? DateTime.now());
  return today.isAfter(range.to);
}

bool isCardInactive(ChoiceCard card, {DateTime? now}) {
  return card.isStamped || isDateExpired(card, now: now);
}

bool requiresNewDateToReopen(ChoiceCard card, {DateTime? now}) {
  return isDateExpired(card, now: now);
}

/// Sort key: sooner end date first; undated last within a group; same
/// from+to → alphabetical by title. Returns 0 when both undated so callers
/// can preserve relative order.
int compareCardsByUpcomingDate(ChoiceCard a, ChoiceCard b, {DateTime? now}) {
  final rangeA = primaryDateRange(a);
  final rangeB = primaryDateRange(b);

  if (rangeA == null && rangeB == null) {
    return 0;
  }
  if (rangeA == null) {
    return 1;
  }
  if (rangeB == null) {
    return -1;
  }

  final endCompare = rangeA.to.compareTo(rangeB.to);
  if (endCompare != 0) {
    return endCompare;
  }

  final startCompare = rangeA.from.compareTo(rangeB.from);
  if (startCompare != 0) {
    return startCompare;
  }

  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}

List<ChoiceCard> sortCardsByDateAndActivity(
  Iterable<ChoiceCard> cards, {
  DateTime? now,
}) {
  final listed = cards.toList();
  final active = <(int, ChoiceCard)>[];
  final inactive = <(int, ChoiceCard)>[];
  for (var i = 0; i < listed.length; i++) {
    final card = listed[i];
    if (isCardInactive(card, now: now)) {
      inactive.add((i, card));
    } else {
      active.add((i, card));
    }
  }

  int compareIndexed((int, ChoiceCard) a, (int, ChoiceCard) b) {
    final cmp = compareCardsByUpcomingDate(a.$2, b.$2, now: now);
    if (cmp != 0) {
      return cmp;
    }
    return a.$1.compareTo(b.$1);
  }

  active.sort(compareIndexed);
  inactive.sort(compareIndexed);
  return [
    ...active.map((entry) => entry.$2),
    ...inactive.map((entry) => entry.$2),
  ];
}

/// Whether saving [updated] should clear `isStamped` because the date moved
/// to a non-expired range.
bool shouldReactivateOnDateUpdate({
  required ChoiceCard previous,
  required ChoiceCard updated,
  DateTime? now,
}) {
  if (isDateExpired(updated, now: now)) {
    return false;
  }

  final updatedRange = primaryDateRange(updated);
  if (updatedRange == null) {
    return false;
  }

  final previousRange = primaryDateRange(previous);
  if (datesEqual(previousRange, updatedRange)) {
    return false;
  }

  return true;
}

bool datesEqual(CardDateRange? a, CardDateRange? b) {
  if (a == null && b == null) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  return a.from == b.from && a.to == b.to;
}
