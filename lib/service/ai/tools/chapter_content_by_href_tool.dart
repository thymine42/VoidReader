import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/tools.dart';

import 'base_tool.dart';
import 'input/chapter_content_by_href_input.dart';
import 'repository/chapter_content_repository.dart';

class ChapterContentByHrefTool
    extends RepositoryTool<ChapterContentByHrefInput, Map<String, dynamic>> {
  ChapterContentByHrefTool(
    this._ref,
    this._repository,
  ) : super(
          name: 'chapter_content_by_href',
          description:
              'Fetch text content for a specific chapter identified by its href. Optionally limit the number of characters returned with maxCharacters.',
          inputJsonSchema: const {
            'type': 'object',
            'properties': {
              'href': {
                'type': 'string',
                'description':
                    'Chapter href identifier from the table of contents.',
              },
              'maxCharacters': {
                'type': 'integer',
                'description':
                    'Optional limit for the number of characters returned (500-12000).',
              },
            },
            'required': ['href'],
          },
          timeout: const Duration(seconds: 6),
        );

  final WidgetRef _ref;
  final ChapterContentRepository _repository;

  @override
  ChapterContentByHrefInput parseInput(Map<String, dynamic> json) {
    return ChapterContentByHrefInput.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> run(ChapterContentByHrefInput input) async {
    final content = await _repository.fetchByHref(
      _ref,
      href: input.href,
      maxCharacters: input.maxCharacters,
    );
    return {
      'content': content,
    };
  }
}

Tool chapterContentByHrefTool(WidgetRef ref) {
  return ChapterContentByHrefTool(
    ref,
    const ChapterContentRepository(),
  ).tool;
}
