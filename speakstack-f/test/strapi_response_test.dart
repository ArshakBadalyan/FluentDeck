import 'package:flutter_test/flutter_test.dart';
import 'package:speakstack/utils/strapi_response.dart';

void main() {
  test('list parses v4 collection', () {
    final rows = StrapiResponse.list({
      'data': [
        {'id': 1, 'attributes': {'title': 'A'}},
        {'id': 2, 'attributes': {'title': 'B'}},
      ],
    });
    expect(rows.length, 2);
    expect(rows[0]['title'], 'A');
    expect(rows[0]['id'], 1);
  });

  test('list parses v5 flattened collection', () {
    final rows = StrapiResponse.list({
      'data': [
        {'id': 1, 'title': 'A', 'documentId': 'abc'},
      ],
    });
    expect(rows.single['title'], 'A');
    expect(rows.single['documentId'], 'abc');
  });

  test('list parses custom route bare list', () {
    expect(
      StrapiResponse.list([
        {'id': 1, 'name': 'deck'},
      ]).single['name'],
      'deck',
    );
  });

  test('row parses v4 and v5 single entity', () {
    expect(
      StrapiResponse.row({
        'data': {'id': 3, 'attributes': {'username': 'u'}},
      })?['username'],
      'u',
    );
    expect(
      StrapiResponse.row({'id': 4, 'username': 'flat'})?['username'],
      'flat',
    );
  });

  test('field reads attributes or top-level', () {
    expect(
      StrapiResponse.field<bool>({'attributes': {'read': false}}, 'read'),
      false,
    );
    expect(StrapiResponse.field<bool>({'read': true}, 'read'), true);
  });
}
