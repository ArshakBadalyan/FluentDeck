import 'flashcard_model.dart';

class NoteTypeModel {
  final String id;
  final String name;
  final List<NoteTypeFieldModel> fields;
  final List<String> cardTemplateNames;
  final List<NoteTypeCardTemplateModel> cardTemplates;
  final String css;
  final String themeId;
  final bool available;
  final bool isCustom;

  const NoteTypeModel({
    required this.id,
    required this.name,
    this.fields = const [],
    this.cardTemplateNames = const [],
    this.cardTemplates = const [],
    this.css = '',
    this.themeId = 'classic',
    this.available = true,
    this.isCustom = false,
  });

  int? get customDbId {
    if (!id.startsWith('custom:')) return null;
    return int.tryParse(id.substring(7));
  }

  factory NoteTypeModel.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final rawTemplates = json['cardTemplates'];
    final templates =
        rawTemplates is List
            ? rawTemplates
                .whereType<Map>()
                .map(
                  (t) => NoteTypeCardTemplateModel.fromJson(
                    Map<String, dynamic>.from(t),
                  ),
                )
                .toList()
            : const <NoteTypeCardTemplateModel>[];
    return NoteTypeModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      fields:
          rawFields is List
              ? rawFields
                  .whereType<Map>()
                  .map(
                    (f) => NoteTypeFieldModel.fromJson(
                      Map<String, dynamic>.from(f),
                    ),
                  )
                  .toList()
              : const [],
      cardTemplateNames:
          (json['cardTemplateNames'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          templates.map((t) => t.name).toList(),
      cardTemplates: templates,
      css: json['css'] as String? ?? '',
      themeId: json['themeId'] as String? ?? 'classic',
      available: json['available'] != false,
      isCustom: json['isCustom'] == true,
    );
  }

  Map<String, dynamic> toCustomPayload() => {
    'name': name,
    'fields': fields.map((f) => f.toJson()).toList(),
    'cardTemplates': cardTemplates.map((t) => t.toJson()).toList(),
    if (css.isNotEmpty) 'css': css,
    'themeId': themeId,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fields': fields.map((f) => f.toJson()).toList(),
    'cardTemplateNames': cardTemplateNames,
    'cardTemplates': cardTemplates.map((t) => t.toJson()).toList(),
    'css': css,
    'themeId': themeId,
    'available': available,
    'isCustom': isCustom,
  };
}

class NoteTypeCardTemplateModel {
  final String name;
  final int ordinal;
  final String qfmt;
  final String afmt;
  final bool reversed;
  final bool optional;
  final bool typeAnswer;

  const NoteTypeCardTemplateModel({
    required this.name,
    this.ordinal = 0,
    this.qfmt = '{{Front}}',
    this.afmt = '{{FrontSide}}<hr id="answer">{{Back}}',
    this.reversed = false,
    this.optional = false,
    this.typeAnswer = false,
  });

  factory NoteTypeCardTemplateModel.fromJson(Map<String, dynamic> json) {
    return NoteTypeCardTemplateModel(
      name: json['name'] as String? ?? 'Card 1',
      ordinal: json['ordinal'] as int? ?? 0,
      qfmt: json['qfmt'] as String? ?? '{{Front}}',
      afmt: json['afmt'] as String? ?? '{{Back}}',
      reversed: json['reversed'] == true,
      optional: json['optional'] == true,
      typeAnswer: json['typeAnswer'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'ordinal': ordinal,
    'qfmt': qfmt,
    'afmt': afmt,
    'reversed': reversed,
    'optional': optional,
    'typeAnswer': typeAnswer,
  };
}

class NoteTypeFieldModel {
  final String name;
  final bool required;

  const NoteTypeFieldModel({required this.name, this.required = false});

  factory NoteTypeFieldModel.fromJson(Map<String, dynamic> json) {
    return NoteTypeFieldModel(
      name: json['name'] as String? ?? '',
      required: json['required'] == true,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'required': required};
}

class FlashcardNoteModel {
  final int id;
  final String noteType;
  final Map<String, String> fields;
  final List<String> tags;
  final bool marked;
  final bool createReverse;
  final int? deckId;
  final String? mediaUrl;
  final List<FlashcardModel> cards;

  const FlashcardNoteModel({
    required this.id,
    required this.noteType,
    this.fields = const {},
    this.tags = const [],
    this.marked = false,
    this.createReverse = false,
    this.deckId,
    this.mediaUrl,
    this.cards = const [],
  });

  String get front => fields['Front'] ?? fields['front'] ?? '';
  String get back => fields['Back'] ?? fields['back'] ?? '';
  String get text => fields['Text'] ?? fields['text'] ?? front;

  factory FlashcardNoteModel.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final fieldsMap = <String, String>{};
    if (rawFields is Map) {
      rawFields.forEach((key, value) {
        fieldsMap[key.toString()] = value?.toString() ?? '';
      });
    }

    final rawCards = json['cards'];
    return FlashcardNoteModel(
      id: json['id'] as int? ?? 0,
      noteType: json['noteType'] as String? ?? 'basic',
      fields: fieldsMap,
      tags:
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      marked: json['marked'] == true,
      createReverse: json['createReverse'] == true,
      deckId: json['deckId'] as int?,
      mediaUrl: json['mediaUrl'] as String?,
      cards:
          rawCards is List
              ? rawCards
                  .whereType<Map>()
                  .map(
                    (c) => FlashcardModel.fromJson(
                      Map<String, dynamic>.from(c),
                    ),
                  )
                  .toList()
              : const [],
    );
  }

  Map<String, dynamic> toCreatePayload({
    required int deckId,
  }) => {
    'deckId': deckId,
    'noteType': noteType,
    'fields': fields,
    'tags': tags,
    'createReverse': createReverse,
    if (mediaUrl != null) 'mediaUrl': mediaUrl,
  };
}
