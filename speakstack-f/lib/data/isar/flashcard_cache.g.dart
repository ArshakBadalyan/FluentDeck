// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedFlashcardDeckCollection on Isar {
  IsarCollection<CachedFlashcardDeck> get cachedFlashcardDecks =>
      this.collection();
}

const CachedFlashcardDeckSchema = CollectionSchema(
  name: r'CachedFlashcardDeck',
  id: -4919545927329905935,
  properties: {
    r'deckOptionsJson': PropertySchema(
      id: 0,
      name: r'deckOptionsJson',
      type: IsarType.string,
    ),
    r'deckSlug': PropertySchema(
      id: 1,
      name: r'deckSlug',
      type: IsarType.string,
    ),
    r'isDefault': PropertySchema(
      id: 2,
      name: r'isDefault',
      type: IsarType.bool,
    ),
    r'learningCount': PropertySchema(
      id: 3,
      name: r'learningCount',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'newCount': PropertySchema(
      id: 5,
      name: r'newCount',
      type: IsarType.long,
    ),
    r'reviewDueCount': PropertySchema(
      id: 6,
      name: r'reviewDueCount',
      type: IsarType.long,
    ),
    r'serverId': PropertySchema(
      id: 7,
      name: r'serverId',
      type: IsarType.long,
    ),
    r'total': PropertySchema(
      id: 8,
      name: r'total',
      type: IsarType.long,
    )
  },
  estimateSize: _cachedFlashcardDeckEstimateSize,
  serialize: _cachedFlashcardDeckSerialize,
  deserialize: _cachedFlashcardDeckDeserialize,
  deserializeProp: _cachedFlashcardDeckDeserializeProp,
  idName: r'id',
  indexes: {
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedFlashcardDeckGetId,
  getLinks: _cachedFlashcardDeckGetLinks,
  attach: _cachedFlashcardDeckAttach,
  version: '3.1.0+1',
);

int _cachedFlashcardDeckEstimateSize(
  CachedFlashcardDeck object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.deckOptionsJson.length * 3;
  bytesCount += 3 + object.deckSlug.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _cachedFlashcardDeckSerialize(
  CachedFlashcardDeck object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.deckOptionsJson);
  writer.writeString(offsets[1], object.deckSlug);
  writer.writeBool(offsets[2], object.isDefault);
  writer.writeLong(offsets[3], object.learningCount);
  writer.writeString(offsets[4], object.name);
  writer.writeLong(offsets[5], object.newCount);
  writer.writeLong(offsets[6], object.reviewDueCount);
  writer.writeLong(offsets[7], object.serverId);
  writer.writeLong(offsets[8], object.total);
}

CachedFlashcardDeck _cachedFlashcardDeckDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedFlashcardDeck();
  object.deckOptionsJson = reader.readString(offsets[0]);
  object.deckSlug = reader.readString(offsets[1]);
  object.id = id;
  object.isDefault = reader.readBool(offsets[2]);
  object.learningCount = reader.readLong(offsets[3]);
  object.name = reader.readString(offsets[4]);
  object.newCount = reader.readLong(offsets[5]);
  object.reviewDueCount = reader.readLong(offsets[6]);
  object.serverId = reader.readLong(offsets[7]);
  object.total = reader.readLong(offsets[8]);
  return object;
}

P _cachedFlashcardDeckDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedFlashcardDeckGetId(CachedFlashcardDeck object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedFlashcardDeckGetLinks(
    CachedFlashcardDeck object) {
  return [];
}

void _cachedFlashcardDeckAttach(
    IsarCollection<dynamic> col, Id id, CachedFlashcardDeck object) {
  object.id = id;
}

extension CachedFlashcardDeckByIndex on IsarCollection<CachedFlashcardDeck> {
  Future<CachedFlashcardDeck?> getByServerId(int serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  CachedFlashcardDeck? getByServerIdSync(int serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(int serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(int serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<CachedFlashcardDeck?>> getAllByServerId(
      List<int> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<CachedFlashcardDeck?> getAllByServerIdSync(List<int> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'serverId', values);
  }

  Future<int> deleteAllByServerId(List<int> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'serverId', values);
  }

  int deleteAllByServerIdSync(List<int> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'serverId', values);
  }

  Future<Id> putByServerId(CachedFlashcardDeck object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(CachedFlashcardDeck object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<CachedFlashcardDeck> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<CachedFlashcardDeck> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension CachedFlashcardDeckQueryWhereSort
    on QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QWhere> {
  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhere>
      anyServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'serverId'),
      );
    });
  }
}

extension CachedFlashcardDeckQueryWhere
    on QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QWhereClause> {
  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhereClause>
      serverIdEqualTo(int serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhereClause>
      serverIdNotEqualTo(int serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhereClause>
      serverIdGreaterThan(
    int serverId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'serverId',
        lower: [serverId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhereClause>
      serverIdLessThan(
    int serverId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'serverId',
        lower: [],
        upper: [serverId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterWhereClause>
      serverIdBetween(
    int lowerServerId,
    int upperServerId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'serverId',
        lower: [lowerServerId],
        includeLower: includeLower,
        upper: [upperServerId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedFlashcardDeckQueryFilter on QueryBuilder<CachedFlashcardDeck,
    CachedFlashcardDeck, QFilterCondition> {
  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckOptionsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deckOptionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckOptionsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deckOptionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckOptionsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deckOptionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckOptionsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deckOptionsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckOptionsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deckOptionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckOptionsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deckOptionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckOptionsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deckOptionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckOptionsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deckOptionsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckOptionsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deckOptionsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckOptionsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deckOptionsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckSlugEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deckSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckSlugGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deckSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckSlugLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deckSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckSlugBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deckSlug',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckSlugStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deckSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckSlugEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deckSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckSlugContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deckSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckSlugMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deckSlug',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckSlugIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deckSlug',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      deckSlugIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deckSlug',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      isDefaultEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDefault',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      learningCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'learningCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      learningCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'learningCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      learningCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'learningCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      learningCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'learningCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      newCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'newCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      newCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'newCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      newCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'newCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      newCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'newCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      reviewDueCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reviewDueCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      reviewDueCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reviewDueCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      reviewDueCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reviewDueCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      reviewDueCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reviewDueCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      serverIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      serverIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      serverIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      serverIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      totalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'total',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      totalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'total',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      totalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'total',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterFilterCondition>
      totalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'total',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedFlashcardDeckQueryObject on QueryBuilder<CachedFlashcardDeck,
    CachedFlashcardDeck, QFilterCondition> {}

extension CachedFlashcardDeckQueryLinks on QueryBuilder<CachedFlashcardDeck,
    CachedFlashcardDeck, QFilterCondition> {}

extension CachedFlashcardDeckQuerySortBy
    on QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QSortBy> {
  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByDeckOptionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckOptionsJson', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByDeckOptionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckOptionsJson', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByDeckSlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckSlug', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByDeckSlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckSlug', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByIsDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByLearningCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learningCount', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByLearningCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learningCount', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByNewCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newCount', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByNewCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newCount', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByReviewDueCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewDueCount', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByReviewDueCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewDueCount', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      sortByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }
}

extension CachedFlashcardDeckQuerySortThenBy
    on QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QSortThenBy> {
  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByDeckOptionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckOptionsJson', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByDeckOptionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckOptionsJson', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByDeckSlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckSlug', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByDeckSlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckSlug', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByIsDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByLearningCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learningCount', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByLearningCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learningCount', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByNewCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newCount', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByNewCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newCount', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByReviewDueCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewDueCount', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByReviewDueCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewDueCount', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QAfterSortBy>
      thenByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }
}

extension CachedFlashcardDeckQueryWhereDistinct
    on QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QDistinct> {
  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QDistinct>
      distinctByDeckOptionsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deckOptionsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QDistinct>
      distinctByDeckSlug({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deckSlug', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QDistinct>
      distinctByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDefault');
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QDistinct>
      distinctByLearningCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'learningCount');
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QDistinct>
      distinctByNewCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'newCount');
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QDistinct>
      distinctByReviewDueCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reviewDueCount');
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QDistinct>
      distinctByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId');
    });
  }

  QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QDistinct>
      distinctByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'total');
    });
  }
}

extension CachedFlashcardDeckQueryProperty
    on QueryBuilder<CachedFlashcardDeck, CachedFlashcardDeck, QQueryProperty> {
  QueryBuilder<CachedFlashcardDeck, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedFlashcardDeck, String, QQueryOperations>
      deckOptionsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deckOptionsJson');
    });
  }

  QueryBuilder<CachedFlashcardDeck, String, QQueryOperations>
      deckSlugProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deckSlug');
    });
  }

  QueryBuilder<CachedFlashcardDeck, bool, QQueryOperations>
      isDefaultProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDefault');
    });
  }

  QueryBuilder<CachedFlashcardDeck, int, QQueryOperations>
      learningCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'learningCount');
    });
  }

  QueryBuilder<CachedFlashcardDeck, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CachedFlashcardDeck, int, QQueryOperations> newCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'newCount');
    });
  }

  QueryBuilder<CachedFlashcardDeck, int, QQueryOperations>
      reviewDueCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reviewDueCount');
    });
  }

  QueryBuilder<CachedFlashcardDeck, int, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<CachedFlashcardDeck, int, QQueryOperations> totalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'total');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedFlashcardCollection on Isar {
  IsarCollection<CachedFlashcard> get cachedFlashcards => this.collection();
}

const CachedFlashcardSchema = CollectionSchema(
  name: r'CachedFlashcard',
  id: 7077262175784803362,
  properties: {
    r'back': PropertySchema(
      id: 0,
      name: r'back',
      type: IsarType.string,
    ),
    r'cardType': PropertySchema(
      id: 1,
      name: r'cardType',
      type: IsarType.string,
    ),
    r'clozeIndex': PropertySchema(
      id: 2,
      name: r'clozeIndex',
      type: IsarType.long,
    ),
    r'clozeText': PropertySchema(
      id: 3,
      name: r'clozeText',
      type: IsarType.string,
    ),
    r'deckServerId': PropertySchema(
      id: 4,
      name: r'deckServerId',
      type: IsarType.long,
    ),
    r'dueAt': PropertySchema(
      id: 5,
      name: r'dueAt',
      type: IsarType.dateTime,
    ),
    r'easeFactor': PropertySchema(
      id: 6,
      name: r'easeFactor',
      type: IsarType.double,
    ),
    r'front': PropertySchema(
      id: 7,
      name: r'front',
      type: IsarType.string,
    ),
    r'intervalDays': PropertySchema(
      id: 8,
      name: r'intervalDays',
      type: IsarType.double,
    ),
    r'lapses': PropertySchema(
      id: 9,
      name: r'lapses',
      type: IsarType.long,
    ),
    r'learningStep': PropertySchema(
      id: 10,
      name: r'learningStep',
      type: IsarType.long,
    ),
    r'mediaUrl': PropertySchema(
      id: 11,
      name: r'mediaUrl',
      type: IsarType.string,
    ),
    r'occlusionDataJson': PropertySchema(
      id: 12,
      name: r'occlusionDataJson',
      type: IsarType.string,
    ),
    r'repetitions': PropertySchema(
      id: 13,
      name: r'repetitions',
      type: IsarType.long,
    ),
    r'serverId': PropertySchema(
      id: 14,
      name: r'serverId',
      type: IsarType.long,
    ),
    r'state': PropertySchema(
      id: 15,
      name: r'state',
      type: IsarType.string,
    ),
    r'tagsJson': PropertySchema(
      id: 16,
      name: r'tagsJson',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedFlashcardEstimateSize,
  serialize: _cachedFlashcardSerialize,
  deserialize: _cachedFlashcardDeserialize,
  deserializeProp: _cachedFlashcardDeserializeProp,
  idName: r'id',
  indexes: {
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedFlashcardGetId,
  getLinks: _cachedFlashcardGetLinks,
  attach: _cachedFlashcardAttach,
  version: '3.1.0+1',
);

int _cachedFlashcardEstimateSize(
  CachedFlashcard object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.back.length * 3;
  bytesCount += 3 + object.cardType.length * 3;
  {
    final value = object.clozeText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.front.length * 3;
  {
    final value = object.mediaUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.occlusionDataJson.length * 3;
  bytesCount += 3 + object.state.length * 3;
  bytesCount += 3 + object.tagsJson.length * 3;
  return bytesCount;
}

void _cachedFlashcardSerialize(
  CachedFlashcard object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.back);
  writer.writeString(offsets[1], object.cardType);
  writer.writeLong(offsets[2], object.clozeIndex);
  writer.writeString(offsets[3], object.clozeText);
  writer.writeLong(offsets[4], object.deckServerId);
  writer.writeDateTime(offsets[5], object.dueAt);
  writer.writeDouble(offsets[6], object.easeFactor);
  writer.writeString(offsets[7], object.front);
  writer.writeDouble(offsets[8], object.intervalDays);
  writer.writeLong(offsets[9], object.lapses);
  writer.writeLong(offsets[10], object.learningStep);
  writer.writeString(offsets[11], object.mediaUrl);
  writer.writeString(offsets[12], object.occlusionDataJson);
  writer.writeLong(offsets[13], object.repetitions);
  writer.writeLong(offsets[14], object.serverId);
  writer.writeString(offsets[15], object.state);
  writer.writeString(offsets[16], object.tagsJson);
}

CachedFlashcard _cachedFlashcardDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedFlashcard();
  object.back = reader.readString(offsets[0]);
  object.cardType = reader.readString(offsets[1]);
  object.clozeIndex = reader.readLong(offsets[2]);
  object.clozeText = reader.readStringOrNull(offsets[3]);
  object.deckServerId = reader.readLong(offsets[4]);
  object.dueAt = reader.readDateTimeOrNull(offsets[5]);
  object.easeFactor = reader.readDouble(offsets[6]);
  object.front = reader.readString(offsets[7]);
  object.id = id;
  object.intervalDays = reader.readDouble(offsets[8]);
  object.lapses = reader.readLong(offsets[9]);
  object.learningStep = reader.readLong(offsets[10]);
  object.mediaUrl = reader.readStringOrNull(offsets[11]);
  object.occlusionDataJson = reader.readString(offsets[12]);
  object.repetitions = reader.readLong(offsets[13]);
  object.serverId = reader.readLong(offsets[14]);
  object.state = reader.readString(offsets[15]);
  object.tagsJson = reader.readString(offsets[16]);
  return object;
}

P _cachedFlashcardDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedFlashcardGetId(CachedFlashcard object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedFlashcardGetLinks(CachedFlashcard object) {
  return [];
}

void _cachedFlashcardAttach(
    IsarCollection<dynamic> col, Id id, CachedFlashcard object) {
  object.id = id;
}

extension CachedFlashcardByIndex on IsarCollection<CachedFlashcard> {
  Future<CachedFlashcard?> getByServerId(int serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  CachedFlashcard? getByServerIdSync(int serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(int serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(int serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<CachedFlashcard?>> getAllByServerId(List<int> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<CachedFlashcard?> getAllByServerIdSync(List<int> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'serverId', values);
  }

  Future<int> deleteAllByServerId(List<int> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'serverId', values);
  }

  int deleteAllByServerIdSync(List<int> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'serverId', values);
  }

  Future<Id> putByServerId(CachedFlashcard object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(CachedFlashcard object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<CachedFlashcard> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<CachedFlashcard> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension CachedFlashcardQueryWhereSort
    on QueryBuilder<CachedFlashcard, CachedFlashcard, QWhere> {
  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhere> anyServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'serverId'),
      );
    });
  }
}

extension CachedFlashcardQueryWhere
    on QueryBuilder<CachedFlashcard, CachedFlashcard, QWhereClause> {
  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhereClause>
      serverIdEqualTo(int serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhereClause>
      serverIdNotEqualTo(int serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhereClause>
      serverIdGreaterThan(
    int serverId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'serverId',
        lower: [serverId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhereClause>
      serverIdLessThan(
    int serverId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'serverId',
        lower: [],
        upper: [serverId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterWhereClause>
      serverIdBetween(
    int lowerServerId,
    int upperServerId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'serverId',
        lower: [lowerServerId],
        includeLower: includeLower,
        upper: [upperServerId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedFlashcardQueryFilter
    on QueryBuilder<CachedFlashcard, CachedFlashcard, QFilterCondition> {
  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      backEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      backGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      backLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      backBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'back',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      backStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      backEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      backContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      backMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'back',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      backIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'back',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      backIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'back',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      cardTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      cardTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      cardTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      cardTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cardType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      cardTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      cardTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      cardTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      cardTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cardType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      cardTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cardType',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      cardTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cardType',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clozeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clozeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clozeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clozeIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'clozeText',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'clozeText',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clozeText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clozeText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clozeText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clozeText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clozeText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clozeText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clozeText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clozeText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clozeText',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      clozeTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clozeText',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      deckServerIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deckServerId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      deckServerIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deckServerId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      deckServerIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deckServerId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      deckServerIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deckServerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      dueAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dueAt',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      dueAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dueAt',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      dueAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dueAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      dueAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dueAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      dueAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dueAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      dueAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dueAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      easeFactorEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'easeFactor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      easeFactorGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'easeFactor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      easeFactorLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'easeFactor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      easeFactorBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'easeFactor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      frontEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      frontGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      frontLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      frontBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'front',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      frontStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      frontEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      frontContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      frontMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'front',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      frontIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'front',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      frontIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'front',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      intervalDaysEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intervalDays',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      intervalDaysGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'intervalDays',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      intervalDaysLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'intervalDays',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      intervalDaysBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'intervalDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      lapsesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lapses',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      lapsesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lapses',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      lapsesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lapses',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      lapsesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lapses',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      learningStepEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'learningStep',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      learningStepGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'learningStep',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      learningStepLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'learningStep',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      learningStepBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'learningStep',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mediaUrl',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mediaUrl',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      mediaUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      occlusionDataJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'occlusionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      occlusionDataJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'occlusionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      occlusionDataJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'occlusionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      occlusionDataJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'occlusionDataJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      occlusionDataJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'occlusionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      occlusionDataJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'occlusionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      occlusionDataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'occlusionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      occlusionDataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'occlusionDataJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      occlusionDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'occlusionDataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      occlusionDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'occlusionDataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      repetitionsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repetitions',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      repetitionsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repetitions',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      repetitionsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repetitions',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      repetitionsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repetitions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      serverIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      serverIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      serverIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      serverIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      stateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      stateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      stateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      stateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'state',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      stateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      stateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      stateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      stateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'state',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      stateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      stateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'state',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      tagsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      tagsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tagsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      tagsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tagsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      tagsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tagsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      tagsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tagsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      tagsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tagsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      tagsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tagsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      tagsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tagsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      tagsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterFilterCondition>
      tagsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tagsJson',
        value: '',
      ));
    });
  }
}

extension CachedFlashcardQueryObject
    on QueryBuilder<CachedFlashcard, CachedFlashcard, QFilterCondition> {}

extension CachedFlashcardQueryLinks
    on QueryBuilder<CachedFlashcard, CachedFlashcard, QFilterCondition> {}

extension CachedFlashcardQuerySortBy
    on QueryBuilder<CachedFlashcard, CachedFlashcard, QSortBy> {
  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> sortByBack() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'back', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByBackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'back', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByCardType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardType', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByCardTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardType', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByClozeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clozeIndex', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByClozeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clozeIndex', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByClozeText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clozeText', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByClozeTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clozeText', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByDeckServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckServerId', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByDeckServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckServerId', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> sortByDueAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueAt', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByDueAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueAt', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByEaseFactor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'easeFactor', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByEaseFactorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'easeFactor', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> sortByFront() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'front', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByFrontDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'front', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByIntervalDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalDays', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByIntervalDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalDays', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> sortByLapses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lapses', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByLapsesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lapses', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByLearningStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learningStep', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByLearningStepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learningStep', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByMediaUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByMediaUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaUrl', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByOcclusionDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occlusionDataJson', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByOcclusionDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occlusionDataJson', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByRepetitionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> sortByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByTagsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagsJson', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      sortByTagsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagsJson', Sort.desc);
    });
  }
}

extension CachedFlashcardQuerySortThenBy
    on QueryBuilder<CachedFlashcard, CachedFlashcard, QSortThenBy> {
  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> thenByBack() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'back', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByBackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'back', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByCardType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardType', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByCardTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardType', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByClozeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clozeIndex', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByClozeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clozeIndex', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByClozeText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clozeText', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByClozeTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clozeText', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByDeckServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckServerId', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByDeckServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckServerId', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> thenByDueAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueAt', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByDueAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueAt', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByEaseFactor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'easeFactor', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByEaseFactorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'easeFactor', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> thenByFront() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'front', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByFrontDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'front', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByIntervalDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalDays', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByIntervalDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalDays', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> thenByLapses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lapses', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByLapsesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lapses', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByLearningStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learningStep', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByLearningStepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learningStep', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByMediaUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByMediaUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaUrl', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByOcclusionDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occlusionDataJson', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByOcclusionDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occlusionDataJson', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByRepetitionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy> thenByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByTagsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagsJson', Sort.asc);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QAfterSortBy>
      thenByTagsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagsJson', Sort.desc);
    });
  }
}

extension CachedFlashcardQueryWhereDistinct
    on QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct> {
  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct> distinctByBack(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'back', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct> distinctByCardType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cardType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct>
      distinctByClozeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clozeIndex');
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct> distinctByClozeText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clozeText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct>
      distinctByDeckServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deckServerId');
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct> distinctByDueAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dueAt');
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct>
      distinctByEaseFactor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'easeFactor');
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct> distinctByFront(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'front', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct>
      distinctByIntervalDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intervalDays');
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct> distinctByLapses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lapses');
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct>
      distinctByLearningStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'learningStep');
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct> distinctByMediaUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct>
      distinctByOcclusionDataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'occlusionDataJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct>
      distinctByRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repetitions');
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct>
      distinctByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId');
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct> distinctByState(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'state', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedFlashcard, CachedFlashcard, QDistinct> distinctByTagsJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagsJson', caseSensitive: caseSensitive);
    });
  }
}

extension CachedFlashcardQueryProperty
    on QueryBuilder<CachedFlashcard, CachedFlashcard, QQueryProperty> {
  QueryBuilder<CachedFlashcard, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedFlashcard, String, QQueryOperations> backProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'back');
    });
  }

  QueryBuilder<CachedFlashcard, String, QQueryOperations> cardTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cardType');
    });
  }

  QueryBuilder<CachedFlashcard, int, QQueryOperations> clozeIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clozeIndex');
    });
  }

  QueryBuilder<CachedFlashcard, String?, QQueryOperations> clozeTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clozeText');
    });
  }

  QueryBuilder<CachedFlashcard, int, QQueryOperations> deckServerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deckServerId');
    });
  }

  QueryBuilder<CachedFlashcard, DateTime?, QQueryOperations> dueAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dueAt');
    });
  }

  QueryBuilder<CachedFlashcard, double, QQueryOperations> easeFactorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'easeFactor');
    });
  }

  QueryBuilder<CachedFlashcard, String, QQueryOperations> frontProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'front');
    });
  }

  QueryBuilder<CachedFlashcard, double, QQueryOperations>
      intervalDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intervalDays');
    });
  }

  QueryBuilder<CachedFlashcard, int, QQueryOperations> lapsesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lapses');
    });
  }

  QueryBuilder<CachedFlashcard, int, QQueryOperations> learningStepProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'learningStep');
    });
  }

  QueryBuilder<CachedFlashcard, String?, QQueryOperations> mediaUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaUrl');
    });
  }

  QueryBuilder<CachedFlashcard, String, QQueryOperations>
      occlusionDataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occlusionDataJson');
    });
  }

  QueryBuilder<CachedFlashcard, int, QQueryOperations> repetitionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repetitions');
    });
  }

  QueryBuilder<CachedFlashcard, int, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<CachedFlashcard, String, QQueryOperations> stateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'state');
    });
  }

  QueryBuilder<CachedFlashcard, String, QQueryOperations> tagsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagsJson');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedReviewQueueCollection on Isar {
  IsarCollection<CachedReviewQueue> get cachedReviewQueues => this.collection();
}

const CachedReviewQueueSchema = CollectionSchema(
  name: r'CachedReviewQueue',
  id: -8942208048069144899,
  properties: {
    r'cardsJson': PropertySchema(
      id: 0,
      name: r'cardsJson',
      type: IsarType.string,
    ),
    r'deckKey': PropertySchema(
      id: 1,
      name: r'deckKey',
      type: IsarType.string,
    ),
    r'savedAt': PropertySchema(
      id: 2,
      name: r'savedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _cachedReviewQueueEstimateSize,
  serialize: _cachedReviewQueueSerialize,
  deserialize: _cachedReviewQueueDeserialize,
  deserializeProp: _cachedReviewQueueDeserializeProp,
  idName: r'id',
  indexes: {
    r'deckKey': IndexSchema(
      id: 631740124933031133,
      name: r'deckKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'deckKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedReviewQueueGetId,
  getLinks: _cachedReviewQueueGetLinks,
  attach: _cachedReviewQueueAttach,
  version: '3.1.0+1',
);

int _cachedReviewQueueEstimateSize(
  CachedReviewQueue object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cardsJson.length * 3;
  bytesCount += 3 + object.deckKey.length * 3;
  return bytesCount;
}

void _cachedReviewQueueSerialize(
  CachedReviewQueue object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cardsJson);
  writer.writeString(offsets[1], object.deckKey);
  writer.writeDateTime(offsets[2], object.savedAt);
}

CachedReviewQueue _cachedReviewQueueDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedReviewQueue();
  object.cardsJson = reader.readString(offsets[0]);
  object.deckKey = reader.readString(offsets[1]);
  object.id = id;
  object.savedAt = reader.readDateTime(offsets[2]);
  return object;
}

P _cachedReviewQueueDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedReviewQueueGetId(CachedReviewQueue object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedReviewQueueGetLinks(
    CachedReviewQueue object) {
  return [];
}

void _cachedReviewQueueAttach(
    IsarCollection<dynamic> col, Id id, CachedReviewQueue object) {
  object.id = id;
}

extension CachedReviewQueueByIndex on IsarCollection<CachedReviewQueue> {
  Future<CachedReviewQueue?> getByDeckKey(String deckKey) {
    return getByIndex(r'deckKey', [deckKey]);
  }

  CachedReviewQueue? getByDeckKeySync(String deckKey) {
    return getByIndexSync(r'deckKey', [deckKey]);
  }

  Future<bool> deleteByDeckKey(String deckKey) {
    return deleteByIndex(r'deckKey', [deckKey]);
  }

  bool deleteByDeckKeySync(String deckKey) {
    return deleteByIndexSync(r'deckKey', [deckKey]);
  }

  Future<List<CachedReviewQueue?>> getAllByDeckKey(List<String> deckKeyValues) {
    final values = deckKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'deckKey', values);
  }

  List<CachedReviewQueue?> getAllByDeckKeySync(List<String> deckKeyValues) {
    final values = deckKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'deckKey', values);
  }

  Future<int> deleteAllByDeckKey(List<String> deckKeyValues) {
    final values = deckKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'deckKey', values);
  }

  int deleteAllByDeckKeySync(List<String> deckKeyValues) {
    final values = deckKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'deckKey', values);
  }

  Future<Id> putByDeckKey(CachedReviewQueue object) {
    return putByIndex(r'deckKey', object);
  }

  Id putByDeckKeySync(CachedReviewQueue object, {bool saveLinks = true}) {
    return putByIndexSync(r'deckKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDeckKey(List<CachedReviewQueue> objects) {
    return putAllByIndex(r'deckKey', objects);
  }

  List<Id> putAllByDeckKeySync(List<CachedReviewQueue> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'deckKey', objects, saveLinks: saveLinks);
  }
}

extension CachedReviewQueueQueryWhereSort
    on QueryBuilder<CachedReviewQueue, CachedReviewQueue, QWhere> {
  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedReviewQueueQueryWhere
    on QueryBuilder<CachedReviewQueue, CachedReviewQueue, QWhereClause> {
  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterWhereClause>
      deckKeyEqualTo(String deckKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'deckKey',
        value: [deckKey],
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterWhereClause>
      deckKeyNotEqualTo(String deckKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deckKey',
              lower: [],
              upper: [deckKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deckKey',
              lower: [deckKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deckKey',
              lower: [deckKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deckKey',
              lower: [],
              upper: [deckKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedReviewQueueQueryFilter
    on QueryBuilder<CachedReviewQueue, CachedReviewQueue, QFilterCondition> {
  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      cardsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      cardsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      cardsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      cardsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cardsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      cardsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      cardsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      cardsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      cardsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cardsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      cardsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cardsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      cardsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cardsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      deckKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deckKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      deckKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deckKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      deckKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deckKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      deckKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deckKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      deckKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deckKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      deckKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deckKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      deckKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deckKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      deckKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deckKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      deckKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deckKey',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      deckKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deckKey',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      savedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'savedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      savedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'savedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      savedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'savedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterFilterCondition>
      savedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'savedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedReviewQueueQueryObject
    on QueryBuilder<CachedReviewQueue, CachedReviewQueue, QFilterCondition> {}

extension CachedReviewQueueQueryLinks
    on QueryBuilder<CachedReviewQueue, CachedReviewQueue, QFilterCondition> {}

extension CachedReviewQueueQuerySortBy
    on QueryBuilder<CachedReviewQueue, CachedReviewQueue, QSortBy> {
  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      sortByCardsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardsJson', Sort.asc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      sortByCardsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardsJson', Sort.desc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      sortByDeckKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckKey', Sort.asc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      sortByDeckKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckKey', Sort.desc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      sortBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      sortBySavedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.desc);
    });
  }
}

extension CachedReviewQueueQuerySortThenBy
    on QueryBuilder<CachedReviewQueue, CachedReviewQueue, QSortThenBy> {
  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      thenByCardsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardsJson', Sort.asc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      thenByCardsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardsJson', Sort.desc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      thenByDeckKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckKey', Sort.asc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      thenByDeckKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckKey', Sort.desc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      thenBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QAfterSortBy>
      thenBySavedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.desc);
    });
  }
}

extension CachedReviewQueueQueryWhereDistinct
    on QueryBuilder<CachedReviewQueue, CachedReviewQueue, QDistinct> {
  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QDistinct>
      distinctByCardsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cardsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QDistinct>
      distinctByDeckKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deckKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedReviewQueue, CachedReviewQueue, QDistinct>
      distinctBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savedAt');
    });
  }
}

extension CachedReviewQueueQueryProperty
    on QueryBuilder<CachedReviewQueue, CachedReviewQueue, QQueryProperty> {
  QueryBuilder<CachedReviewQueue, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedReviewQueue, String, QQueryOperations>
      cardsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cardsJson');
    });
  }

  QueryBuilder<CachedReviewQueue, String, QQueryOperations> deckKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deckKey');
    });
  }

  QueryBuilder<CachedReviewQueue, DateTime, QQueryOperations>
      savedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPendingFlashcardReviewCollection on Isar {
  IsarCollection<PendingFlashcardReview> get pendingFlashcardReviews =>
      this.collection();
}

const PendingFlashcardReviewSchema = CollectionSchema(
  name: r'PendingFlashcardReview',
  id: -2089606605154067213,
  properties: {
    r'flashcardServerId': PropertySchema(
      id: 0,
      name: r'flashcardServerId',
      type: IsarType.long,
    ),
    r'rating': PropertySchema(
      id: 1,
      name: r'rating',
      type: IsarType.string,
    ),
    r'reviewedAt': PropertySchema(
      id: 2,
      name: r'reviewedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _pendingFlashcardReviewEstimateSize,
  serialize: _pendingFlashcardReviewSerialize,
  deserialize: _pendingFlashcardReviewDeserialize,
  deserializeProp: _pendingFlashcardReviewDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _pendingFlashcardReviewGetId,
  getLinks: _pendingFlashcardReviewGetLinks,
  attach: _pendingFlashcardReviewAttach,
  version: '3.1.0+1',
);

int _pendingFlashcardReviewEstimateSize(
  PendingFlashcardReview object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.rating.length * 3;
  return bytesCount;
}

void _pendingFlashcardReviewSerialize(
  PendingFlashcardReview object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.flashcardServerId);
  writer.writeString(offsets[1], object.rating);
  writer.writeDateTime(offsets[2], object.reviewedAt);
}

PendingFlashcardReview _pendingFlashcardReviewDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PendingFlashcardReview();
  object.flashcardServerId = reader.readLong(offsets[0]);
  object.id = id;
  object.rating = reader.readString(offsets[1]);
  object.reviewedAt = reader.readDateTime(offsets[2]);
  return object;
}

P _pendingFlashcardReviewDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pendingFlashcardReviewGetId(PendingFlashcardReview object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pendingFlashcardReviewGetLinks(
    PendingFlashcardReview object) {
  return [];
}

void _pendingFlashcardReviewAttach(
    IsarCollection<dynamic> col, Id id, PendingFlashcardReview object) {
  object.id = id;
}

extension PendingFlashcardReviewQueryWhereSort
    on QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QWhere> {
  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PendingFlashcardReviewQueryWhere on QueryBuilder<
    PendingFlashcardReview, PendingFlashcardReview, QWhereClause> {
  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PendingFlashcardReviewQueryFilter on QueryBuilder<
    PendingFlashcardReview, PendingFlashcardReview, QFilterCondition> {
  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> flashcardServerIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flashcardServerId',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> flashcardServerIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flashcardServerId',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> flashcardServerIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flashcardServerId',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> flashcardServerIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flashcardServerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> ratingEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> ratingGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> ratingLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> ratingBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rating',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> ratingStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> ratingEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
          QAfterFilterCondition>
      ratingContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
          QAfterFilterCondition>
      ratingMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rating',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> ratingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rating',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> ratingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rating',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> reviewedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reviewedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> reviewedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reviewedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> reviewedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reviewedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview,
      QAfterFilterCondition> reviewedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reviewedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PendingFlashcardReviewQueryObject on QueryBuilder<
    PendingFlashcardReview, PendingFlashcardReview, QFilterCondition> {}

extension PendingFlashcardReviewQueryLinks on QueryBuilder<
    PendingFlashcardReview, PendingFlashcardReview, QFilterCondition> {}

extension PendingFlashcardReviewQuerySortBy
    on QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QSortBy> {
  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      sortByFlashcardServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flashcardServerId', Sort.asc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      sortByFlashcardServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flashcardServerId', Sort.desc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      sortByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      sortByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      sortByReviewedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewedAt', Sort.asc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      sortByReviewedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewedAt', Sort.desc);
    });
  }
}

extension PendingFlashcardReviewQuerySortThenBy on QueryBuilder<
    PendingFlashcardReview, PendingFlashcardReview, QSortThenBy> {
  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      thenByFlashcardServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flashcardServerId', Sort.asc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      thenByFlashcardServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flashcardServerId', Sort.desc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      thenByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      thenByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      thenByReviewedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewedAt', Sort.asc);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QAfterSortBy>
      thenByReviewedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewedAt', Sort.desc);
    });
  }
}

extension PendingFlashcardReviewQueryWhereDistinct
    on QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QDistinct> {
  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QDistinct>
      distinctByFlashcardServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flashcardServerId');
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QDistinct>
      distinctByRating({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rating', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingFlashcardReview, PendingFlashcardReview, QDistinct>
      distinctByReviewedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reviewedAt');
    });
  }
}

extension PendingFlashcardReviewQueryProperty on QueryBuilder<
    PendingFlashcardReview, PendingFlashcardReview, QQueryProperty> {
  QueryBuilder<PendingFlashcardReview, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PendingFlashcardReview, int, QQueryOperations>
      flashcardServerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flashcardServerId');
    });
  }

  QueryBuilder<PendingFlashcardReview, String, QQueryOperations>
      ratingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rating');
    });
  }

  QueryBuilder<PendingFlashcardReview, DateTime, QQueryOperations>
      reviewedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reviewedAt');
    });
  }
}
