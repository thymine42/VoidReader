import 'package:anx_reader/dao/tag.dart';
import 'package:anx_reader/models/tag.dart';
import 'package:anx_reader/utils/color/hash_color.dart';
import 'package:anx_reader/utils/color/rgb.dart';

class TagRepository {
  const TagRepository();

  Future<List<Tag>> fetchAllTags() => tagDao.fetchAllTags();

  Future<Tag?> fetchTagById(int id) => tagDao.getTagById(id);

  Future<Tag?> fetchTagByName(String name) => tagDao.getTagByName(name);

  Future<Tag> ensureTag(String name, {int? color}) async {
    final existing = await fetchTagByName(name);
    if (existing != null) {
      if (color != null && existing.color != color) {
        await tagDao.updateTag(existing.id, color: sanitizeRgb(color));
      }
      return (await fetchTagById(existing.id)) ?? existing;
    }
    final rgb = sanitizeRgb(color ?? hashColor(name).toARGB32());
    final id = await tagDao.insertTag(name, color: rgb);
    return (await fetchTagById(id)) ?? Tag(id: id, name: name, color: rgb);
  }

  Future<Tag> updateTag({
    required int id,
    String? newName,
    int? color,
  }) async {
    await tagDao.updateTag(
      id,
      newName: newName,
      color: color == null ? null : sanitizeRgb(color),
    );
    final updated = await fetchTagById(id);
    if (updated == null) {
      throw StateError('Tag $id vanished after update');
    }
    return updated;
  }

  Future<void> mergeTags({
    required Tag source,
    required Tag target,
  }) async {
    final bookIds = await bookTagDao.fetchBookIdsForTag(source.id);
    for (final bookId in bookIds) {
      await bookTagDao.addRelation(bookId: bookId, tagId: target.id);
    }
    await tagDao.deleteTag(source.id);
  }

  Future<Map<int, List<Tag>>> fetchTagsForBooks(Iterable<int> bookIds) async {
    final tagMap = <int, List<Tag>>{};
    if (bookIds.isEmpty) return tagMap;
    final idList = bookIds.toSet().toList();
    final relations = await bookTagDao.bookIdToTagIds(bookIds: idList);
    final tagIds = relations.values.expand((e) => e).toSet().toList();
    if (tagIds.isEmpty) {
      for (final id in idList) {
        tagMap[id] = const [];
      }
      return tagMap;
    }
    final tags = await tagDao.fetchAllTags();
    final byId = {for (final t in tags) t.id: t};
    for (final entry in relations.entries) {
      tagMap[entry.key] =
          entry.value.map((id) => byId[id]).whereType<Tag>().toList();
    }
    for (final id in idList) {
      tagMap.putIfAbsent(id, () => const []);
    }
    return tagMap;
  }
}
