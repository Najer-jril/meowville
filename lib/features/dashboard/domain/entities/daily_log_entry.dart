class DailyLogEntry {
  const DailyLogEntry({
    required this.id,
    required this.bookingId,
    required this.logDate,
    required this.createdAt,
    this.eatingTime,
    this.mood,
    this.note,
    this.photoUrl,
    this.authorName,
  });

  final String id;
  final String bookingId;
  final DateTime logDate;
  final DateTime createdAt;

  final String? eatingTime;
  final String? mood;
  final String? note;
  final String? photoUrl;
  final String? authorName;

  bool get hasNote => note != null && note!.trim().isNotEmpty;
}
