import 'dart:async';

import 'package:anx_reader/service/ai/tools/input/bookshelf_lookup_input.dart';
import 'package:anx_reader/service/ai/tools/repository/books_repository.dart';

import 'base_tool.dart';

class BookshelfLookupTool
    extends RepositoryTool<BookshelfLookupInput, Map<String, dynamic>> {
  BookshelfLookupTool(this._repository)
      : super(
          name: 'bookshelf_lookup',
          description:
              'Search books on the local shelf by title or author. Optional filters: group_id, include_deleted, limit. Returns a list of matching books, and the meta information(title, author, progress, last reading time) of each book.',
          inputJsonSchema: const {
            'type': 'object',
            'properties': {
              'query': {
                'type': 'string',
                'description': 'Keyword for title or author search. Optional when filtering by group only.',
              },
              'group_id': {
                'type': 'integer',
                'description': 'Optional group identifier to filter books.',
              },
              'include_deleted': {
                'type': 'boolean',
                'description': 'Whether to include deleted books (default false).',
              },
              'limit': {
                'type': 'integer',
                'description': 'Maximum number of results (1-50).',
              },
            },
          },
          timeout: const Duration(seconds: 3),
        );

  final BooksRepository _repository;

  @override
  BookshelfLookupInput parseInput(Map<String, dynamic> json) {
    return BookshelfLookupInput.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> run(BookshelfLookupInput input) async {
    final results = await _repository.searchBooks(
      keyword: input.query,
      groupId: input.groupId,
      includeDeleted: input.includeDeleted,
      limit: input.resolvedLimit(),
    );

    return {
      'query': input.query,
      'groupId': input.groupId,
      'includeDeleted': input.includeDeleted,
      'results': results.map((entry) => entry.toMap()).toList(),
    };
  }

  @override
  bool shouldLogError(Object error) {
    return error is! TimeoutException;
  }
}
