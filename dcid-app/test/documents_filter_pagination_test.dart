import 'package:dcid_app/core/localization/app_strings.dart';
import 'package:dcid_app/data/models/document_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Document Localization Tests', () {
    final vi = AppStringsVi();
    final en = AppStringsEn();
    final hi = AppStringsHi();
    final ja = AppStringsJa();

    test('All language providers have valid pagination and filter strings', () {
      final providers = <AppStrings>[vi, en, hi, ja];

      for (final s in providers) {
        expect(s.rowsPerPage, isNotEmpty);
        expect(s.firstPage, isNotEmpty);
        expect(s.lastPage, isNotEmpty);
        expect(s.previousPage, isNotEmpty);
        expect(s.nextPage, isNotEmpty);
        expect(s.clearFilters, isNotEmpty);
        expect(s.allCategories, isNotEmpty);
        expect(s.showingDocsCount(1, 10, 100), contains('1'));
        expect(s.showingDocsCount(1, 10, 100), contains('10'));
        expect(s.showingDocsCount(1, 10, 100), contains('100'));
        expect(s.pageOf(1, 10), contains('1'));
        expect(s.pageOf(1, 10), contains('10'));
      }
    });
  });

  group('Document Filtering, Sorting and Pagination Logic Tests', () {
    final sampleDocs = [
      DocumentSummary(
        id: '1',
        title: 'CNC Machine 01 Manual',
        category: 'SOP',
        machineCode: 'CNC-01',
        minRole: 'OPERATOR',
        updatedAt: '2026-08-01T10:00:00Z',
      ),
      DocumentSummary(
        id: '2',
        title: 'Electrical Circuit Diagram',
        category: 'CIRCUIT',
        machineCode: 'ELEC-99',
        minRole: 'OPERATOR',
        updatedAt: '2026-08-05T12:00:00Z',
      ),
      DocumentSummary(
        id: '3',
        title: 'Safety Guidelines for Welding',
        category: 'SAFETY',
        machineCode: 'WELD-02',
        minRole: 'OPERATOR',
        updatedAt: '2026-07-20T08:00:00Z',
      ),
      DocumentSummary(
        id: '4',
        title: 'CNC Maintenance Guide',
        category: 'SOP',
        machineCode: 'CNC-02',
        minRole: 'OPERATOR',
        updatedAt: '2026-08-10T15:00:00Z',
      ),
    ];

    test('Filter by category returns only matching items', () {
      final sopDocs = sampleDocs.where((d) => (d.category ?? '').toUpperCase() == 'SOP').toList();
      expect(sopDocs.length, 2);
      expect(sopDocs.map((d) => d.id), containsAll(['1', '4']));
    });

    test('Filter by search query matches title and machineCode', () {
      final query = 'cnc';
      final results = sampleDocs.where((d) {
        final t = d.title.toLowerCase();
        final c = (d.category ?? '').toLowerCase();
        final m = (d.machineCode ?? '').toLowerCase();
        return t.contains(query) || c.contains(query) || m.contains(query);
      }).toList();

      expect(results.length, 2);
      expect(results.map((d) => d.id), containsAll(['1', '4']));
    });

    test('Sorting by title ascending and descending works correctly', () {
      final sortedAsc = List<DocumentSummary>.from(sampleDocs)
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      expect(sortedAsc.first.title, 'CNC Machine 01 Manual');
      expect(sortedAsc.last.title, 'Safety Guidelines for Welding');

      final sortedDesc = List<DocumentSummary>.from(sampleDocs)
        ..sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      expect(sortedDesc.first.title, 'Safety Guidelines for Welding');
      expect(sortedDesc.last.title, 'CNC Machine 01 Manual');
    });

    test('Sorting by update date works correctly', () {
      final sortedNewest = List<DocumentSummary>.from(sampleDocs)
        ..sort((a, b) => (b.updatedAt ?? '').compareTo(a.updatedAt ?? ''));
      expect(sortedNewest.first.id, '4'); // 2026-08-10

      final sortedOldest = List<DocumentSummary>.from(sampleDocs)
        ..sort((a, b) => (a.updatedAt ?? '').compareTo(b.updatedAt ?? ''));
      expect(sortedOldest.first.id, '3'); // 2026-07-20
    });

    test('Pagination slicing handles pages and bounds correctly', () {
      final pageSize = 2;
      final total = sampleDocs.length; // 4
      final totalPages = (total / pageSize).ceil(); // 2

      expect(totalPages, 2);

      // Page 1
      final page1Start = (1 - 1) * pageSize;
      final page1End = (page1Start + pageSize).clamp(0, total);
      final page1Docs = sampleDocs.sublist(page1Start, page1End);
      expect(page1Docs.length, 2);
      expect(page1Docs.first.id, '1');
      expect(page1Docs.last.id, '2');

      // Page 2
      final page2Start = (2 - 1) * pageSize;
      final page2End = (page2Start + pageSize).clamp(0, total);
      final page2Docs = sampleDocs.sublist(page2Start, page2End);
      expect(page2Docs.length, 2);
      expect(page2Docs.first.id, '3');
      expect(page2Docs.last.id, '4');
    });
  });
}
