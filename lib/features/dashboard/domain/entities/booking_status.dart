enum BookingStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  rejected('Rejected'),
  checkedIn('CheckedIn'),
  checkedOut('CheckedOut'),
  cancelled('Cancelled');

  const BookingStatus(this.wireValue);

  final String wireValue;

  static BookingStatus fromWireValue(String value) {
    return BookingStatus.values.firstWhere(
      (BookingStatus status) => status.wireValue == value,
      orElse: () => BookingStatus.pending,
    );
  }
}
