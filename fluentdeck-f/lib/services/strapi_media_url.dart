import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves Strapi upload plugin URLs for use with [CachedStrapiImage].
///
/// [API_URL] is typically `…/api`; media paths are usually served from the
/// same host without the `/api` suffix.
abstract final class StrapiMediaUrl {
  static String? _publicOrigin() {
    final api = dotenv.env['API_URL'];
    if (api == null || api.trim().isEmpty) return null;
    var t = api.trim();
    while (t.endsWith('/')) {
      t = t.substring(0, t.length - 1);
    }
    if (t.endsWith('/api')) {
      return t.substring(0, t.length - 4);
    }
    return t;
  }

  static String? resolve(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);

    String? pickFromAttributes(Map<String, dynamic> attrs) {
      final u = attrs['url']?.toString();
      if (u == null || u.trim().isEmpty) return null;
      return _absolute(u.trim());
    }

    final data = m['data'];
    if (data is Map) {
      final dm = Map<String, dynamic>.from(data);
      final attrs = dm['attributes'];
      if (attrs is Map<String, dynamic>) {
        return pickFromAttributes(attrs);
      }
      final u = dm['url']?.toString();
      if (u != null && u.trim().isNotEmpty) return _absolute(u.trim());
    }
    if (data is List && data.isNotEmpty) {
      return resolve(data.first);
    }

    final direct = m['url']?.toString();
    if (direct != null && direct.trim().isNotEmpty) {
      return _absolute(direct.trim());
    }
    return null;
  }

  static String _absolute(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final origin = _publicOrigin();
    if (origin == null || origin.isEmpty) return url;
    if (url.startsWith('/')) {
      return '$origin$url';
    }
    return '$origin/$url';
  }

  static List<String> resolveMany(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      final out = <String>[];
      for (final e in raw) {
        final u = resolve(e);
        if (u != null && u.isNotEmpty) out.add(u);
      }
      return out;
    }
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) {
        return resolveMany(data);
      }
      final u = resolve(raw);
      return u == null ? [] : [u];
    }
    return [];
  }
}
