import 'dart:convert';

class OcclusionRegion {
  final int id;
  final double x;
  final double y;
  final double w;
  final double h;
  final String label;

  const OcclusionRegion({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.label = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    if (label.isNotEmpty) 'label': label,
  };

  factory OcclusionRegion.fromJson(Map<String, dynamic> json) {
    return OcclusionRegion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      w: (json['w'] as num?)?.toDouble() ?? 0,
      h: (json['h'] as num?)?.toDouble() ?? 0,
      label: json['label']?.toString() ?? json['answer']?.toString() ?? '',
    );
  }
}

class OcclusionData {
  final String imageUrl;
  final String header;
  final List<OcclusionRegion> regions;
  final int activeIndex;

  const OcclusionData({
    required this.imageUrl,
    this.header = '',
    this.regions = const [],
    this.activeIndex = 0,
  });

  OcclusionRegion? get activeRegion {
    if (activeIndex < 0 || activeIndex >= regions.length) return null;
    return regions[activeIndex];
  }

  factory OcclusionData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const OcclusionData(imageUrl: '');
    }
    final rawRegions = json['regions'];
    final regions =
        rawRegions is List
            ? rawRegions
                .whereType<Map>()
                .map((m) => OcclusionRegion.fromJson(Map<String, dynamic>.from(m)))
                .toList()
            : <OcclusionRegion>[];

    return OcclusionData(
      imageUrl: json['imageUrl']?.toString() ?? '',
      header: json['header']?.toString() ?? '',
      regions: regions,
      activeIndex: (json['activeIndex'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'imageUrl': imageUrl,
    if (header.isNotEmpty) 'header': header,
    'regions': regions.map((r) => r.toJson()).toList(),
    'activeIndex': activeIndex,
  };
}

List<OcclusionRegion> parseOcclusionField(String raw) {
  if (raw.trim().isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final regions = decoded['regions'];
      if (regions is! List) return [];
      return regions
          .whereType<Map>()
          .map((m) => OcclusionRegion.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((m) => OcclusionRegion.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
  } catch (_) {}
  return [];
}

String occlusionFieldJson(List<OcclusionRegion> regions) {
  return jsonEncode({
    'regions': regions.map((r) => r.toJson()).toList(),
  });
}
