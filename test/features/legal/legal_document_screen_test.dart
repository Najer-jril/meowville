import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/features/legal/data/legal_documents.dart';
import 'package:meowville/features/legal/domain/legal_document.dart';
import 'package:meowville/features/legal/presentation/screens/legal_document_screen.dart';

void main() {
  Future<void> pumpDocument(WidgetTester tester, LegalDocument document) {
    return tester.pumpWidget(
      MaterialApp(home: LegalDocumentScreen(document: document)),
    );
  }

  testWidgets('ketentuan penitipan menampilkan judul dan spanduk draf', (
    WidgetTester tester,
  ) async {
    await pumpDocument(tester, LegalDocuments.ketentuanLayananPenitipan);

    expect(find.text('Ketentuan Layanan Penitipan'), findsOneWidget);
    expect(find.text('data dummy, belum final'), findsOneWidget);
    expect(find.text('Siapa kami'), findsOneWidget);
  });

  testWidgets('kebijakan kasih sayang menyebut perawatan dan data pribadi', (
    WidgetTester tester,
  ) async {
    await pumpDocument(tester, LegalDocuments.kebijakanKasihSayang);

    expect(find.text('Cara kami merawat kucing Anda'), findsOneWidget);
    expect(find.text('Data pribadi yang kami simpan'), findsOneWidget);
  });

  testWidgets('tidak ada luapan mendatar pada lebar telepon sempit', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpDocument(tester, LegalDocuments.ketentuanLayananPenitipan);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  test('setiap bagian dokumen punya isi', () {
    for (final LegalDocument document in <LegalDocument>[
      LegalDocuments.ketentuanLayananPenitipan,
      LegalDocuments.kebijakanKasihSayang,
    ]) {
      expect(document.sections, isNotEmpty);
      for (final LegalSection section in document.sections) {
        expect(
          section.paragraphs.isNotEmpty || section.points.isNotEmpty,
          isTrue,
          reason: 'Bagian "${section.heading}" kosong.',
        );
      }
    }
  });
}
