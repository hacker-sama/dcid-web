import 'package:dcid_app/data/docs_repository.dart';
import 'package:dcid_app/data/models/document_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseDocumentList reads items from PagedResponse (§3.1) — regression '
      'for the old `data as List` bug', () {
    // Fixture đúng shape backend: data là PagedResponse, KHÔNG phải List.
    final body = <String, dynamic>{
      'data': {
        'items': [
          {
            'id': '8f14e45f-0000-0000-0000-000000000001',
            'title': 'Manual máy CNC XK-500',
            'machineCode': 'CNC-01',
            'category': 'SOP',
            'minRole': 'OPERATOR',
            'description': null,
            'createdAt': '2026-07-02T03:00:00Z',
            'updatedAt': '2026-07-02T03:00:00Z',
          },
        ],
        'page': 0,
        'size': 20,
        'total': 1,
      },
      'meta': null,
    };

    final docs = DocsRepository.parseDocumentList(body);

    expect(docs, hasLength(1));
    expect(docs.single.id, '8f14e45f-0000-0000-0000-000000000001');
    expect(docs.single.title, 'Manual máy CNC XK-500');
    expect(docs.single.machineCode, 'CNC-01');
    expect(docs.single.category, 'SOP');
    expect(docs.single.minRole, 'OPERATOR');
    expect(docs.single.description, isNull);
  });

  test('parseDocumentList tolerates empty page', () {
    final docs = DocsRepository.parseDocumentList({
      'data': {'items': [], 'page': 0, 'size': 20, 'total': 0},
      'meta': null,
    });
    expect(docs, isEmpty);
  });

  test('DocumentDetail.fromJson parses document + versions (§3.2), '
      'null-safe for PROCESSING version', () {
    final detail = DocumentDetail.fromJson({
      'document': {
        'id': 'c9f0f895-0000-0000-0000-000000000002',
        'title': 'Manual máy CNC XK-500',
        'machineCode': 'CNC-01',
        'category': 'SOP',
        'minRole': 'OPERATOR',
        'description': 'Tài liệu vận hành',
        'createdAt': '2026-07-02T03:00:00Z',
        'updatedAt': '2026-07-02T03:00:00Z',
      },
      'versions': [
        {
          'id': 'v-active',
          'documentId': 'c9f0f895-0000-0000-0000-000000000002',
          'versionNo': 1,
          'status': 'ACTIVE',
          'lang': 'vi,en',
          'pageCount': 12,
          'originalFilename': 'manual.pdf',
          'fileSize': 1048576,
          'createdAt': '2026-07-02T03:00:00Z',
          'ingestedAt': '2026-07-02T03:05:00Z',
        },
        {
          // Đang PROCESSING: pageCount/ingestedAt/lang null theo contract.
          'id': 'v-processing',
          'documentId': 'c9f0f895-0000-0000-0000-000000000002',
          'versionNo': 2,
          'status': 'PROCESSING',
          'lang': null,
          'pageCount': null,
          'originalFilename': 'manual-v2.pdf',
          'fileSize': 2097152,
          'createdAt': '2026-07-02T04:00:00Z',
          'ingestedAt': null,
        },
      ],
    });

    expect(detail.document.title, 'Manual máy CNC XK-500');
    expect(detail.document.description, 'Tài liệu vận hành');
    expect(detail.versions, hasLength(2));

    final active = detail.versions[0];
    expect(active.status, 'ACTIVE');
    expect(active.versionNo, 1);
    expect(active.pageCount, 12);
    expect(active.lang, 'vi,en');
    expect(active.originalFilename, 'manual.pdf');
    expect(active.fileSize, 1048576);
    expect(active.ingestedAt, isNotNull);

    final processing = detail.versions[1];
    expect(processing.status, 'PROCESSING');
    expect(processing.pageCount, isNull);
    expect(processing.lang, isNull);
    expect(processing.ingestedAt, isNull);

    expect(detail.queryableVersion?.id, 'v-active');
  });

  test('DocumentDetail uses READY only when no ACTIVE version exists', () {
    final detail = DocumentDetail.fromJson({
      'document': {'id': 'x', 'title': 't'},
      'versions': [
        {'id': 'processing', 'versionNo': 3, 'status': 'PROCESSING'},
        {'id': 'ready', 'versionNo': 2, 'status': 'READY'},
      ],
    });

    expect(detail.queryableVersion?.id, 'ready');
  });

  test('DocumentDetail.fromJson tolerates missing versions array', () {
    final detail = DocumentDetail.fromJson({
      'document': {'id': 'x', 'title': 't'},
    });
    expect(detail.versions, isEmpty);
  });
}
