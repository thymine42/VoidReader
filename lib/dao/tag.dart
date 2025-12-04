import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/tag.dart';

const _stylesTable = 'tb_styles';
const _tagSentinel = 1.0;
const _relationSentinel = 2.0;

class TagDao extends BaseDao {
  Future<List<Tag>> fetchAllTags() {
    return queryList(
      _stylesTable,
      mapper: Tag.fromDb,
      where: 'ABS(font_size - ?) < 0.0001',
      whereArgs: [_tagSentinel],
      orderBy: 'LOWER(font_family) ASC',
    );
  }

  Future<Tag?> getTagById(int id) {
    return querySingle(
      _stylesTable,
      mapper: Tag.fromDb,
      where: 'id = ? AND ABS(font_size - ?) < 0.0001',
      whereArgs: [id, _tagSentinel],
    );
  }

  Future<Tag?> getTagByName(String name) {
    return rawQuerySingle(
      '''
      SELECT * FROM $_stylesTable 
      WHERE ABS(font_size - ?) < 0.0001 AND LOWER(font_family) = LOWER(?) 
      LIMIT 1
      ''',
      arguments: [_tagSentinel, name],
      mapper: Tag.fromDb,
    );
  }

  Future<int> insertTag(String name) async {
    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.rawQuery(
        '''
        SELECT id FROM $_stylesTable 
        WHERE ABS(font_size - ?) < 0.0001 AND LOWER(font_family) = LOWER(?) 
        LIMIT 1
        ''',
        [_tagSentinel, name],
      );
      if (existing.isNotEmpty) {
        return existing.first['id'] as int;
      }
      return txn.insert(_stylesTable, {
        'font_size': _tagSentinel,
        'font_family': name,
      });
    });
  }

  Future<void> renameTag(int id, String newName) async {
    await update(
      _stylesTable,
      {
        'font_family': newName,
      },
      where: 'id = ? AND ABS(font_size - ?) < 0.0001',
      whereArgs: [id, _tagSentinel],
    );
  }

  Future<void> deleteTag(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        _stylesTable,
        where: 'id = ? AND ABS(font_size - ?) < 0.0001',
        whereArgs: [id, _tagSentinel],
      );
      await txn.delete(
        _stylesTable,
        where:
            'ABS(font_size - ?) < 0.0001 AND CAST(letter_spacing AS INTEGER) = ?',
        whereArgs: [_relationSentinel, id],
      );
    });
  }
}

class BookTagDao extends BaseDao {
  Future<List<BookTag>> fetchRelationsForBook(int bookId) {
    return queryList(
      _stylesTable,
      mapper: BookTag.fromDb,
      where: 'ABS(font_size - ?) < 0.0001 AND CAST(line_height AS INTEGER) = ?',
      whereArgs: [_relationSentinel, bookId],
    );
  }

  Future<List<int>> fetchTagIdsForBook(int bookId) async {
    final relations = await fetchRelationsForBook(bookId);
    return relations.map((r) => r.tagId).toList(growable: false);
  }

  Future<List<Tag>> fetchTagsForBook(int bookId) async {
    final tagIds = await fetchTagIdsForBook(bookId);
    if (tagIds.isEmpty) return const [];
    final placeholders = List.filled(tagIds.length, '?').join(',');
    return rawQueryList(
      '''
      SELECT * FROM $_stylesTable 
      WHERE ABS(font_size - ?) < 0.0001 AND id IN ($placeholders)
      ''',
      arguments: [_tagSentinel, ...tagIds],
      mapper: Tag.fromDb,
    );
  }

  Future<void> addRelation({required int bookId, required int tagId}) async {
    final db = await database;
    await db.transaction((txn) async {
      final exists = await txn.rawQuery(
        '''
        SELECT id FROM $_stylesTable 
        WHERE ABS(font_size - ?) < 0.0001 
          AND CAST(line_height AS INTEGER) = ? 
          AND CAST(letter_spacing AS INTEGER) = ? 
        LIMIT 1
        ''',
        [_relationSentinel, bookId, tagId],
      );
      if (exists.isNotEmpty) return;
      await txn.insert(_stylesTable, {
        'font_size': _relationSentinel,
        'line_height': bookId.toDouble(),
        'letter_spacing': tagId.toDouble(),
      });
    });
  }

  Future<void> removeRelation({required int bookId, required int tagId}) async {
    await delete(
      _stylesTable,
      where:
          'ABS(font_size - ?) < 0.0001 AND CAST(line_height AS INTEGER) = ? AND CAST(letter_spacing AS INTEGER) = ?',
      whereArgs: [_relationSentinel, bookId, tagId],
    );
  }

  Future<Map<int, List<int>>> bookIdToTagIds({List<int>? bookIds}) async {
    final buffer = StringBuffer(
        'SELECT id, line_height, letter_spacing FROM $_stylesTable WHERE ABS(font_size - ?) < 0.0001');
    final args = <Object?>[_relationSentinel];
    if (bookIds != null && bookIds.isNotEmpty) {
      final placeholders = List.filled(bookIds.length, '?').join(',');
      buffer.write(' AND CAST(line_height AS INTEGER) IN ($placeholders)');
      args.addAll(bookIds);
    }
    final rows = await rawQueryList(
      buffer.toString(),
      arguments: args,
      mapper: BookTag.fromDb,
    );
    final map = <int, List<int>>{};
    for (final rel in rows) {
      map.putIfAbsent(rel.bookId, () => []).add(rel.tagId);
    }
    return map;
  }
}

final tagDao = TagDao();
final bookTagDao = BookTagDao();
