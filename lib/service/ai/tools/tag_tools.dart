import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/tag.dart';
import 'package:anx_reader/models/tag.dart';
import 'package:anx_reader/service/ai/tools/base_tool.dart';
import 'package:anx_reader/service/ai/tools/input/apply_book_tags_input.dart';
import 'package:anx_reader/service/ai/tools/repository/books_repository.dart';
import 'package:anx_reader/service/ai/tools/repository/tag_repository.dart';
import 'package:anx_reader/service/ai/tools/ai_tool_registry.dart';
import 'package:anx_reader/utils/color/hash_color.dart';
import 'package:anx_reader/utils/color/rgb.dart';
import 'package:flutter/material.dart';

const _tagsListToolId = 'tags_list';
const _booksTagsListToolId = 'books_tags_list';
const _applyBookTagsToolId = 'apply_book_tags';

final tagsListToolDefinition = AiToolDefinition(
  id: _tagsListToolId,
  displayNameBuilder: (_) => 'List Tags',
  descriptionBuilder: (_) => 'Returns all tags with id, name, and RGB color.',
  build: (context) => TagsListTool(context.tagRepository).tool,
);

final booksTagsListToolDefinition = AiToolDefinition(
  id: _booksTagsListToolId,
  displayNameBuilder: (_) => 'List Book Tags',
  descriptionBuilder: (_) =>
      'Returns tags for books (id, title, tags with id/name/rgb). Accepts optional bookIds array.',
  build: (context) => BooksTagsListTool(context.tagRepository).tool,
);

final applyBookTagsToolDefinition = AiToolDefinition(
  id: _applyBookTagsToolId,
  displayNameBuilder: (_) => 'Apply Book Tags',
  descriptionBuilder: (_) =>
      'Creates/updates tags and syncs book-tag links. Input supports books, createTags, updateTags.',
  build: (context) =>
      ApplyBookTagsTool(context.tagRepository, context.booksRepository).tool,
);

class TagsListTool
    extends RepositoryTool<Map<String, dynamic>, List<Map<String, dynamic>>> {
  TagsListTool(this._tagRepository)
      : super(
          name: _tagsListToolId,
          description: 'List all tags with id, name, rgb.',
          inputJsonSchema: const {
            'type': 'object',
          },
          timeout: const Duration(seconds: 5),
        );

  final TagRepository _tagRepository;

  @override
  Map<String, dynamic> parseInput(Map<String, dynamic> json) => json;

  @override
  Future<List<Map<String, dynamic>>> run(Map<String, dynamic> input) async {
    final tags = await _tagRepository.fetchAllTags();
    return tags
        .map((t) => {
              'id': t.id,
              'name': t.name,
              'rgb': _rgbString(t.color ?? hashColor(t.name)),
            })
        .toList();
  }
}

class BooksTagsListTool
    extends RepositoryTool<Map<String, dynamic>, List<Map<String, dynamic>>> {
  BooksTagsListTool(this._tagRepository)
      : super(
          name: _booksTagsListToolId,
          description:
              'List books with their tags. Optional bookIds array filters the result.',
          inputJsonSchema: const {
            'type': 'object',
            'properties': {
              'bookIds': {
                'type': 'array',
                'items': {'type': 'integer'},
                'description': 'Optional list of book IDs to filter.',
              }
            }
          },
          timeout: const Duration(seconds: 8),
        );

  final TagRepository _tagRepository;

  @override
  Map<String, dynamic> parseInput(Map<String, dynamic> json) => json;

  @override
  Future<List<Map<String, dynamic>>> run(Map<String, dynamic> input) async {
    final ids = (input['bookIds'] as List?)
            ?.map((e) => (e as num?)?.toInt() ?? 0)
            .where((e) => e > 0)
            .toList() ??
        const [];
    final tagMap = await _tagRepository.fetchTagsForBooks(ids);
    final books = ids.isEmpty
        ? await bookDao.selectNotDeleteBooks()
        : await bookDao.selectBooksByIds(ids);
    final byId = {for (final b in books) b.id: b};
    return tagMap.entries
        .map((entry) {
          final book = byId[entry.key];
          if (book == null) return null;
          return {
            'bookId': book.id,
            'bookTitle': book.title,
            'tags': entry.value
                .map((t) => {
                      'id': t.id,
                      'name': t.name,
                      'rgb': _rgbString(
                        t.color ?? hashColor(t.name),
                      ),
                    })
                .toList(),
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}

class ApplyBookTagsTool
    extends RepositoryTool<ApplyBookTagsInput, Map<String, dynamic>> {
  ApplyBookTagsTool(this._tagRepository, this._booksRepository)
      : super(
          name: _applyBookTagsToolId,
          description:
              'Plan tag changes (create/update) and book-tag links. Returns a plan requiring user confirmation.',
          inputJsonSchema: const {
            'type': 'object',
            'properties': {
              'books': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'required': ['bookId', 'bookTitle'],
                  'properties': {
                    'bookId': {'type': 'integer'},
                    'bookTitle': {'type': 'string'},
                    'tags': {
                      'type': 'array',
                      'items': {'type': 'string'},
                      'description':
                          'Final tag names that should be attached to this book.'
                    }
                  }
                }
              },
              'createTags': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'required': ['name'],
                  'properties': {
                    'name': {'type': 'string'},
                    'rgb': {
                      'type': 'string',
                      'description': 'RGB hex string, e.g. 0x33aa77',
                    }
                  }
                }
              },
              'updateTags': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'required': ['id'],
                  'properties': {
                    'id': {'type': 'integer'},
                    'name': {'type': 'string'},
                    'rgb': {
                      'type': 'string',
                      'description': 'RGB hex string, e.g. 0x33aa77',
                    }
                  }
                }
              }
            }
          },
          timeout: const Duration(seconds: 12),
        );

  final TagRepository _tagRepository;
  final BooksRepository _booksRepository;

  @override
  ApplyBookTagsInput parseInput(Map<String, dynamic> json) =>
      ApplyBookTagsInput.fromJson(json);

  @override
  Future<Map<String, dynamic>> run(ApplyBookTagsInput input) async {
    final conflicts = <Map<String, dynamic>>[];
    final createPlans = <String, Map<String, dynamic>>{};
    final updatePlans = <Map<String, dynamic>>[];
    final mergePlans = <Map<String, dynamic>>[];
    final booksOutput = <Map<String, dynamic>>[];
    final bookChanges = <Map<String, dynamic>>[];

    final existingTags = await _tagRepository.fetchAllTags();
    final tagByName = {
      for (final t in existingTags) t.name.toLowerCase(): t,
    };

    // Plan updates with merge
    for (final update in input.updateTags.where((u) => u.isValid)) {
      final existing = await _tagRepository.fetchTagById(update.id);
      if (existing == null) {
        conflicts.add({
          'type': 'missing_tag',
          'id': update.id,
          'message': 'Tag id ${update.id} not found'
        });
        continue;
      }
      Tag target = existing;
      if (update.name != null) {
        final collision = await _tagRepository.fetchTagByName(update.name!);
        if (collision != null && collision.id != existing.id) {
          mergePlans.add({'sourceId': existing.id, 'targetId': collision.id});
          target = collision;
        }
      }
      updatePlans.add({
        'id': target.id,
        if (update.name != null) 'name': update.name,
        if (update.rgb != null)
          'rgb': _rgbString(_parseRgb(update.rgb) ?? sanitizeRgb(0)),
      });
    }

    // Plan createTags
    for (final create in input.createTags.where((c) => c.isValid)) {
      createPlans[create.name.toLowerCase()] = {
        'name': create.name,
        'rgb': _rgbString(
          _parseRgb(create.rgb) ?? hashColor(create.name),
        ),
      };
    }

    for (final bookReq in input.books.where((b) => b.isValid)) {
      final book = await _booksRepository.fetchByIds([bookReq.bookId]);
      final found = book[bookReq.bookId];
      if (found == null || found.isDeleted) {
        conflicts.add({
          'type': 'missing_book',
          'bookId': bookReq.bookId,
          'bookTitle': bookReq.bookTitle,
          'message': 'Book not found or deleted'
        });
        continue;
      }

      final desiredNames = bookReq.tags
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      final currentTags = await bookTagDao.fetchTagsForBook(found.id);
      final currentNameSet =
          currentTags.map((t) => t.name.toLowerCase()).toSet();

      // ensure planned create for missing tags
      for (final name in desiredNames) {
        final key = name.toLowerCase();
        if (!tagByName.containsKey(key)) {
          createPlans[key] = {
            'name': name,
            'rgb': _rgbString(hashColor(name)),
          };
        }
      }

      final addNames = desiredNames
          .where((n) => !currentNameSet.contains(n.toLowerCase()))
          .toList();
      final removeNames = currentTags
          .where((t) => !desiredNames
              .map((n) => n.toLowerCase())
              .contains(t.name.toLowerCase()))
          .map((t) => t.name)
          .toList();

      booksOutput.add({
        'bookId': found.id,
        'bookTitle': found.title,
        'finalTags': desiredNames
            .map(
              (n) => {
                'name': n,
                'rgb': _rgbString(
                    tagByName[n.toLowerCase()]?.color ?? hashColor(n)),
              },
            )
            .toList(),
      });

      bookChanges.add({
        'bookId': found.id,
        'add': addNames,
        'remove': removeNames,
      });
    }

    return {
      'requiresConfirmation': true,
      'plan': {
        'books': booksOutput,
        'createTags': createPlans.values.toList(),
        'updateTags': updatePlans,
        'mergeTags': mergePlans,
        'bookChanges': bookChanges,
      },
      'conflicts': conflicts,
    };
  }
}

int? _parseRgb(dynamic value) {
  if (value == null) return null;
  if (value is Color) return rgbFromColor(value);
  if (value is num) {
    return sanitizeRgb(value.toInt());
  }
  if (value is String) {
    var v = value.trim();
    if (v.startsWith('0x')) {
      v = v.substring(2);
    } else if (v.startsWith('#')) {
      v = v.substring(1);
    }
    try {
      return sanitizeRgb(int.parse(v, radix: 16));
    } catch (_) {
      return null;
    }
  }
  return null;
}

String _rgbString(dynamic value) {
  final rgb = _parseRgb(value) ?? 0;
  return '0x${rgb.toRadixString(16).padLeft(6, '0')}';
}
