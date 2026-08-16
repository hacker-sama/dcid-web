import 'api_client.dart';
import 'models/analytics_summary.dart';

abstract class AnalyticsRepositoryInterface {
  Future<AnalyticsSummary> getAnalytics();
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
}
