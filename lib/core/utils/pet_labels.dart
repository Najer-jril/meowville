String aggressivenessLabel(String value) => switch (value) {
  'Low' => 'Rendah',
  'Medium' => 'Sedang',
  'High' => 'Tinggi',
  _ => value,
};

String formatWeightKg(double kg) {
  final String text = kg == kg.roundToDouble()
      ? kg.toStringAsFixed(0)
      : kg.toStringAsFixed(1);
  return '${text.replaceAll('.', ',')} kg';
}
