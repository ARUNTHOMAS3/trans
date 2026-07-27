import 'package:zerpai_erp/core/services/api_client.dart';

class SettingsPreferencesRepository {
  SettingsPreferencesRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> load() async {
    final response = await _apiClient.get(
      'settings-setup/general-preferences',
      useCache: false,
    );
    return _map(response.data);
  }

  Future<Map<String, dynamic>> loadSection(
    String column, [
    List<String> path = const <String>[],
  ]) async {
    dynamic value = (await load())[column];
    for (final key in path) {
      value = value is Map ? value[key] : null;
    }
    return _map(value);
  }

  Future<void> saveSection(
    String column,
    Map<String, dynamic> values, [
    List<String> path = const <String>[],
  ]) async {
    dynamic nested = values;
    for (final key in path.reversed) {
      nested = <String, dynamic>{key: nested};
    }
    await save(<String, dynamic>{column: nested});
  }

  Future<void> save(Map<String, dynamic> sections) async {
    await _apiClient.put('settings-setup/general-preferences', data: sections);
    _apiClient.clearCache('settings-setup/general-preferences');
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}
