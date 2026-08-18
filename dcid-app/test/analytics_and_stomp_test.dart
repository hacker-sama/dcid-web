import 'package:dcid_app/data/models/analytics_summary.dart';
import 'package:dcid_app/data/models/ingest_progress_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Analytics Models Test', () {
    test('AnalyticsSummary.fromJson parses full payload correctly', () {
      final json = {
        'totalDocuments': 12,
        'totalVersions': 15,
        'totalQueries': 120,
        'avgConfidence': 0.885,
        'avgLatencyMs': 350,
        'totalLockedQueries': 6,
        'totalNumericRuleQueries': 24,
        'lockedRate': 5.0,
        'numericRuleRate': 20.0,
        'queriesByDay': [
          {'date': '2026-08-10', 'count': 15},
          {'date': '2026-08-11', 'count': 22},
        ],
        'documentsByCategory': [
          {'category': 'SOP', 'count': 5},
          {'category': 'DRAWING', 'count': 7},
        ],
        'topMachines': [
          {'machineCode': 'XK-500', 'count': 30},
        ],
      };

      final summary = AnalyticsSummary.fromJson(json);

      expect(summary.totalDocuments, 12);
      expect(summary.totalVersions, 15);
      expect(summary.totalQueries, 120);
      expect(summary.avgConfidence, 0.885);
      expect(summary.avgLatencyMs, 350);
      expect(summary.lockedRate, 5.0);
      expect(summary.numericRuleRate, 20.0);
      expect(summary.queriesByDay.length, 2);
      expect(summary.queriesByDay.first.date, '2026-08-10');
      expect(summary.queriesByDay.first.count, 15);
      expect(summary.documentsByCategory.length, 2);
      expect(summary.documentsByCategory.first.category, 'SOP');
      expect(summary.documentsByCategory.first.count, 5);
      expect(summary.topMachines.length, 1);
      expect(summary.topMachines.first.machineCode, 'XK-500');
    });

    test('AnalyticsSummary.fromJson handles empty/null fields safely', () {
      final summary = AnalyticsSummary.fromJson({});

      expect(summary.totalDocuments, 0);
      expect(summary.totalQueries, 0);
      expect(summary.avgConfidence, 0.0);
      expect(summary.queriesByDay, isEmpty);
      expect(summary.documentsByCategory, isEmpty);
      expect(summary.topMachines, isEmpty);
    });
  });

  group('IngestProgressMessage Test', () {
    test('IngestProgressMessage parsing and isDone/isFailed flags', () {
      final msgOcr = IngestProgressMessage.fromJson({
        'versionId': 'f5d130a1-77aa-485e-9905-eb8da3e0aa01',
        'step': 'OCR',
        'progress': 30,
        'message': 'Đang trích xuất OCR văn bản trang 3...',
      });

      expect(msgOcr.versionId, 'f5d130a1-77aa-485e-9905-eb8da3e0aa01');
      expect(msgOcr.step, 'OCR');
      expect(msgOcr.progress, 30);
      expect(msgOcr.isDone, false);
      expect(msgOcr.isFailed, false);

      final msgReady = IngestProgressMessage.fromJson({
        'versionId': 'f5d130a1-77aa-485e-9905-eb8da3e0aa01',
        'step': 'READY',
        'progress': 100,
        'message': 'Xử lý thành công',
      });

      expect(msgReady.isDone, true);
      expect(msgReady.isFailed, false);

      final msgFailed = IngestProgressMessage.fromJson({
        'versionId': 'f5d130a1-77aa-485e-9905-eb8da3e0aa01',
        'step': 'FAILED',
        'progress': 0,
        'message': 'Không thể trích xuất PDF bị mã hóa mật khẩu',
      });

      expect(msgFailed.isDone, false);
      expect(msgFailed.isFailed, true);
    });
  });
}
