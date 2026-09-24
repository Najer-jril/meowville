class PetSummary {
  const PetSummary({
    required this.id,
    required this.name,
    required this.breed,
    this.sex,
    this.weightKg,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String breed;
  final String? sex;
  final double? weightKg;
  final String? photoUrl;
}
