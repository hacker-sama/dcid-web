import 'api_client.dart';
import 'models/analytics_summary.dart';
import 'models/feedback_admin_item.dart';

abstract class AnalyticsRepositoryInterface {
  Future<AnalyticsSummary> getAnalytics();
  Future<List<FeedbackAdminItem>> getFeedbacks({int? feedback, int page = 0, int size = 50});
  Future<void> resetAnalytics();
}

class AnalyticsRepository implements AnalyticsRepositoryInterface {
  AnalyticsRepository(this._client);

  final ApiClient _client;

  @override
  Future<AnalyticsSummary> getAnalytics() async {
    final response = await _client.dio.get('/api/admin/analytics');
    final data = response.data['data'] as Map<String, dynamic>;
    return AnalyticsSummary.fromJson(data);
  }

  @override
  Future<void> resetAnalytics() async {
    await _client.dio.delete('/api/admin/analytics/reset');
  }

  @override
  Future<List<FeedbackAdminItem>> getFeedbacks({int? feedback, int page = 0, int size = 50}) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (feedback != null) {
      queryParams['feedback'] = feedback;
    }
    final response = await _client.dio.get('/api/admin/feedbacks', queryParameters: queryParams);
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? []);
    return items.map((e) => FeedbackAdminItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

