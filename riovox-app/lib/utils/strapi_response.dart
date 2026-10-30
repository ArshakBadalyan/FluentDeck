/// Helpers for Strapi REST responses (v4 nested `attributes` and v5 flattened).
class StrapiResponse {
  StrapiResponse._();

  /// Collection body: `{ data: [...] }`, bare list, or empty.
  static List<Map<String, dynamic>> list(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => unwrap(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (body is Map) {
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => unwrap(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  }

  /// Single entity: `{ data: {...} }`, flat map, or null.
  static Map<String, dynamic>? row(dynamic body) {
    if (body is! Map || body.containsKey('error')) return null;
    final data = body['data'];
    if (data is Map) {
      return unwrap(Map<String, dynamic>.from(data));
    }
    if (!body.containsKey('data')) {
      return unwrap(Map<String, dynamic>.from(body));
    }
    return null;
  }

  /// Unwrap Strapi v4 `{ id, attributes: { ... } }` into a flat map.
  static Map<String, dynamic> unwrap(Map<String, dynamic> json) {
    final attrs = json['attributes'];
    if (attrs is Map) {
      return {
        ...Map<String, dynamic>.from(attrs),
        if (json['id'] != null) 'id': json['id'],
        if (json['documentId'] != null) 'documentId': json['documentId'],
      };
    }
    return json;
  }

  /// Read a field from v4 (`attributes`) or v5 (top-level) notification/entity maps.
  static T? field<T>(Map<String, dynamic> json, String key) {
    final attrs = json['attributes'];
    if (attrs is Map && attrs.containsKey(key)) {
      final v = attrs[key];
      return v is T ? v : null;
    }
    final v = json[key];
    return v is T ? v : null;
  }
}
