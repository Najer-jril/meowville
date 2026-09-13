class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.intro,
    required this.status,
    required this.sections,
  });

  final String title;
  final String intro;

  final LegalDocumentStatus status;
  final List<LegalSection> sections;
}

class LegalDocumentStatus {
  const LegalDocumentStatus({required this.label, required this.detail});

  final String label;
  final String detail;
}

class LegalSection {
  const LegalSection({
    required this.heading,
    this.paragraphs = const <String>[],
    this.points = const <String>[],
  });

  final String heading;
  final List<String> paragraphs;
  final List<String> points;
}
